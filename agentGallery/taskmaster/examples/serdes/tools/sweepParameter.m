function [observation, workspace] = sweepParameter(workspace, nvp)
%sweepParameter Sweep a parameter over a range and collect metrics.
%   [OBSERVATION, WORKSPACE] = sweepParameter(WORKSPACE, ...) varies one or
%   two parameters over specified ranges, runs analysis at each point, and
%   returns the metrics grid.

    arguments (Input)
        workspace struct
        nvp.Parameter (1,1) string   % Parameter name to sweep: "Modulation", "FFETapWeights", "CTLEACGain", "CTLEDCGain", "CTLEConfigSelect", "DFENumTaps", "ChannelLossdB", or "TxRiseTime" (in ps)
        nvp.Values (1,:) double = []      % Explicit list of all values to sweep. Units: dB for gains/loss, count for taps/modulation, ps for TxRiseTime. Must contain every point.
        nvp.SecondParameter (1,1) string = "" % Second parameter name for 2D sweep (same valid values as Parameter). Only use for 2D sweeps.
        nvp.SecondParameterValues (1,:) double = []    % Explicit list of values for the second parameter in a 2D sweep.
    end

    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    if ~isfield(workspace, 'systemConfig')
        observation = "Cannot sweep: no system configured. Call createSerdesSystem first.";
        return;
    end
    if ~isfield(workspace, 'channel')
        observation = "Cannot sweep: no channel configured. Call configureChannel first (defaults to 8 dB loss if no params given).";
        return;
    end

    % Default to passthrough if no architecture was set
    if ~isfield(workspace, 'txBlocks')
        workspace.txBlocks = {};
    end
    if ~isfield(workspace, 'rxBlocks')
        workspace.rxBlocks = {};
    end
    if ~isfield(workspace, 'rxBlockTypes')
        workspace.rxBlockTypes = string.empty;
    end
    if ~isfield(workspace, 'txBlockTypes')
        workspace.txBlockTypes = string.empty;
    end

    % Auto-create blocks referenced by sweep params but missing from workspace
    allParams = string(nvp.Parameter);
    if nvp.SecondParameter ~= ""
        allParams(end+1) = nvp.SecondParameter;
    end
    for pIdx = 1:numel(allParams)
        p = lower(allParams(pIdx));
        if ismember(p, ["ctleacgain", "ctledcgain", "ctleconfigselect"])
            if ~any(workspace.rxBlockTypes == "CTLE")
                workspace.rxBlocks{end+1} = serdes.CTLE;
                workspace.rxBlockTypes(end+1) = "CTLE";
            end
        end
        if ismember(p, ["dfenumtaps"])
            if ~any(workspace.rxBlockTypes == "DFECDR") && ~any(workspace.rxBlockTypes == "DFE")
                workspace.rxBlocks{end+1} = serdes.DFECDR;
                workspace.rxBlocks{end}.Mode = 2;
                workspace.rxBlockTypes(end+1) = "DFECDR";
            end
        end
        if ismember(p, ["ffetapweights"])
            if ~any(workspace.txBlockTypes == "FFE")
                workspace.txBlocks{end+1} = serdes.FFE;
                workspace.txBlockTypes(end+1) = "FFE";
            end
        end
    end

    sysCfg = workspace.systemConfig;
    param1 = nvp.Parameter;
    vals1 = nvp.Values;

    validParams = ["Modulation", "FFETapWeights", "CTLEACGain", "CTLEDCGain", ...
        "CTLEConfigSelect", "DFENumTaps", "ChannelLossdB", "TxRiseTime"];
    if ~ismember(param1, validParams)
        observation = sprintf('Invalid Parameter "%s". Valid: %s.', param1, strjoin(validParams, ', '));
        return;
    end

    % No sweep range given: guide the model to supply one instead of crashing
    % on the missing field (fix #24 — feedback only via observation). The scan
    % range is a real engineering choice, so the tool asks rather than inventing
    % a domain the prompt never specified (same principle as fix #31 soft-create).
    if isempty(vals1)
        [unitHint, egVals] = sweepValueHint(param1);
        observation = sprintf(['No sweep Values given for %s. Pass the list of points to scan, ' ...
            'e.g. Values=%s (%s). Pick a range appropriate to the prompt, then call sweepParameter again.'], ...
            param1, egVals, unitHint);
        return;
    end

    % Validate TxRiseTime units: values should be in ps (e.g., 5-50), not seconds
    if param1 == "TxRiseTime" && all(vals1 < 1)
        observation = sprintf('TxRiseTime values appear to be in seconds. Provide values in picoseconds (e.g., [5, 10, 15, 20] for 5 ps to 20 ps).');
        return;
    end

    is2D = (nvp.SecondParameter ~= "" && ~isempty(nvp.SecondParameterValues));

    if is2D
        param2 = nvp.SecondParameter;
        vals2 = nvp.SecondParameterValues;
        nTotal = numel(vals1) * numel(vals2);
        comGrid = zeros(numel(vals1), numel(vals2));
        ehGrid = zeros(numel(vals1), numel(vals2));
        ewGrid = zeros(numel(vals1), numel(vals2));
    else
        nTotal = numel(vals1);
        comVec = zeros(1, nTotal);
        ehVec = zeros(1, nTotal);
        ewVec = zeros(1, nTotal);
    end

    % Sweep loop
    impulses = {};
    for i = 1:numel(vals1)
        if is2D
            for j = 1:numel(vals2)
                [com, eh, ew, impData] = evaluatePoint(workspace, sysCfg, param1, vals1(i), param2, vals2(j));
                comGrid(i, j) = com;
                ehGrid(i, j) = eh;
                ewGrid(i, j) = ew;
                impulses{end+1} = impData; %#ok<AGROW>
            end
        else
            [com, eh, ew, impData] = evaluatePoint(workspace, sysCfg, param1, vals1(i), "", []);
            comVec(i) = com;
            ehVec(i) = eh;
            ewVec(i) = ew;
            impulses{i} = impData;
        end
    end

    % Store results
    sweep = struct();
    sweep.parameter = param1;
    sweep.values = vals1;
    if is2D
        sweep.parameter2 = param2;
        sweep.values2 = vals2;
        sweep.COM = comGrid;
        sweep.EH = ehGrid;
        sweep.EW = ewGrid;
        [bestCOM, bestLinIdx] = max(comGrid(:));
        [bestI, bestJ] = ind2sub(size(comGrid), bestLinIdx);
        sweep.bestValue1 = vals1(bestI);
        sweep.bestValue2 = vals2(bestJ);
        sweep.bestCOM = bestCOM;
        observation = sprintf( ...
            '2D sweep complete: %s x %s (%d points). Best COM=%.2f dB at %s=%.4g, %s=%.4g. Use plotSweepResults to visualize.', ...
            param1, param2, nTotal, bestCOM, param1, vals1(bestI), param2, vals2(bestJ));
    else
        sweep.COM = comVec;
        sweep.EH = ehVec;
        sweep.EW = ewVec;
        [bestCOM, bestIdx] = max(comVec);
        sweep.bestValue = vals1(bestIdx);
        sweep.bestCOM = bestCOM;
        comStrs = arrayfun(@(v,c) sprintf('%.4g:%.2f', v, c), vals1, comVec, 'UniformOutput', false);
        observation = string(sprintf( ...
            'Sweep complete: %s over %d values. Best COM=%.2f dB at %s=%.4g. Results [%s=COM]: %s. Use plotSweepResults to visualize (PlotStyle="line"/"bar" for single metric, "stacked" with Metrics="COM,EH,EW" for multi-metric subplots, "impulse" for impulse overlay).', ...
            param1, nTotal, bestCOM, param1, vals1(bestIdx), param1, strjoin(string(comStrs), ', ')));
    end

    sweep.impulses = impulses;
    workspace.sweep = sweep;
end

function [com, eh, ew, impulseData] = evaluatePoint(workspace, sysCfg, param1, val1, param2, val2)
    % Clone workspace blocks (originals may be locked from prior tool calls)
    txBlocks = cellfun(@(b) clone(b), workspace.txBlocks, 'UniformOutput', false);
    rxBlocks = cellfun(@(b) clone(b), workspace.rxBlocks, 'UniformOutput', false);
    cellfun(@release, txBlocks, 'UniformOutput', false);
    cellfun(@release, rxBlocks, 'UniformOutput', false);

    modulation = sysCfg.modulation;
    symbolTime = sysCfg.symbolTime;
    dataRate = sysCfg.dataRate;

    % Handle Modulation sweep — recalculate timing
    if lower(param1) == "modulation"
        modulation = val1;
        symbolTime = log2(modulation) / dataRate;
    end
    if param2 ~= "" && lower(param2) == "modulation"
        modulation = val2;
        symbolTime = log2(modulation) / dataRate;
    end

    nyquistFreq = 1 / (2 * symbolTime);

    applyParam(txBlocks, rxBlocks, param1, val1);
    if param2 ~= ""
        applyParam(txBlocks, rxBlocks, param2, val2);
    end

    tx = Transmitter('Blocks', txBlocks);
    rx = Receiver('Blocks', rxBlocks);

    % TxRiseTime: value in ps, convert to seconds
    if lower(param1) == "txrisetime"
        tx.RiseTime = val1 * 1e-12;
    end
    if param2 ~= "" && lower(param2) == "txrisetime"
        tx.RiseTime = val2 * 1e-12;
    end

    sys = SerdesSystem( ...
        'TxModel', tx, 'RxModel', rx, ...
        'SymbolTime', symbolTime, ...
        'SamplesPerSymbol', sysCfg.samplesPerSymbol, ...
        'Modulation', modulation, ...
        'BERtarget', sysCfg.berTarget);

    ch = workspace.channel;
    if ch.source == "loss"
        if param1 == "ChannelLossdB"
            sys.ChannelData.ChannelLossdB = val1;
        else
            sys.ChannelData.ChannelLossdB = ch.ChannelLossdB;
        end
        sys.ChannelData.ChannelLossFreq = nyquistFreq;
        sys.ChannelData.ChannelDifferentialImpedance = ch.ChannelDifferentialImpedance;
    end

    analysis(sys);
    com = sys.Metrics.summary.COMestimate;
    eh = min(sys.Metrics.summary.EH);
    ew = min(sys.Metrics.summary.EW);
    impulseData.response = sys.ImpulseResponse;
    impulseData.dt = sys.dt;
end

function [unitHint, egVals] = sweepValueHint(param)
    % Per-parameter unit and an example range, so the guiding observation is
    % actionable. Values are illustrative only — the model must choose a range
    % suited to the prompt, not copy these blindly.
    switch lower(char(param))
        case "channellossdb"
            unitHint = "dB"; egVals = "[4, 8, 12, 16, 20]";
        case {"ctleacgain", "ctledcgain"}
            unitHint = "dB"; egVals = "[0, 3, 6, 9, 12]";
        case "ctleconfigselect"
            unitHint = "config index"; egVals = "[0, 1, 2, 3]";
        case "dfenumtaps"
            unitHint = "tap count"; egVals = "[1, 2, 3, 4, 5]";
        case "txrisetime"
            unitHint = "ps"; egVals = "[5, 10, 15, 20]";
        case "modulation"
            unitHint = "levels (2=NRZ, 4=PAM4)"; egVals = "[2, 4]";
        case "ffetapweights"
            unitHint = "tap-weight vectors — use a 2D/explicit sweep instead"; egVals = "[...]";
        otherwise
            unitHint = "appropriate units"; egVals = "[...]";
    end
end

function applyParam(txBlocks, rxBlocks, paramName, paramValue)
    switch lower(char(paramName))
        case "ffetapweights"
            for k = 1:numel(txBlocks)
                if isa(txBlocks{k}, 'serdes.FFE')
                    txBlocks{k}.TapWeights = paramValue;
                end
            end
        case "ctleacgain"
            for k = 1:numel(rxBlocks)
                if isa(rxBlocks{k}, 'serdes.CTLE')
                    rxBlocks{k}.Specification = 'DC Gain and AC Gain';
                    rxBlocks{k}.ACGain = paramValue;
                end
            end
        case "ctledcgain"
            for k = 1:numel(rxBlocks)
                if isa(rxBlocks{k}, 'serdes.CTLE')
                    rxBlocks{k}.DCGain = paramValue;
                end
            end
        case "ctleconfigselect"
            for k = 1:numel(rxBlocks)
                if isa(rxBlocks{k}, 'serdes.CTLE')
                    rxBlocks{k}.ConfigSelect = paramValue;
                end
            end
        case "dfenumtaps"
            for k = 1:numel(rxBlocks)
                if isa(rxBlocks{k}, 'serdes.DFECDR') || isa(rxBlocks{k}, 'serdes.DFE')
                    rxBlocks{k}.TapWeights = zeros(1, round(paramValue));
                end
            end
        case "txrisetime"
            % Handled in caller via TxModel.RiseTime
        case "channellossdb"
            % Handled in caller
        case "modulation"
            % Handled in caller
    end
end
