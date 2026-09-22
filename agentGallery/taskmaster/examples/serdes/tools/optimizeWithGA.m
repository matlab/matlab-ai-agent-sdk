function [observation, workspace] = optimizeWithGA(workspace, nvp)
%optimizeWithGA Optimize equalization parameters using genetic algorithm.
%   [OBSERVATION, WORKSPACE] = optimizeWithGA(WORKSPACE, ...) runs GA
%   optimization on specified block properties to maximize/minimize a metric.

    arguments (Input)
        workspace struct
        nvp.Objective (1,1) string = "maximize COM" % Goal: "maximize COM", "maximize EH", "maximize EW", or "minimize VEC"
        nvp.Block (1,1) string = ""                 % Block type to optimize: "FFE", "CTLE", "DFE", or "Channel". Do not include Tx/Rx prefix.
        nvp.Property (1,1) string = ""              % Property on the block to vary: "TapWeights", "ACGain", "DCGain", "NumTaps", "ChannelLossdB". Required.
        nvp.Indices (1,1) string = ""               % Comma-separated 1-based indices into the property vector to optimize. E.g. "1,3" for FFE taps 1 and 3. Omit for scalar properties.
        nvp.LowerBounds (1,:) double = []           % Lower bounds matching number of optimized elements. E.g. [-0.3, -0.3] for two FFE taps.
        nvp.UpperBounds (1,:) double = []           % Upper bounds matching number of optimized elements. E.g. [0, 0] for two FFE taps.
        nvp.PopulationSize (1,1) double = 10        % GA population size (default 10)
        nvp.MaxGenerations (1,1) double = 10        % GA maximum generations (default 10)
    end

    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    if ~isfield(workspace, 'systemConfig')
        observation = "Cannot optimize: no system configured. Call createSerdesSystem first.";
        return;
    end
    if ~isfield(workspace, 'channel')
        observation = "Cannot optimize: no channel configured. Call configureChannel first (defaults to 8 dB loss if no params given).";
        return;
    end

    if ~isfield(workspace, 'txBlocks')
        workspace.txBlocks = {};
    end
    if ~isfield(workspace, 'rxBlocks')
        workspace.rxBlocks = {};
    end

    blockName = upper(nvp.Block);
    blockName = regexprep(blockName, '^(TX|RX)', '');
    propName = nvp.Property;

    assert(blockName ~= "", 'optimizeWithGA:noBlock', ...
        'Block is required. Valid: "FFE", "CTLE", "DFE", "Channel".');
    assert(propName ~= "", 'optimizeWithGA:noProperty', ...
        'Property is required. E.g. "TapWeights", "ACGain", "DCGain", "NumTaps", "ChannelLossdB".');

    % Parse indices — infer if not provided
    if nvp.Indices ~= ""
        indices = str2double(strsplit(nvp.Indices, ','));
        assert(all(~isnan(indices)), 'optimizeWithGA:badIndices', ...
            'Indices must be comma-separated integers. Got: "%s".', nvp.Indices);
        indices = round(indices);
    else
        indices = inferIndices(blockName, propName, workspace);
    end

    % Determine number of optimization variables
    nVars = numel(indices);
    if nVars == 0
        nVars = 1;
    end

    % Validate bounds
    lb = nvp.LowerBounds(:);
    ub = nvp.UpperBounds(:);
    if isempty(lb) || isempty(ub)
        [lb, ub] = defaultBounds(blockName, propName, nVars);
    end
    assert(numel(lb) == nVars && numel(ub) == nVars, ...
        'optimizeWithGA:boundsSize', ...
        'Bounds length (%d, %d) must match number of variables (%d).', ...
        numel(lb), numel(ub), nVars);

    sysCfg = workspace.systemConfig;
    [objFcn, objName] = parseObjective(nvp.Objective);

    % Build linear constraint for FFE normalization
    [Aineq, bineq] = buildConstraints(blockName, propName, indices, nVars);

    evalCount = 0;

    function val = fitness(x)
        evalCount = evalCount + 1;

        txB = workspace.txBlocks;
        rxB = workspace.rxBlocks;

        applyVariables(txB, rxB, workspace, blockName, propName, indices, x);

        tx = Transmitter('Blocks', txB);
        rx = Receiver('Blocks', rxB);
        sys = SerdesSystem( ...
            'TxModel', tx, 'RxModel', rx, ...
            'SymbolTime', sysCfg.symbolTime, ...
            'SamplesPerSymbol', sysCfg.samplesPerSymbol, ...
            'Modulation', sysCfg.modulation, ...
            'BERtarget', sysCfg.berTarget);

        ch = workspace.channel;
        if ch.source == "loss"
            lossdB = ch.ChannelLossdB;
            if blockName == "CHANNEL" && lower(propName) == "channellossdb"
                lossdB = x(1);
            end
            sys.ChannelData.ChannelLossdB = lossdB;
            sys.ChannelData.ChannelLossFreq = ch.ChannelLossFreq;
            sys.ChannelData.ChannelDifferentialImpedance = ch.ChannelDifferentialImpedance;
        end

        analysis(sys);
        val = objFcn(sys);
    end

    % Discretize each variable into a grid; gaSI searches integer gene indices
    % into that grid. SerDes tap/gain spaces are quantized, which is exactly
    % what this Signal Integrity Toolbox GA is built for. We own the outer loop:
    % gaSI hands back a population, we score it into column 1 and feed it back.
    % No Global Optimization Toolbox dependency (gaSI is base MATLAB).
    nLevels = 41;
    lbRow = lb(:)'; ubRow = ub(:)';
    span = ubRow - lbRow;
    span(span == 0) = 1;   % avoid divide-by-zero for pinned variables
    decodeGenes = @(g) lbRow + (g - 1) ./ (nLevels - 1) .* span;

    popSize = max(4, round(nvp.PopulationSize));
    maxGen  = max(1, round(nvp.MaxGenerations));
    maxGeneValues = repmat(nLevels, 1, nVars);
    OFFSET = 1e4;   % keep feasible fitness strictly positive; gaSI culls <= 0

    % Seed generation 1 at the grid midpoint (neutral warm start).
    presetGene = repmat(round((nLevels + 1) / 2), 1, nVars);
    ancestors = zeros(popSize * (maxGen + 2), nVars);
    lastResults = [NaN, presetGene];
    bestFit = -Inf; bestGenes = presetGene;

    for gen = 1:maxGen
        try
            [gaStatus, nextGen, ancestors] = si.utilities.optimization.gaSI( ...
                gen, popSize, maxGeneValues, ancestors, lastResults);
        catch
            % GA can throw for very small variable counts on later generations;
            % stop cleanly and keep the best design found so far.
            break;
        end
        if gaStatus == 2
            break;   % no member of the last generation had positive fitness
        end
        for r = 1:size(nextGen, 1)
            if isnan(nextGen(r, 1))
                x = decodeGenes(nextGen(r, 2:end));
                if ~isempty(Aineq) && any(Aineq * x(:) > bineq + 1e-12)
                    nextGen(r, 1) = 0;   % infeasible -> culled by gaSI
                else
                    nextGen(r, 1) = OFFSET - fitness(x);   % higher = better
                end
            end
        end
        lastResults = nextGen;
        [genBest, iBest] = max(nextGen(:, 1));
        if genBest > bestFit
            bestFit = genBest;
            bestGenes = nextGen(iBest, 2:end);
        end
    end

    xOpt = decodeGenes(bestGenes);
    fVal = OFFSET - bestFit;   % recover raw objFcn value (ga-minimization sign)

    % Package results
    optResult = struct();
    optResult.objective = nvp.Objective;
    optResult.bestMetricValue = abs(fVal);
    optResult.block = nvp.Block;
    optResult.property = propName;
    optResult.indices = indices;
    optResult.optimalValues = xOpt;
    optResult.evaluationCount = evalCount;

    % For FFE TapWeights, record the full tap vector with derived main
    if blockName == "FFE" && lower(propName) == "tapweights"
        optResult.optimalTapWeights = buildFullFFETaps(workspace.txBlocks, indices, xOpt);
    end

    workspace.optimization = optResult;

    % Format observation
    obsStr = sprintf( ...
        'GA optimization complete (%d evaluations). Objective: %s = %.3f.', ...
        evalCount, objName, abs(fVal));
    if isfield(optResult, 'optimalTapWeights')
        tapStr = sprintf('%.4f ', optResult.optimalTapWeights);
        obsStr = strcat(obsStr, sprintf(' Optimal FFE TapWeights: [%s].', strtrim(tapStr)));
    else
        valStr = sprintf('%.4g ', xOpt);
        obsStr = strcat(obsStr, sprintf(' Optimal %s.%s values: [%s].', nvp.Block, propName, strtrim(valStr)));
    end

    observation = string(obsStr);
