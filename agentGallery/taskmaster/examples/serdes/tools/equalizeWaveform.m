function [observation, workspace] = equalizeWaveform(workspace, nvp)
%equalizeWaveform Run the system objects chain on a waveform (time-domain, sample-by-sample).
%   [OBSERVATION, WORKSPACE] = equalizeWaveform(WORKSPACE, ...) applies the
%   configured equalization blocks to the loaded waveform in sample mode.
%   This is the time-domain simulation path using SerDes system objects.
%   FFE and CTLE accept full vectors; DFECDR/DFE process sample-by-sample
%   with adaptive tap weights and CDR phase tracking.

    arguments (Input)
        workspace struct
        nvp.PreloadDFETaps (1,:) double = [] % Initial DFE tap weights vector, e.g. [0.1 0.05 0.02]
        nvp.DFEMode double = []        % DFE operating mode: 0=fixed, 1=initial adapted, 2=adaptive
        nvp.EqualizationGain double = [] % Linear gain multiplier applied before DFE (unitless)
    end

    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    assert(isfield(workspace, 'waveform') && isfield(workspace.waveform, 'signal'), ...
        'equalizeWaveform:noWaveform', 'Call loadWaveform or generateStimulus first.');

    % Soft-create: if no Rx architecture, create default [CTLE, DFECDR]
    if ~isfield(workspace, 'rxBlocks') || isempty(workspace.rxBlocks)
        workspace.rxBlocks = {serdes.CTLE, serdes.DFECDR};
        workspace.rxBlocks{2}.Mode = 2;
        workspace.rxBlockTypes = ["CTLE", "DFECDR"];
        workspace.rxModel = Receiver('Blocks', workspace.rxBlocks);
    end

    signal = workspace.waveform.signal(:);
    dt = workspace.waveform.sampleInterval;
    symbolTime = workspace.waveform.symbolTime;
    modulation = workspace.waveform.modulation;

    % Process through each Rx block in order
    eqSignal = signal;
    blockDescs = {};

    sps = workspace.waveform.samplesPerSymbol;

    for i = 1:numel(workspace.rxBlocks)
        obj = workspace.rxBlocks{i};
        blockType = workspace.rxBlockTypes(i);

        % Release locked objects before setting properties
        if isLocked(obj), release(obj); end

        % Set timing on block
        if isprop(obj, 'SymbolTime'), obj.SymbolTime = symbolTime; end
        if isprop(obj, 'SampleInterval'), obj.SampleInterval = dt; end
        if isprop(obj, 'WaveType'), obj.WaveType = "Sample"; end
        if isprop(obj, 'Modulation') && blockType ~= "CTLE"
            obj.Modulation = modulation;
        end

        switch upper(blockType)
            case "FFE"
                % FFE accepts full vector in Sample mode
                eqSignal = obj(eqSignal);
                blockDescs{end+1} = sprintf('FFE(%d taps)', numel(obj.TapWeights));

            case "CTLE"
                % CTLE accepts full vector
                eqSignal = obj(eqSignal);
                blockDescs{end+1} = sprintf('CTLE(ACGain=%.1f)', obj.ACGain);

            case {"DFECDR", "DFE"}
                % Override DFE settings if requested
                if ~isempty(nvp.PreloadDFETaps)
                    obj.TapWeights = nvp.PreloadDFETaps(:)';
                    obj.Mode = 1;
                end
                if ~isempty(nvp.DFEMode)
                    obj.Mode = nvp.DFEMode;
                end
                if ~isempty(nvp.EqualizationGain)
                    obj.EqualizationGain = nvp.EqualizationGain;
                end

                % Sample-by-sample loop with tap history capture
                nSamp = numel(eqSignal);
                nTaps = numel(obj.TapWeights);
                out = zeros(size(eqSignal));
                adaptedTaps = obj.TapWeights;
                numSym = floor(nSamp / sps);
                tapHistory = zeros(numSym, nTaps);
                symIdx = 0;
                for k = 1:nSamp
                    [out(k), adaptedTaps] = obj(eqSignal(k));
                    if mod(k, sps) == 0
                        symIdx = symIdx + 1;
                        tapHistory(symIdx, :) = adaptedTaps;
                    end
                end
                eqSignal = out;
                workspace.waveform.adaptedDFETaps = adaptedTaps;
                workspace.waveform.tapHistory = tapHistory(1:symIdx, :);
                blockDescs{end+1} = sprintf('%s(%d taps, Mode=%d)', blockType, numel(obj.TapWeights), obj.Mode);

            case "VGA"
                eqSignal = obj(eqSignal);
                blockDescs{end+1} = sprintf('VGA(Gain=%.2f)', obj.Gain);

            case "AGC"
                for k = 1:numel(eqSignal)
                    eqSignal(k) = obj(eqSignal(k));
                end
                blockDescs{end+1} = 'AGC';

            otherwise
                eqSignal = obj(eqSignal);
                blockDescs{end+1} = char(blockType);
        end
    end

    % Store equalized waveform
    workspace.waveform.signal = eqSignal;
    workspace.waveform.eqChain = strjoin(blockDescs, ' -> ');

    peakV = max(abs(eqSignal));
    tapMsg = "";
    if isfield(workspace.waveform, 'tapHistory')
        th = workspace.waveform.tapHistory;
        tapMsg = sprintf(' DFE tap history: %d symbols x %d taps captured. Use plotSerdesResults Type="adaptation" to visualize.', size(th,1), size(th,2));
    end
    observation = sprintf( ...
        'Waveform equalized: [%s]. Output: %d samples, peak=%.1f mV.%s Ready for measureWaveform.', ...
        strjoin(blockDescs, ' -> '), numel(eqSignal), peakV*1e3, tapMsg);
end
