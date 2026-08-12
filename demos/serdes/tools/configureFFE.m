function [observation, workspace] = configureFFE(workspace, nvp)
%configureFFE Configure an FFE block on the transmitter or receiver.
%   [OBSERVATION, WORKSPACE] = configureFFE(WORKSPACE, ...) sets parameters
%   on the FFE block. If Side is not specified, defaults to Tx (most common).

    arguments (Input)
        workspace struct
        nvp.Side (1,1) string = "Tx"              % Side to configure: "Tx" or "Rx"
        nvp.NumTaps double = []                   % Number of FFE taps. Creates default weights with cursor at tap 2 (e.g., NumTaps=3 → [0 1 0])
        nvp.TapWeights (1,:) double = []          % Row vector of tap weights, e.g. [0 1 0 0 0]. Default=[0 1 0 0 0]
        nvp.TapSpacing (1,1) string = ""          % Tap spacing: "T-spaced","T/2-spaced","T/4-spaced","T/8-spaced","T/16-spaced","T/32-spaced". Default="T-spaced"
        nvp.Normalize (1,1) logical = true        % Normalize tap weights so sum(abs)=1: true or false. Default=true
        nvp.Mode double = []                % 0=Off, 1=Fixed. Omit to use default (Fixed). Only set if prompt specifies a mode.
    end
    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    side = upper(nvp.Side);
    createdArch = false;

    if side == "TX"
        % Soft-create: if no Tx architecture, create default [FFE]
        if ~isfield(workspace, 'txBlocks') || isempty(workspace.txBlocks)
            workspace.txBlocks = {serdes.FFE};
            workspace.txBlocks{1}.Mode = 1;
            workspace.txBlockTypes = "FFE";
            workspace.txModel = Transmitter('Blocks', workspace.txBlocks);
            createdArch = true;
        end
        [idx, blocks, types, createdBlock] = findOrCreateBlock(workspace.txBlocks, workspace.txBlockTypes, "FFE");
        if createdBlock
            workspace.txBlocks = blocks;
            workspace.txBlockTypes = types;
            workspace.txModel = Transmitter('Blocks', blocks);
            createdArch = true;
        end
    else
        % Soft-create: if no Rx architecture, create ONLY the requested FFE —
        % do not inject a DFECDR the user never asked for; no phantom companion block.
        if ~isfield(workspace, 'rxBlocks') || isempty(workspace.rxBlocks)
            workspace.rxBlocks = {serdes.FFE};
            workspace.rxBlockTypes = "FFE";
            workspace.rxModel = Receiver('Blocks', workspace.rxBlocks);
            createdArch = true;
        end
        [idx, blocks, types, createdBlock] = findOrCreateBlock(workspace.rxBlocks, workspace.rxBlockTypes, "FFE");
        if createdBlock
            workspace.rxBlocks = blocks;
            workspace.rxBlockTypes = types;
            workspace.rxModel = Receiver('Blocks', blocks);
            createdArch = true;
        end
    end

    obj = blocks{idx};

    if ~isempty(nvp.TapWeights)
        taps = nvp.TapWeights(:)';
        if nvp.Normalize && abs(sum(abs(taps)) - 1.0) > 0.01
            taps = taps / sum(abs(taps));
        end
        obj.TapWeights = taps;
    elseif ~isempty(nvp.NumTaps)
        taps = zeros(1, nvp.NumTaps);
        taps(min(2, nvp.NumTaps)) = 1;
        obj.TapWeights = taps;
    end
    if nvp.TapSpacing ~= ""
        obj.TapSpacing = nvp.TapSpacing;
    end
    if ~isempty(nvp.Mode)
        assert(nvp.Mode ~= 2, 'configureFFE:noAdapt', ...
            'FFE does not support Mode=2 (Adaptive). Use Mode=0 or Mode=1.');
        obj.Mode = nvp.Mode;
    end

    blocks{idx} = obj;
    if side == "TX"
        workspace.txBlocks = blocks;
    else
        workspace.rxBlocks = blocks;
    end

    prefix = "";
    if createdArch
        prefix = sprintf("No %s architecture set; created default. ", side);
    end
    observation = sprintf('%s%s FFE configured: %d taps, weights=[%s], Mode=%d. Ready for configureChannel or runAnalysis.', ...
        prefix, side, numel(obj.TapWeights), strtrim(num2str(obj.TapWeights, '%.3f ')), obj.Mode);
end

function [idx, blocks, types, created] = findOrCreateBlock(blocks, types, target)
    idx = find(types == upper(target), 1);
    created = false;
    if isempty(idx)
        newBlock = serdes.FFE;
        newBlock.Mode = 1;
        % Prepend the new block. Side-specific wiring (Transmitter vs
        % Receiver construction) is handled by the caller, so placement
        % here is identical for Tx and Rx.
        blocks = [{newBlock}, blocks];
        types = [upper(target), types];
        idx = 1;
        created = true;
    end
end