end

%% --- Local functions ---

function [fcn, name] = parseObjective(objective)
    obj = lower(strtrim(objective));
    % Accept bare metric names — default to maximize
    if ~contains(obj, "max") && ~contains(obj, "min")
        obj = "maximize " + obj;
    end
    if contains(obj, "maximize") || contains(obj, "max")
        if contains(obj, "com")
            fcn = @(sys) -sys.Metrics.summary.COMestimate;
            name = "COM";
        elseif contains(obj, "eh") || contains(obj, "eye height")
            fcn = @(sys) -min(sys.Metrics.summary.EH);
            name = "EH";
        elseif contains(obj, "ew") || contains(obj, "eye width")
            fcn = @(sys) -min(sys.Metrics.summary.EW);
            name = "EW";
        else
            error('optimizeWithGA:unknownObj', 'Unknown objective: %s', objective);
        end
    elseif contains(obj, "minimize") || contains(obj, "min")
        if contains(obj, "vec")
            fcn = @(sys) sys.Metrics.summary.VEC;
            name = "VEC";
        else
            error('optimizeWithGA:unknownObj', 'Unknown objective: %s', objective);
        end
    else
        error('optimizeWithGA:invalidObj', ...
            'Objective must start with maximize or minimize. Got: "%s". Valid: "maximize COM", "maximize EH", "maximize EW", "minimize VEC".', ...
            objective);
    end
