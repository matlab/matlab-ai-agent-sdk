function [observation, workspace] = configureDFECDR(workspace, nvp)
%configureDFECDR Configure a DFECDR or DFE block on the receiver.
%   [OBSERVATION, WORKSPACE] = configureDFECDR(WORKSPACE, ...) sets parameters
%   on the DFECDR (or standalone DFE) block.

    arguments (Input)
        workspace struct
        nvp.NumTaps double = []             % Number of DFE taps (e.g., 4). Creates zeros(1,N) tap weights
        nvp.TapWeights (1,:) double = []          % Row vector of initial tap weights in Volts. Default=zeros(1,4)
        nvp.Mode double = []                % 0=Off, 1=Fixed, 2=Adapt. Omit to use default (Adapt). Only set if prompt specifies a mode.
        nvp.PhaseDetector (1,1) string = ""       % "BangBang" (default) or "BaudRateTypeA"
        nvp.PhaseOffset double = []         % Clock phase offset in fraction of symbol time, range (-0.5,0.5). Default=0
        nvp.ReferenceOffset double = []     % Reference clock frequency offset in ppm, range +/-3000. Default=0
        nvp.EqualizationGain double = []    % DFE adaptive gain (controls convergence rate). Default=9.6e-5
        nvp.CDRMode (1,1) string = ""             % "1st order" (default) or "2nd order"
        nvp.Count double = []               % CDR early/late vote count threshold, integer >= 4. Default=16
        nvp.Modulation double = []          % Number of signal levels: 2=NRZ, 4=PAM4. Default=2
    end
    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    % Soft-create: if no Rx architecture exists, create ONLY the requested
    % DFECDR — do not inject a CTLE the user never asked for; no phantom
    % companion block.
    createdArch = false;
    if ~isfield(workspace, 'rxBlocks') || isempty(workspace.rxBlocks)
        newBlock = serdes.DFECDR;
        newBlock.Mode = 2;
        workspace.rxBlocks = {newBlock};
        workspace.rxBlockTypes = "DFECDR";
        workspace.rxModel = Receiver('Blocks', workspace.rxBlocks);
        createdArch = true;
    end

    % Find DFECDR or DFE block
    idx = find(workspace.rxBlockTypes == "DFECDR", 1);
    blockType = "DFECDR";
    if isempty(idx)
        idx = find(workspace.rxBlockTypes == "DFE", 1);
        blockType = "DFE";
    end
    % Soft-create: if no DFECDR/DFE block found, append a DFECDR
    if isempty(idx)
        newBlock = serdes.DFECDR;
        newBlock.Mode = 2;
        workspace.rxBlocks{end+1} = newBlock;
        workspace.rxBlockTypes(end+1) = "DFECDR";
        workspace.rxModel = Receiver('Blocks', workspace.rxBlocks);
        idx = numel(workspace.rxBlocks);
        blockType = "DFECDR";
        createdArch = true;
    end

    obj = workspace.rxBlocks{idx};

    % Tap configuration: NumTaps creates zero-initialized taps; TapWeights sets explicit values
    if ~isempty(nvp.TapWeights)
        obj.TapWeights = nvp.TapWeights(:)';
    elseif ~isempty(nvp.NumTaps)
        obj.TapWeights = zeros(1, nvp.NumTaps);
    end

    if ~isempty(nvp.Mode)
        obj.Mode = nvp.Mode;
    end
    if nvp.PhaseDetector ~= "" && blockType == "DFECDR"
        obj.PhaseDetector = nvp.PhaseDetector;
    end
    if ~isempty(nvp.PhaseOffset) && blockType == "DFECDR"
        obj.PhaseOffset = nvp.PhaseOffset;
    end
    if ~isempty(nvp.ReferenceOffset) && isprop(obj, 'ReferenceOffset')
        obj.ReferenceOffset = nvp.ReferenceOffset;
    end
    if ~isempty(nvp.EqualizationGain)
        obj.EqualizationGain = nvp.EqualizationGain;
    end
    if nvp.CDRMode ~= "" && blockType == "DFECDR"
        obj.CDRMode = nvp.CDRMode;
    end
    if ~isempty(nvp.Count) && blockType == "DFECDR"
        obj.Count = nvp.Count;
    end
    if ~isempty(nvp.Modulation)
        obj.Modulation = nvp.Modulation;
    end

    workspace.rxBlocks{idx} = obj;

    prefix = "";
    if createdArch
        prefix = "No Rx architecture set; created a DFECDR-only Rx. ";
    end

    modeNames = ["Off", "Fixed", "Adapt"];
    modeLabel = modeNames(obj.Mode + 1);
    if blockType == "DFECDR"
        observation = sprintf('%s%s configured: %d taps, Mode=%d (%s), EqGain=%.2e, PhaseOffset=%.3f. Ready for configureChannel or runAnalysis.', ...
            prefix, blockType, numel(obj.TapWeights), obj.Mode, modeLabel, obj.EqualizationGain, obj.PhaseOffset);
    else
        observation = sprintf('%s%s configured: %d taps, Mode=%d (%s), EqGain=%.2e. Ready for configureChannel or runAnalysis.', ...
            prefix, blockType, numel(obj.TapWeights), obj.Mode, modeLabel, obj.EqualizationGain);
    end
end
