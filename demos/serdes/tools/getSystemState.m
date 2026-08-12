function [observation, workspace] = getSystemState(workspace, nvp)
%getSystemState Return current system configuration and last metrics.
%   [OBSERVATION, WORKSPACE] = getSystemState(WORKSPACE) reports the current
%   state of the SerDes system: timing, architecture, channel, and metrics.

    arguments (Input)
        workspace struct
        nvp.Verbose (1,1) logical = false       % Include detailed block parameters: true or false
        nvp.Section (1,1) string = "all"        % Section to report: "all", "systemConfig", "tx", "rx", or "channel"
    end

    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    parts = {};

    % System config
    if isfield(workspace, 'systemConfig')
        sc = workspace.systemConfig;
        parts{end+1} = sprintf('System: %.2f Gbps, PAM%d, SymbolTime=%.2f ps, %d sps', ...
            sc.dataRate/1e9, sc.modulation, sc.symbolTime*1e12, sc.samplesPerSymbol);
    else
        parts{end+1} = 'System: not configured';
    end

    % Tx architecture
    if isfield(workspace, 'txBlockTypes') && ~isempty(workspace.txBlockTypes)
        parts{end+1} = sprintf('Tx: [%s]', strjoin(workspace.txBlockTypes, " -> "));
        if isfield(workspace, 'txBlocks')
            for i = 1:numel(workspace.txBlocks)
                obj = workspace.txBlocks{i};
                if isa(obj, 'serdes.FFE')
                    parts{end+1} = sprintf('  FFE: taps=[%s], Mode=%d', ...
                        num2str(obj.TapWeights, '%.3f '), obj.Mode);
                end
            end
        end
    else
        parts{end+1} = 'Tx: not configured';
    end

    % Rx architecture
    if isfield(workspace, 'rxBlockTypes') && ~isempty(workspace.rxBlockTypes)
        parts{end+1} = sprintf('Rx: [%s]', strjoin(workspace.rxBlockTypes, " -> "));
        if isfield(workspace, 'rxBlocks')
            for i = 1:numel(workspace.rxBlocks)
                obj = workspace.rxBlocks{i};
                if isa(obj, 'serdes.CTLE')
                    parts{end+1} = sprintf('  CTLE: Spec="%s", ACGain=%.1f, Mode=%d', ...
                        string(obj.Specification), obj.ACGain, obj.Mode);
                elseif isa(obj, 'serdes.DFECDR')
                    parts{end+1} = sprintf('  DFECDR: %d taps, Mode=%d, TapWeights=[%s] (block object — initial values, not adapted)', ...
                        numel(obj.TapWeights), obj.Mode, num2str(obj.TapWeights, '%.4f '));
                end
            end
        end
    else
        parts{end+1} = 'Rx: not configured';
    end

    % Channel
    if isfield(workspace, 'channel')
        ch = workspace.channel;
        switch ch.source
            case "loss"
                parts{end+1} = sprintf('Channel: loss=%.1f dB at %.2f GHz, %d ohm', ...
                    ch.ChannelLossdB, ch.ChannelLossFreq/1e9, ch.ChannelDifferentialImpedance);
            case "sparameter"
                parts{end+1} = sprintf('Channel: S-param file "%s"', ch.SParameterFile);
            case "impulse"
                parts{end+1} = sprintf('Channel: impulse (%d samples)', numel(ch.Impulse));
        end
    else
        parts{end+1} = 'Channel: not configured';
    end

    % Last metrics
    if isfield(workspace, 'metrics')
        m = workspace.metrics;
        parts{end+1} = sprintf('Last metrics: COM=%.2f dB, EH=%.1f mV, EW=%.1f ps', ...
            m.COM, m.minEH*1e3, m.minEW);
        % Show adapted taps inline if available
        if isfield(workspace, 'analysisResults') && isfield(workspace.analysisResults, 'outparams')
            for k = 1:numel(workspace.analysisResults.outparams)
                op = workspace.analysisResults.outparams{k};
                if isstruct(op) && isfield(op, 'DFECDR') && isfield(op.DFECDR, 'TapWeights')
                    parts{end+1} = sprintf('Adapted DFE taps (from analysis): [%s]', num2str(op.DFECDR.TapWeights, '%.4f '));
                elseif isstruct(op) && isfield(op, 'DFE') && isfield(op.DFE, 'TapWeights')
                    parts{end+1} = sprintf('Adapted DFE taps (from analysis): [%s]', num2str(op.DFE.TapWeights, '%.4f '));
                end
            end
        else
            parts{end+1} = 'Adapted EQ values: call getAnalysisResults(Query="adaptedtaps") or "adaptedctle"';
        end
    end

    % Iteration count
    if isfield(workspace, 'iterations')
        parts{end+1} = sprintf('Iterations: %d', numel(workspace.iterations));
    end

    % Hint at what's missing
    missing = {};
    if ~isfield(workspace, 'systemConfig'), missing{end+1} = "createSerdesSystem"; end
    if ~isfield(workspace, 'txBlockTypes') || isempty(workspace.txBlockTypes), missing{end+1} = "setTransmitterArchitecture"; end
    if ~isfield(workspace, 'rxBlockTypes') || isempty(workspace.rxBlockTypes), missing{end+1} = "setReceiverArchitecture"; end
    if ~isfield(workspace, 'channel'), missing{end+1} = "configureChannel"; end
    if ~isempty(missing)
        parts{end+1} = sprintf('Pending: %s', strjoin(string(missing), ', '));
    elseif ~isfield(workspace, 'metrics')
        parts{end+1} = 'Ready for runAnalysis.';
    end

    observation = strjoin(parts, '\n');
end
