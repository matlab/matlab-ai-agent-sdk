function [observation, workspace] = configureChannel(workspace, nvp)
%configureChannel Configure the analog channel for the SerDes system.
%   [OBSERVATION, WORKSPACE] = configureChannel(WORKSPACE, ...) sets up the
%   channel using a loss model, S-parameter file, or raw impulse response.
%   Source is determined by which NV pairs are provided.

    arguments (Input)
        workspace struct
        nvp.Source (1,1) string = ""                  % Channel source type: "loss", "sparameter", or "impulse"
        nvp.Loss double = []                          % Channel loss in dB at target frequency. Default=8
        nvp.Frequency double = []                     % Target frequency in Hz for loss specification. Default=system Nyquist (or 10e9)
        nvp.Impedance double = []                     % Differential impedance in Ohms. Default=100
        nvp.SParameterFile (1,1) string = ""          % Path to Touchstone .sNp file
        nvp.PortOrder (1,:) double = []               % Port mapping vector, e.g. [1 3 2 4]
        nvp.StopTime double = []                      % Impulse truncation time in seconds
        nvp.Impulse (:,1) double = []                 % Impulse response column vector
        nvp.dt double = []                            % Sample interval in seconds (e.g., 2.23e-12)
        nvp.EnableCrosstalk (1,1) logical = false     % Enable crosstalk modeling: true or false. Default=false
        nvp.CrosstalkSpecification (1,1) string = ""  % "CEI-28G-SR" (default), "CEI-25G-LR", "CEI-28G-VSR", "100GBASE-CR4", or "Custom"
        nvp.FEXTICN double = []                       % Far-end integrated crosstalk noise in Volts. Default=15e-3
        nvp.NEXTICN double = []                       % Near-end integrated crosstalk noise in Volts. Default=10e-3
    end
    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    % Soft gate: systemConfig is needed for Nyquist fallback and impulse dt,
    % but if Loss+Frequency are both explicit we can proceed without it.
    hasSystem = isfield(workspace, 'systemConfig');
    if ~hasSystem
        % Determine if we truly need systemConfig based on what's provided
        isImpulseSource = (nvp.Source == "impulse") || ...
            (nvp.Source == "" && ~isempty(nvp.Impulse));
        needsSystem = isempty(nvp.Frequency) || ...
            (isImpulseSource && isempty(nvp.dt));
        assert(~needsSystem, 'configureChannel:noSystem', ...
            'Call createSerdesSystem first (needed for Nyquist/dt defaults), or provide Frequency and dt explicitly.');
        % Create a minimal sysCfg placeholder for downstream code
        freqVal = nvp.Frequency;
        if isempty(freqVal), freqVal = 14e9; end
        dtVal = nvp.dt;
        if isempty(dtVal), dtVal = NaN; end
        sysCfg = struct('nyquistFreq', freqVal, 'sampleInterval', dtVal, ...
            'dataRate', NaN, 'modulation', 2);
    else
        sysCfg = workspace.systemConfig;
    end
    source = nvp.Source;

    % Auto-detect source from provided params if not explicit
    if source == ""
        if ~isempty(nvp.Loss)
            source = "loss";
        elseif nvp.SParameterFile ~= ""
            source = "sparameter";
        elseif ~isempty(nvp.Impulse)
            source = "impulse";
        else
            source = "loss";
        end
    end

    if isfield(workspace, 'channel') && (source == "" || source == workspace.channel.source)
        channel = workspace.channel;
    else
        channel = struct();
    end
    channel.source = source;

    switch source
        case "loss"
            loss = nvp.Loss;
            if isempty(loss)
                if isfield(channel, 'ChannelLossdB')
                    loss = channel.ChannelLossdB;
                else
                    cfg = struct();
                    if isfile("config.json")
                        cfg = jsondecode(fileread("config.json"));
                    end
                    if isfield(cfg, 'ChannelLossdB')
                        loss = cfg.ChannelLossdB;
                    end
                end
            end
            if isempty(loss)
                loss = 8;
            end

            % Frequency: preserve existing, else Nyquist
            freq = nvp.Frequency;
            if isempty(freq)
                if isfield(channel, 'ChannelLossFreq')
                    freq = channel.ChannelLossFreq;
                else
                    freq = sysCfg.nyquistFreq;
                end
            end

            channel.ChannelLossdB = loss;
            channel.ChannelLossFreq = freq;
            if ~isempty(nvp.Impedance)
                channel.ChannelDifferentialImpedance = nvp.Impedance;
            elseif ~isfield(channel, 'ChannelDifferentialImpedance')
                channel.ChannelDifferentialImpedance = 100;
            end
            channel.EnableCrosstalk = nvp.EnableCrosstalk;
            if nvp.EnableCrosstalk
                spec = nvp.CrosstalkSpecification;
                if spec == "" && (~isempty(nvp.FEXTICN) || ~isempty(nvp.NEXTICN))
                    spec = "Custom";
                end
                channel.CrosstalkSpecification = spec;
                channel.FEXTICN = nvp.FEXTICN;
                channel.NEXTICN = nvp.NEXTICN;
            end

            xtStr = "off";
            if nvp.EnableCrosstalk
                parts = "on";
                if ~isempty(nvp.FEXTICN)
                    parts = parts + sprintf(", FEXT=%.0f mV", nvp.FEXTICN*1e3);
                end
                if ~isempty(nvp.NEXTICN)
                    parts = parts + sprintf(", NEXT=%.0f mV", nvp.NEXTICN*1e3);
                end
                if spec ~= ""
                    parts = parts + sprintf(", Spec=%s", spec);
                end
                xtStr = parts;
            end
            observation = sprintf( ...
                'Channel configured: loss model, %.1f dB @ %.2f GHz, Z=%d ohm, Crosstalk=%s.', ...
                loss, freq/1e9, channel.ChannelDifferentialImpedance, xtStr);

        case "sparameter"
            sFile = nvp.SParameterFile;
            if sFile == ""
                cfg = struct();
                if isfile("config.json")
                    cfg = jsondecode(fileread("config.json"));
                end
                if isfield(cfg, 'SParameterFile')
                    sFile = string(cfg.SParameterFile);
                end
            end
            assert(sFile ~= "", 'configureChannel:missingFile', ...
                'SParameterFile required for S-parameter channel.');

            channel.SParameterFile = sFile;
            if ~isempty(nvp.PortOrder)
                channel.PortOrder = nvp.PortOrder;
            end
            if ~isempty(nvp.StopTime)
                channel.StopTime = nvp.StopTime;
            end

            if isfield(channel, 'PortOrder') && ~isempty(channel.PortOrder)
                observation = sprintf('Channel configured: S-parameter file "%s", PortOrder=[%s].', ...
                    sFile, strtrim(num2str(channel.PortOrder, '%d ')));
            else
                observation = sprintf('Channel configured: S-parameter file "%s".', sFile);
            end

        case "impulse"
            assert(~isempty(nvp.Impulse), 'configureChannel:missingImpulse', ...
                'Impulse vector required for impulse channel.');
            dtVal = nvp.dt;
            if isempty(dtVal)
                dtVal = sysCfg.sampleInterval;
            end

            channel.Impulse = nvp.Impulse(:);
            channel.dt = dtVal;

            observation = sprintf('Channel configured: impulse response, %d samples, dt=%.3e s.', ...
                numel(nvp.Impulse), dtVal);

        otherwise
            error('configureChannel:invalidSource', ...
                'Unknown Source: "%s". Use "loss", "sparameter", or "impulse".', source);
    end

    workspace.channel = channel;

    observation = string(observation);
    if hasSystem
        observation = observation + sprintf(' System: %.2f Gbps PAM%d. Ready for runAnalysis.', ...
            sysCfg.dataRate/1e9, sysCfg.modulation);
    else
        observation = observation + " Ready for createSerdesSystem (if not done) then runAnalysis.";
    end
end
