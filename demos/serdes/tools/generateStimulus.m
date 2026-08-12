function [observation, workspace] = generateStimulus(workspace, nvp)
%generateStimulus Generate a PRBS or PAM-N stimulus waveform.
%   [OBSERVATION, WORKSPACE] = generateStimulus(WORKSPACE, ...) creates a
%   time-domain stimulus signal for equalization or simulation workflows.

    arguments (Input)
        workspace struct
        nvp.PRBSOrder (1,1) double = 10        % PRBS polynomial order: 7, 10, 15, 23, or 31
        nvp.NumSymbols double = []       % Number of symbols to generate (defaults to 2^PRBSOrder-1)
        nvp.Modulation (1,1) string = ""  % PAM order: "2" or "NRZ" for NRZ/PAM2, "4" or "PAM4" for PAM4, "8" or "PAM8" for PAM8
        nvp.SamplesPerSymbol double = [] % Samples per unit interval (e.g., 16)
        nvp.Amplitude (1,1) double = 0.5       % Peak signal amplitude in Volts
        nvp.Source (1,1) string = "rectangular" % Source: "rectangular" (ideal NRZ/PAM) or "pulseResponse" (convolve with equalized pulse)
    end

    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    assert(isfield(workspace, 'systemConfig'), 'generateStimulus:noSystem', ...
        'Call createSerdesSystem first.');

    sysCfg = workspace.systemConfig;

    modStr = upper(strtrim(nvp.Modulation));
    if modStr == "" || modStr == "[]" || startsWith(modStr, "PRBS")
        modulation = sysCfg.modulation;
    elseif modStr == "NRZ" || modStr == "PAM2" || modStr == "2"
        modulation = 2;
    elseif startsWith(modStr, "PAM")
        modulation = str2double(extractAfter(modStr, "PAM"));
    else
        modVal = str2double(modStr);
        if isnan(modVal)
            observation = "Error: Modulation must be a PAM order (2=NRZ, 4=PAM4, 8=PAM8). Got: " + nvp.Modulation;
            return
        end
        modulation = modVal;
    end

    sps = nvp.SamplesPerSymbol;
    if isempty(sps)
        sps = sysCfg.samplesPerSymbol;
    end

    numSymbols = nvp.NumSymbols;
    if isempty(numSymbols)
        numSymbols = 2^nvp.PRBSOrder - 1;
    end

    % Generate PRBS bit sequence
    prbsBits = generatePRBS(nvp.PRBSOrder, numSymbols);

    % Map to PAM-N levels
    if modulation == 2
        % NRZ: bits -> +/-Amplitude
        symbols = 2 * prbsBits - 1;
    else
        % PAM-N: group bits into symbols
        bitsPerSymbol = log2(modulation);
        nSymPAM = floor(numel(prbsBits) / bitsPerSymbol);
        prbsBits = prbsBits(1:nSymPAM * bitsPerSymbol);
        bitGroups = reshape(prbsBits, bitsPerSymbol, [])';
        symbolIdx = bitGroups * (2.^((bitsPerSymbol-1):-1:0))';
        symbols = (2 * symbolIdx / (modulation - 1) - 1);
        numSymbols = nSymPAM;
    end

    symbols = symbols(:) * nvp.Amplitude;

    dt = sysCfg.sampleInterval;

    source = lower(nvp.Source);
    if contains(source, "pulse")
        source = "pulseresponse";
    end

    if source == "pulseresponse"
        assert(isfield(workspace, 'analysisResults') && isfield(workspace.analysisResults, 'pulse'), ...
            'generateStimulus:noPulse', 'No equalized pulse response. Call runAnalysis first.');
        eqPulse = workspace.analysisResults.pulse(:, 2);
        % Upsample symbol sequence to sample rate, then convolve with pulse
        symbolsUp = upsample(symbols, sps);
        waveform = conv(symbolsUp, eqPulse);
        waveform = waveform(1:numel(symbolsUp));
    else
        % Rectangular (ideal) symbols upsampled
        waveform = repelem(symbols, sps);
    end

    timeVec = (0:numel(waveform)-1)' * dt;

    % Store as workspace waveform (same struct as loadWaveform)
    workspace.waveform = struct( ...
        'signal', waveform, ...
        'time', timeVec, ...
        'sampleInterval', dt, ...
        'symbolTime', sysCfg.symbolTime, ...
        'samplesPerSymbol', sps, ...
        'modulation', modulation, ...
        'sourceFile', "generated", ...
        'numSamples', numel(waveform), ...
        'numSymbols', numSymbols, ...
        'prbsOrder', nvp.PRBSOrder);

    observation = sprintf( ...
        'Stimulus generated: PRBS-%d, %d symbols, PAM%d, %d samples, Amplitude=%.2f V, dt=%.3e s. Ready for equalizeWaveform or configureChannel with impulse source.', ...
        nvp.PRBSOrder, numSymbols, modulation, numel(waveform), nvp.Amplitude, dt);
end

function bits = generatePRBS(order, numBits)
    % Generate PRBS sequence using linear feedback shift register
    % Standard polynomials for common orders
    taps = getPRBSTaps(order);
    reg = ones(1, order);
    bits = zeros(1, numBits);
    for i = 1:numBits
        bits(i) = reg(end);
        feedback = mod(sum(reg(taps)), 2);
        reg = [feedback, reg(1:end-1)];
    end
end

function taps = getPRBSTaps(order)
    switch order
        case 7,  taps = [6, 7];
        case 9,  taps = [5, 9];
        case 10, taps = [7, 10];
        case 11, taps = [9, 11];
        case 13, taps = [12, 13];
        case 15, taps = [14, 15];
        case 23, taps = [18, 23];
        case 31, taps = [28, 31];
        otherwise, taps = [order-1, order];
    end
end
