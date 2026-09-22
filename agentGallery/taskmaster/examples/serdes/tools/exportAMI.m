function [observation, workspace] = exportAMI(workspace, nvp)
%exportAMI Configure and compile AMI deliverables (.ami/.ibs/.dll/.so).
%   [OBSERVATION, WORKSPACE] = exportAMI(WORKSPACE, ...) creates a
%   serdes.AMIExport object for the exported Simulink model, configures
%   export settings, and generates compiled AMI files.

    arguments (Input)
        workspace struct
        nvp.Dir (1,1) string = ""                         % Output directory path for AMI files
        nvp.ModelsToExport (1,1) string = "Both Tx and Rx" % Which models: "Tx", "Rx", or "Both" (accepts "Tx only"/"Rx only"/"Both Tx and Rx")
        nvp.ModelTypeTx (1,1) string = ""                 % Tx model type: "GetWave", "Init only", or "Dual model"
        nvp.ModelTypeRx (1,1) string = ""                 % Rx model type: "GetWave", "Init only", or "Dual model"
        nvp.DLLFiles (1,1) logical = false                % Compile the binary (.dll/.so). Omit for fast .ami/.ibs-only export; set true only if the prompt asks for a compiled/DLL model
        nvp.CrossCompile (1,1) logical = false            % Also cross-compile a Linux .so: true or false
        nvp.Obfuscate (1,1) logical = false               % Obfuscate generated code: true or false
        nvp.ModelConfiguration (1,1) string = "TxAndRx"   % Configuration: "TxAndRx", "TxOnly", or "RxOnly"
    end

    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    assert(isfield(workspace, 'exportedModel'), 'exportAMI:noModel', ...
        'No Simulink model. Call exportToSimulink first.');

    modelName = workspace.exportedModel;

    % Output directory
    targetDir = char(nvp.Dir);
    if targetDir == ""
        targetDir = fullfile(tempdir, 'si_bench_ami_export');
    end
    if ~isfolder(targetDir)
        mkdir(targetDir);
    end

    % cd to target dir — AMIExport checks pwd writability
    prevDir = cd(targetDir);
    cleanupObj = onCleanup(@() cd(prevDir));

    % Infer model types from block Mode values if not explicit
    modelTypeTx = nvp.ModelTypeTx;
    if modelTypeTx == "" && isfield(workspace, 'txBlocks')
        modelTypeTx = inferModelType(workspace.txBlocks);
    end
    if modelTypeTx == ""
        modelTypeTx = "Init only";
    end

    modelTypeRx = nvp.ModelTypeRx;
    if modelTypeRx == "" && isfield(workspace, 'rxBlocks')
        modelTypeRx = inferModelType(workspace.rxBlocks);
    end
    if modelTypeRx == ""
        modelTypeRx = "Dual model";
    end

    % Normalize ModelsToExport — models pass "Tx"/"Rx"/"Both"; API demands
    % "Tx only"/"Rx only"/"Both Tx and Rx". Match intent, not exact code.
    modelsToExport = normalizeModelsToExport(nvp.ModelsToExport);

    % Create AMIExport object (R2026a+)
    AMIExport = serdes.AMIExport(modelName);
    AMIExport.ModelsToExport = modelsToExport;
    AMIExport.ModelTypeTx = modelTypeTx;
    AMIExport.ModelTypeRx = modelTypeRx;
    AMIExport.DLLFiles = nvp.DLLFiles;
    AMIExport.AMIFiles = true;
    AMIExport.IBISFile = true;
    AMIExport.TargetDir = targetDir;

    % LinuxCrossCompile defaults to true in the API — set it explicitly so a
    % Linux .so build never runs unless the caller asks for it.
    AMIExport.LinuxCrossCompile = nvp.CrossCompile;

    % Export
    export(AMIExport);

    % Verify generated files. The compiled binary is platform-dependent:
    % Windows -> .dll, Linux -> .so (Linux cannot produce .dll). Check either.
    binExists = ~isempty(dir(fullfile(targetDir, '**', '*.dll'))) || ...
                ~isempty(dir(fullfile(targetDir, '**', '*.so')));
    amiExists = ~isempty(dir(fullfile(targetDir, '**', '*.ami')));
    ibsExists = ~isempty(dir(fullfile(targetDir, '**', '*.ibs')));

    workspace.amiExport = struct( ...
        'targetDir', string(targetDir), ...
        'modelsToExport', modelsToExport, ...
        'modelTypeTx', modelTypeTx, ...
        'modelTypeRx', modelTypeRx, ...
        'dllFiles', nvp.DLLFiles, ...
        'crossCompile', nvp.CrossCompile, ...
        'binExists', binExists, ...
        'dllExists', binExists, ...   % kept for back-compat with existing checks
        'amiExists', amiExists, ...
        'ibsExists', ibsExists);

    if nvp.DLLFiles
        binNote = sprintf('Binary=%s', string(binExists));
    else
        binNote = 'Binary=not compiled (set DLLFiles=true to compile a .dll/.so)';
    end

    observation = sprintf( ...
        ['AMI export complete: Models="%s", TxModel="%s", RxModel="%s". Files: AMI=%s, IBS=%s, %s. ' ...
        'Output dir: %s. Ready for validateAMI.'], ...
        modelsToExport, modelTypeTx, modelTypeRx, ...
        string(amiExists), string(ibsExists), binNote, targetDir);
end

function normalized = normalizeModelsToExport(raw)
    % Map natural-language variants to the AMIExport enum.
    s = lower(strtrim(raw));
    hasTx = contains(s, "tx");
    hasRx = contains(s, "rx");
    if contains(s, "both") || (hasTx && hasRx)
        normalized = "Both Tx and Rx";
    elseif hasRx
        normalized = "Rx only";
    elseif hasTx
        normalized = "Tx only";
    else
        normalized = "Both Tx and Rx";   % safe default
    end
end

function modelType = inferModelType(blocks)
    maxMode = 0;
    for k = 1:numel(blocks)
        if isprop(blocks{k}, 'Mode')
            maxMode = max(maxMode, blocks{k}.Mode);
        end
    end
    if maxMode >= 2
        modelType = "Dual model";
    else
        modelType = "Init only";
    end
end
