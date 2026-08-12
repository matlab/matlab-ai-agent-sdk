function [observation, workspace] = runAnalysis(workspace, nvp)
%runAnalysis Run statistical analysis on the current SerDes system.
%   [OBSERVATION, WORKSPACE] = runAnalysis(WORKSPACE) assembles the SerdesSystem
%   from the configured Tx, Rx, and channel, runs analysis(), and reports
%   key metrics (COM, EH, EW, VEC).

    arguments (Input)
        workspace struct
        nvp.Tag (1,1) string = "" % Optional label for this analysis run (e.g., "baseline")
    end

    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    if ~isfield(workspace, 'systemConfig')
        observation = "Cannot run analysis: no system configured. Call createSerdesSystem first (defaults to 28 Gbps NRZ if no params given).";
        return;
    end
    if ~isfield(workspace, 'channel')
        observation = "Cannot run analysis: no channel configured. Call configureChannel first (defaults to 8 dB loss if no params given).";
        return;
    end

    % Default to passthrough if no architecture was set
    if ~isfield(workspace, 'txModel')
        workspace.txModel = Transmitter('Blocks', {});
    end
    if ~isfield(workspace, 'rxModel')
        workspace.rxModel = Receiver('Blocks', {});
    end

    sysCfg = workspace.systemConfig;

    % Build SerdesSystem
    sys = SerdesSystem( ...
        'TxModel', workspace.txModel, ...
        'RxModel', workspace.rxModel, ...
        'SymbolTime', sysCfg.symbolTime, ...
        'SamplesPerSymbol', sysCfg.samplesPerSymbol, ...
        'Modulation', sysCfg.modulation, ...
        'BERtarget', sysCfg.berTarget);

    % Apply jitter/noise configuration
    if isfield(workspace, 'jitterConfig')
        jc = workspace.jitterConfig;
        jn = sys.JitterAndNoise;
        flds = fieldnames(jc);
        for i = 1:numel(flds)
            jn.(flds{i}) = jc.(flds{i});
        end
        sys.JitterAndNoise = jn;
    end

    % Apply channel
    ch = workspace.channel;
    switch ch.source
        case "loss"
            sys.ChannelData.ChannelLossdB = ch.ChannelLossdB;
            sys.ChannelData.ChannelLossFreq = ch.ChannelLossFreq;
            sys.ChannelData.ChannelDifferentialImpedance = ch.ChannelDifferentialImpedance;
            if isfield(ch, 'EnableCrosstalk') && ch.EnableCrosstalk
                sys.ChannelData.EnableCrosstalk = true;
                if isfield(ch, 'FEXTICN') && ~isempty(ch.FEXTICN)
                    sys.ChannelData.FEXTICN = ch.FEXTICN;
                end
                if isfield(ch, 'NEXTICN') && ~isempty(ch.NEXTICN)
                    sys.ChannelData.NEXTICN = ch.NEXTICN;
                end
                if isfield(ch, 'CrosstalkSpecification') && ch.CrosstalkSpecification ~= ""
                    sys.ChannelData.CrosstalkSpecification = ch.CrosstalkSpecification;
                end
            end
        case "sparameter"
            spChan = SParameterChannel;
            spChan.FileName = ch.SParameterFile;
            spChan.SampleInterval = sysCfg.sampleInterval;
            if isfield(ch, 'PortOrder') && ~isempty(ch.PortOrder)
                spChan.PortOrder = ch.PortOrder;
            end
            if isfield(ch, 'StopTime') && ~isempty(ch.StopTime)
                spChan.StopTime = ch.StopTime;
            end
            sys.ChannelData.Impulse = spChan.Impulse;
            sys.ChannelData.dt = spChan.SampleInterval;
        case "impulse"
            sys.ChannelData.Impulse = ch.Impulse;
            sys.ChannelData.dt = ch.dt;
    end

    % Run analysis
    results = analysis(sys);

    % Extract metrics
    metrics = struct();
    metrics.COM = sys.Metrics.summary.COMestimate;
    metrics.EH = sys.Metrics.summary.EH;
    metrics.EW = sys.Metrics.summary.EW;
    metrics.VEC = sys.Metrics.summary.VEC;
    if isfield(sys.Metrics.summary, 'eyeLinearity')
        metrics.eyeLinearity = sys.Metrics.summary.eyeLinearity;
    end
    metrics.minEH = min(metrics.EH);
    metrics.minEW = min(metrics.EW);

    % Store
    workspace.sys = sys;
    workspace.analysisResults = results;
    workspace.metrics = metrics;
    workspace.channelImpulse = results.impulse(:, 1);
    workspace.eqImpulse = results.impulse(:, 2);

    % Track iteration history
    iteration = struct('metrics', metrics, 'tag', nvp.Tag);
    if isfield(workspace, 'iterations')
        workspace.iterations{end+1} = iteration;
    else
        workspace.iterations = {iteration};
    end

    % Determine pass/fail heuristic
    passStr = "";
    if metrics.COM > 3
        passStr = " (PASS: COM > 3 dB)";
    else
        passStr = " (MARGINAL: COM < 3 dB)";
    end

    iterNum = numel(workspace.iterations);
    tagStr = "";
    if nvp.Tag ~= ""
        tagStr = sprintf('[%s] ', nvp.Tag);
    end

    % EH/EW are per-eye vectors (PAM4 has 3 eyes; NRZ has 1). Report the
    % worst-case (min) here and flag the eye count so the model knows per-eye
    % detail exists via getAnalysisResults. VEC is vertical eye closure in dB.
    nEye = numel(metrics.EH);
    if nEye > 1
        eyeNote = sprintf(' across %d eyes (worst-case; call getAnalysisResults for per-eye EH/EW)', nEye);
    else
        eyeNote = "";
    end
    observation = sprintf( ...
        '%sAnalysis #%d complete%s. COM=%.2f dB, minEH=%.1f mV, minEW=%.2f ps%s, VEC=%.2f dB. Use getAnalysisResults for adapted EQ values, or plotSerdesResults to visualize.', ...
        tagStr, iterNum, passStr, metrics.COM, metrics.minEH*1e3, metrics.minEW, eyeNote, metrics.VEC);
end
