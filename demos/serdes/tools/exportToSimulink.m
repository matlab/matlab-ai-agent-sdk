function [observation, workspace] = exportToSimulink(workspace, nvp)
%exportToSimulink Export the current SerDes system to a Simulink model.
%   [OBSERVATION, WORKSPACE] = exportToSimulink(WORKSPACE, ...) calls
%   exportToSimulink on the analyzed SerdesSystem to create a Simulink model
%   for time-domain simulation or AMI export.

    arguments (Input)
        workspace struct
        nvp.ModelName (1,1) string = "untitled"   % Simulink model name without extension (e.g., "mySerdes")
    end

    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    assert(isfield(workspace, 'sys'), 'exportToSimulink:noSystem', ...
        'No analyzed system. Call runAnalysis first.');

    % cd to temp dir — OneDrive paths break Simulink export
    exportDir = fullfile(tempdir, 'si_bench_work');
    if ~isfolder(exportDir), mkdir(exportDir); end
    prevDir = cd(exportDir);
    cleanupObj = onCleanup(@() cd(prevDir));

    % Export
    before = find_system('type', 'block_diagram');
    exportToSimulink(workspace.sys);
    after = find_system('type', 'block_diagram');
    newModels = setdiff(after, before);
    isUntitled = startsWith(newModels, 'untitled');
    newModels = newModels(isUntitled);
    if isempty(newModels)
        actualName = 'untitled';
    else
        actualName = char(newModels{1});
    end

    workspace.exportedModel = actualName;

    observation = sprintf( ...
        'Simulink model "%s" created with Tx, Rx, Channel, Config, and Stimulus blocks. Ready for runSimulation or exportAMI.', ...
        actualName);
end
