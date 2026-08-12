function [observation, workspace] = configureVGA(workspace, nvp)
%configureVGA Configure a VGA (Variable Gain Amplifier) block.

    arguments (Input)
        workspace struct
        nvp.Side (1,1) string = ""            % "Tx" or "Rx"; auto-detected if omitted
        nvp.Gain double = []            % Gain in dB, range [-20, 20]. Default=0 dB (unity)
        nvp.Mode double = []            % 0=Off, 1=On. Default=1
    end
    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    side = upper(nvp.Side);
    createdBlock = false;
    if side == ""
        side = findSideWithBlock(workspace, "VGA", "RX");
    end

    if side == "TX"
        if ~isfield(workspace, 'txBlocks') || isempty(workspace.txBlocks)
            workspace.txBlocks = {serdes.VGA};
            workspace.txBlockTypes = "VGA";
            workspace.txModel = Transmitter('Blocks', workspace.txBlocks);
            createdBlock = true;
        end
        blocks = workspace.txBlocks;
        types = workspace.txBlockTypes;
    else
        if ~isfield(workspace, 'rxBlocks') || isempty(workspace.rxBlocks)
            % Create ONLY the requested VGA — no phantom DFECDR companion block.
            workspace.rxBlocks = {serdes.VGA};
            workspace.rxBlockTypes = "VGA";
            workspace.rxModel = Receiver('Blocks', workspace.rxBlocks);
            createdBlock = true;
        end
        blocks = workspace.rxBlocks;
        types = workspace.rxBlockTypes;
    end

    idx = find(types == "VGA", 1);
    % Soft-create: if VGA block not in architecture, prepend one
    if isempty(idx)
        newBlock = serdes.VGA;
        blocks = [{newBlock}, blocks];
        types = ["VGA", types];
        idx = 1;
        createdBlock = true;
        if side == "TX"
            workspace.txBlocks = blocks;
            workspace.txBlockTypes = types;
            workspace.txModel = Transmitter('Blocks', blocks);
        else
            workspace.rxBlocks = blocks;
            workspace.rxBlockTypes = types;
            workspace.rxModel = Receiver('Blocks', blocks);
        end
    end

    obj = blocks{idx};
    gainLinear = obj.Gain;
    if ~isempty(nvp.Gain)
        gainLinear = 10^(nvp.Gain/20);
        obj.Gain = gainLinear;
    end
    if ~isempty(nvp.Mode), obj.Mode = nvp.Mode; end

    blocks{idx} = obj;
    if side == "TX"
        workspace.txBlocks = blocks;
    else
        workspace.rxBlocks = blocks;
    end

    prefix = "";
    if createdBlock
        prefix = sprintf("No VGA in %s architecture; added one. ", side);
    end
    observation = sprintf('%s%s VGA configured: Gain=%.2f dB (%.3f V/V), Mode=%d. Ready for further block configuration or runAnalysis.', ...
        prefix, side, 20*log10(gainLinear), gainLinear, obj.Mode);
end

function side = findSideWithBlock(workspace, blockType, defaultSide)
    for s = ["TX", "RX"]
        if s == "TX" && isfield(workspace, 'txBlockTypes')
            if any(workspace.txBlockTypes == blockType), side = s; return; end
        elseif s == "RX" && isfield(workspace, 'rxBlockTypes')
            if any(workspace.rxBlockTypes == blockType), side = s; return; end
        end
    end
    % Block not found anywhere — default to specified side for soft-creation
    side = defaultSide;
end