end

function indices = inferIndices(blockName, propName, workspace)
    % Infer which elements to optimize when Indices is not provided.
    % FFE TapWeights: optimize all non-main-cursor taps.
    % DFE TapWeights: optimize all taps.
    % Scalar properties: return empty (handled as single variable).
    indices = [];
    switch upper(blockName)
        case "FFE"
            if lower(propName) == "tapweights"
                blk = findBlock(workspace.txBlocks, 'serdes.FFE');
                if ~isempty(blk)
                    taps = blk.TapWeights;
                    [~, mainIdx] = max(abs(taps));
                    indices = setdiff(1:numel(taps), mainIdx);
                end
            end
        case "DFE"
            if lower(propName) == "tapweights"
                blk = findBlock(workspace.rxBlocks, 'serdes.DFECDR');
                if isempty(blk)
                    blk = findBlock(workspace.rxBlocks, 'serdes.DFE');
                end
                if ~isempty(blk)
                    indices = 1:numel(blk.TapWeights);
                end
            end
    end
end

function [lb, ub] = defaultBounds(blockName, propName, nVars)
    switch upper(blockName)
        case "FFE"
            lb = -0.3 * ones(nVars, 1);
            ub = zeros(nVars, 1);
        case "CTLE"
            if lower(propName) == "acgain"
                lb = zeros(nVars, 1);
                ub = 20 * ones(nVars, 1);
            else
                lb = -10 * ones(nVars, 1);
                ub = zeros(nVars, 1);
            end
        case "DFE"
            lb = ones(nVars, 1);
            ub = 15 * ones(nVars, 1);
        case "CHANNEL"
            lb = 5 * ones(nVars, 1);
            ub = 40 * ones(nVars, 1);
        otherwise
            lb = -1 * ones(nVars, 1);
            ub = ones(nVars, 1);
    end
end

function [A, b] = buildConstraints(blockName, propName, indices, nVars)
    A = [];
    b = [];
    if blockName ~= "FFE" || lower(propName) ~= "tapweights"
        return;
    end
    % FFE normalization: sum of |optimized taps| <= 0.6 so main >= 0.4
    % Since FFE non-main taps are <= 0: -x1 + -x2 + ... <= 0.6
    A = -ones(1, nVars);
    b = 0.6;
end

function applyVariables(txBlocks, rxBlocks, workspace, blockName, propName, indices, x)
    switch upper(blockName)
        case "FFE"
            blk = findBlock(txBlocks, 'serdes.FFE');
            if isempty(blk), return; end
            if lower(propName) == "tapweights"
                taps = blk.TapWeights;
                % Apply optimized values at indices, derive main
                for k = 1:numel(indices)
                    taps(indices(k)) = x(k);
                end
                % Renormalize: main cursor = 1 - sum(|non-main|)
                [~, mainIdx] = max(abs(taps));
                nonMainSum = sum(abs(taps)) - abs(taps(mainIdx));
                taps(mainIdx) = sign(taps(mainIdx)) * (1 - nonMainSum);
                blk.TapWeights = taps;
            end
        case "CTLE"
            blk = findBlock(rxBlocks, 'serdes.CTLE');
            if isempty(blk), return; end
            switch lower(propName)
                case "acgain"
                    blk.ACGain = x(1);
                case "dcgain"
                    blk.DCGain = x(1);
            end
        case "DFE"
            blk = findBlock(rxBlocks, 'serdes.DFECDR');
            if isempty(blk)
                blk = findBlock(rxBlocks, 'serdes.DFE');
            end
            if isempty(blk), return; end
            if lower(propName) == "numtaps"
                blk.TapWeights = zeros(1, round(x(1)));
            elseif lower(propName) == "tapweights"
                taps = blk.TapWeights;
                for k = 1:numel(indices)
                    if indices(k) <= numel(taps)
                        taps(indices(k)) = x(k);
                    end
                end
                blk.TapWeights = taps;
            end
        case "CHANNEL"
            % Handled in fitness function
    end
end

function blk = findBlock(blocks, className)
    blk = [];
    for k = 1:numel(blocks)
        if isa(blocks{k}, className)
            blk = blocks{k};
            return;
        end
    end
end

function fullTaps = buildFullFFETaps(txBlocks, indices, xOpt)
    blk = findBlock(txBlocks, 'serdes.FFE');
    if isempty(blk)
        fullTaps = xOpt;
        return;
    end
    taps = blk.TapWeights;
    for k = 1:numel(indices)
        taps(indices(k)) = xOpt(k);
    end
    [~, mainIdx] = max(abs(taps));
    nonMainSum = sum(abs(taps)) - abs(taps(mainIdx));
    taps(mainIdx) = 1 - nonMainSum;
    fullTaps = taps;
end
