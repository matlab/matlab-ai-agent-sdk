function [observation, workspace] = createSerdesSystem(workspace, nvp)
%createSerdesSystem Create a new SerDes system shell with timing and modulation.
%   [OBSERVATION, WORKSPACE] = createSerdesSystem(WORKSPACE, ...) initializes
%   a new system configuration with data rate, modulation, and timing parameters.
%   Does not create Tx/Rx blocks — call setTransmitterArchitecture and
%   setReceiverArchitecture next.

    arguments (Input)
        workspace struct
        nvp.DataRate double = []              % Data (bit) rate in bits/sec, e.g. 112e9 for "112 Gbps". For PAM4 this is 2x the baud rate. Use when the link is given in Gbps / Gb/s / data rate / line rate. Omit and use BaudRate if given in GBaud. Defaults to 28e9 if neither is given.
        nvp.BaudRate double = []              % Symbol (baud) rate in symbols/sec, e.g. 56e9 for "56 GBaud". Use when the link is given in GBaud / baud / symbol rate / GT/s. SymbolTime = 1/BaudRate (independent of modulation). Omit if given as a bit/data rate (use DataRate).
        nvp.Modulation double = []            % Modulation order as integer: 2 for PAM2/NRZ, 4 for PAM4, 8 for PAM8, etc. Omit to default to 2.
        nvp.SamplesPerSymbol double = []      % Oversampling factor per symbol. Valid: 8, 16, 32, 64, 128. Omit to use default (16).
        nvp.BERtarget double = []             % Target bit error rate (e.g., 1e-6)
        nvp.Signaling (1,1) string = "Differential" % "Differential" or "Single-ended"
        nvp.Fresh (1,1) logical = false       % Set true to PURGE all existing Tx/Rx blocks and start from a base system with no equalization. Use when the prompt says "start over"/"purge"/"recreate"/"clean slate"/"new system with no blocks". Default false preserves any existing blocks (only timing/modulation are updated).
    end
    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    cfg = struct();
    if isfile("config.json")
        cfg = jsondecode(fileread("config.json"));
    end

    % Modulation: agent NVP > config fallback
    modulation = nvp.Modulation;
    if isempty(modulation) && isfield(cfg, 'modulation')
        modulation = cfg.modulation;
    end
    if isempty(modulation)
        modulation = 2;
    end

    % Rate resolution: accept either BaudRate (symbol rate) or DataRate (bit rate).
    % SymbolTime = 1/baud; dataRate (bits/sec) = baud * log2(modulation).
    baudRate = nvp.BaudRate;
    if isempty(baudRate) && isfield(cfg, 'BaudRate')
        baudRate = cfg.BaudRate;
    end

    dataRate = nvp.DataRate;
    if isempty(dataRate) && isfield(cfg, 'DataRate')
        dataRate = cfg.DataRate;
    end

    if ~isempty(baudRate)
        % Baud-specified: symbol time is independent of modulation.
        symbolTime = 1 / baudRate;
        derivedDataRate = baudRate * log2(modulation);
        if ~isempty(dataRate) && abs(derivedDataRate - dataRate) > 0.01 * derivedDataRate
            % Both given and inconsistent — BaudRate wins; flag it.
            baudNote = sprintf(' (note: DataRate=%.3g bps ignored; used BaudRate)', dataRate);
        else
            baudNote = "";
        end
        dataRate = derivedDataRate;
    elseif ~isempty(dataRate)
        % Data-rate-specified (existing behavior).
        symbolTime = log2(modulation) / dataRate;
        baudRate = dataRate / log2(modulation);
        baudNote = "";
    else
        % Neither given: default to 28 Gbps bit rate (NRZ default = 28 GBaud).
        dataRate = 28e9;
        symbolTime = log2(modulation) / dataRate;
        baudRate = dataRate / log2(modulation);
        baudNote = "";
    end
    nyquistFreq = 1 / (2 * symbolTime);

    % SamplesPerSymbol: agent NVP > config > default 16
    samplesPerSymbol = nvp.SamplesPerSymbol;
    if isempty(samplesPerSymbol) && isfield(cfg, 'samplesPerSymbol')
        samplesPerSymbol = cfg.samplesPerSymbol;
    end
    if isempty(samplesPerSymbol)
        samplesPerSymbol = 16;
    end

    validSPS = [8 16 32 64 128];
    assert(ismember(samplesPerSymbol, validSPS), 'createSerdesSystem:invalidSPS', ...
        'SamplesPerSymbol must be one of [%s]. Got %g. Omit to use default (16).', ...
        strjoin(string(validSPS), ', '), samplesPerSymbol);

    sampleInterval = symbolTime / samplesPerSymbol;

    % BERtarget: agent NVP > config > default 1e-6
    berTarget = nvp.BERtarget;
    if isempty(berTarget) && isfield(cfg, 'berTarget')
        berTarget = cfg.berTarget;
    end
    if isempty(berTarget)
        berTarget = 1e-6;
    end

    % Store system configuration
    workspace.systemConfig = struct( ...
        'dataRate', dataRate, ...
        'baudRate', baudRate, ...
        'modulation', modulation, ...
        'symbolTime', symbolTime, ...
        'sampleInterval', sampleInterval, ...
        'samplesPerSymbol', samplesPerSymbol, ...
        'nyquistFreq', nyquistFreq, ...
        'berTarget', berTarget, ...
        'signaling', nvp.Signaling);

    % Block accumulators. Default: initialize only if not already set, so
    % calling createSerdesSystem out of order never destroys prior config
    % (see fix #22). Fresh=true is the explicit opt-in to purge back to base.
    priorTx = string.empty;
    priorRx = string.empty;
    if isfield(workspace, 'txBlockTypes'), priorTx = workspace.txBlockTypes; end
    if isfield(workspace, 'rxBlockTypes'), priorRx = workspace.rxBlockTypes; end

    if nvp.Fresh
        workspace.txBlocks = {};
        workspace.txBlockTypes = string.empty;
        workspace.rxBlocks = {};
        workspace.rxBlockTypes = string.empty;
        workspace.txModel = Transmitter('Blocks', {});
        workspace.rxModel = Receiver('Blocks', {});
    else
        if ~isfield(workspace, 'txBlocks')
            workspace.txBlocks = {};
            workspace.txBlockTypes = string.empty;
        end
        if ~isfield(workspace, 'rxBlocks')
            workspace.rxBlocks = {};
            workspace.rxBlockTypes = string.empty;
        end
    end

    % Describe what happened to existing blocks, so the observation never
    % claims a clean "System created" when blocks were actually kept.
    keptAll = [priorTx, priorRx];
    if nvp.Fresh
        if isempty(keptAll)
            blockNote = " Fresh base system: no Tx/Rx blocks.";
        else
            blockNote = sprintf(" Purged %d existing block(s) [%s]; base system now has no Tx/Rx blocks.", ...
                numel(keptAll), strjoin(keptAll, ", "));
        end
    else
        if isempty(keptAll)
            blockNote = "";
        else
            blockNote = sprintf(" Kept existing block(s) [%s] (only timing/modulation updated). Pass Fresh=true to purge to a base system.", ...
                strjoin(keptAll, ", "));
        end
    end

    observation = sprintf( ...
        ['System created: %.2f Gbps / %.2f GBaud PAM%d, SymbolTime=%.2f ps, %d sps, ' ...
        'Nyquist=%.2f GHz, BER=%.0e.%s%s ' ...
        'Next: configureChannel. To add equalization, call configureCTLE/configureFFE/configureDFECDR directly (they create the architecture automatically).'], ...
        dataRate/1e9, baudRate/1e9, modulation, symbolTime*1e12, samplesPerSymbol, ...
        nyquistFreq/1e9, berTarget, baudNote, blockNote);
end
