function [observation, workspace] = configureAnalogModel(workspace, nvp)
%configureAnalogModel Configure AnalogModel and JitterAndNoise on Tx or Rx.
%   [OBSERVATION, WORKSPACE] = configureAnalogModel(WORKSPACE, ...) sets the
%   analog characteristics (rise time, parasitic capacitance, termination
%   impedance) and jitter/noise sources for the specified side.

    arguments (Input)
        workspace struct
        nvp.Side (1,1) string = "Tx"              % Side to configure: "Tx" or "Rx"
        nvp.RiseTime double = []            % Rise time in seconds (Tx only). Default=1e-12
        nvp.ParasiticCapacitance double = [] % Parasitic capacitance in Farads (AnalogModel.C). Default=1e-15
        nvp.TerminationImpedance double = [] % Termination impedance in Ohms (AnalogModel.R). Default=50
        nvp.TxRj double = []                % Tx random jitter RMS in seconds
        nvp.TxDj double = []                % Tx deterministic jitter peak-to-peak in seconds
        nvp.TxDCD double = []               % Tx duty cycle distortion in seconds
        nvp.TxSjAmplitude double = []       % Tx sinusoidal jitter amplitude in seconds
        nvp.TxSjFrequency double = []       % Tx sinusoidal jitter frequency in Hz
        nvp.RxRj double = []                % Rx random jitter RMS in seconds
        nvp.RxDj double = []                % Rx deterministic jitter peak-to-peak in seconds
        nvp.RxNoise double = []             % Rx additive Gaussian noise in Vrms
        nvp.RxClockRj double = []           % Rx clock recovery random jitter RMS in seconds
        nvp.RxClockDj double = []           % Rx clock recovery deterministic jitter in seconds
    end
    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    side = upper(nvp.Side);
    assert(ismember(side, ["TX", "RX"]), 'configureAnalogModel:invalidSide', ...
        'Side must be "Tx" or "Rx".');

    analogDesc = {};
    jitterDesc = {};

    if ~isfield(workspace, 'jitterConfig')
        workspace.jitterConfig = struct();
    end

    if side == "TX"
        % Soft-create: if no Tx model, create default [FFE]
        if ~isfield(workspace, 'txModel')
            workspace.txBlocks = {serdes.FFE};
            workspace.txBlocks{1}.Mode = 1;
            workspace.txBlockTypes = "FFE";
            workspace.txModel = Transmitter('Blocks', workspace.txBlocks, ...
                'AnalogModel', AnalogModel('R', 50, 'C', 1e-15));
        elseif isfield(workspace, 'rxModel') && workspace.txModel.AnalogModel == workspace.rxModel.AnalogModel
            % Break shared AnalogModel handle to avoid cross-contamination
            am = workspace.txModel.AnalogModel;
            workspace.txModel = Transmitter('Blocks', workspace.txBlocks, ...
                'RiseTime', workspace.txModel.RiseTime, ...
                'AnalogModel', AnalogModel('R', am.R, 'C', am.C));
        end

        if ~isempty(nvp.RiseTime)
            workspace.txModel.RiseTime = nvp.RiseTime;
            analogDesc{end+1} = sprintf('RiseTime=%.1f ps', nvp.RiseTime*1e12);
        end
        if ~isempty(nvp.ParasiticCapacitance)
            workspace.txModel.AnalogModel.C = nvp.ParasiticCapacitance;
            analogDesc{end+1} = sprintf('C=%.1f fF', nvp.ParasiticCapacitance*1e15);
        end
        if ~isempty(nvp.TerminationImpedance)
            workspace.txModel.AnalogModel.R = nvp.TerminationImpedance;
            analogDesc{end+1} = sprintf('R=%d ohm', nvp.TerminationImpedance);
        end

        % Store Tx jitter for application in runAnalysis
        if ~isempty(nvp.TxRj)
            workspace.jitterConfig.Tx_Rj = nvp.TxRj;
            jitterDesc{end+1} = sprintf('Rj=%.2e s', nvp.TxRj);
        end
        if ~isempty(nvp.TxDj)
            workspace.jitterConfig.Tx_Dj = nvp.TxDj;
            jitterDesc{end+1} = sprintf('Dj=%.2e s', nvp.TxDj);
        end
        if ~isempty(nvp.TxDCD)
            workspace.jitterConfig.Tx_DCD = nvp.TxDCD;
            jitterDesc{end+1} = sprintf('DCD=%.2e s', nvp.TxDCD);
        end
        if ~isempty(nvp.TxSjAmplitude)
            workspace.jitterConfig.Tx_Sj = nvp.TxSjAmplitude;
            jitterDesc{end+1} = sprintf('SjA=%.2e s', nvp.TxSjAmplitude);
        end
        if ~isempty(nvp.TxSjFrequency)
            workspace.jitterConfig.Tx_Sj_Frequency = nvp.TxSjFrequency;
            jitterDesc{end+1} = sprintf('SjF=%.2e Hz', nvp.TxSjFrequency);
        end

    else  % RX
        % Soft-create: if no Rx model, create default [CTLE, DFECDR]
        if ~isfield(workspace, 'rxModel')
            workspace.rxBlocks = {serdes.CTLE, serdes.DFECDR};
            workspace.rxBlocks{2}.Mode = 2;
            workspace.rxBlockTypes = ["CTLE", "DFECDR"];
            workspace.rxModel = Receiver('Blocks', workspace.rxBlocks, ...
                'AnalogModel', AnalogModel('R', 50, 'C', 1e-15));
        elseif isfield(workspace, 'txModel') && workspace.rxModel.AnalogModel == workspace.txModel.AnalogModel
            % Break shared AnalogModel handle to avoid cross-contamination
            am = workspace.rxModel.AnalogModel;
            workspace.rxModel = Receiver('Blocks', workspace.rxBlocks, ...
                'AnalogModel', AnalogModel('R', am.R, 'C', am.C));
        end

        if ~isempty(nvp.RiseTime)
            observation = "Warning: Receiver has no RiseTime property. Ignored.";
            return
        end
        if ~isempty(nvp.ParasiticCapacitance)
            workspace.rxModel.AnalogModel.C = nvp.ParasiticCapacitance;
            analogDesc{end+1} = sprintf('C=%.1f fF', nvp.ParasiticCapacitance*1e15);
        end
        if ~isempty(nvp.TerminationImpedance)
            workspace.rxModel.AnalogModel.R = nvp.TerminationImpedance;
            analogDesc{end+1} = sprintf('R=%d ohm', nvp.TerminationImpedance);
        end

        % Store Rx jitter for application in runAnalysis
        if ~isempty(nvp.RxRj)
            workspace.jitterConfig.Rx_Rj = nvp.RxRj;
            jitterDesc{end+1} = sprintf('RxRj=%.2e s', nvp.RxRj);
        end
        if ~isempty(nvp.RxDj)
            workspace.jitterConfig.Rx_Dj = nvp.RxDj;
            jitterDesc{end+1} = sprintf('RxDj=%.2e s', nvp.RxDj);
        end
        if ~isempty(nvp.RxNoise)
            workspace.jitterConfig.Rx_GaussianNoise = nvp.RxNoise;
            jitterDesc{end+1} = sprintf('RxNoise=%.2e V', nvp.RxNoise);
        end
        if ~isempty(nvp.RxClockRj)
            workspace.jitterConfig.Rx_Clock_Recovery_Rj = nvp.RxClockRj;
            jitterDesc{end+1} = sprintf('RxClkRj=%.2e s', nvp.RxClockRj);
        end
        if ~isempty(nvp.RxClockDj)
            workspace.jitterConfig.Rx_Clock_Recovery_Dj = nvp.RxClockDj;
            jitterDesc{end+1} = sprintf('RxClkDj=%.2e s', nvp.RxClockDj);
        end
    end

    parts = [analogDesc, jitterDesc];
    if isempty(parts)
        observation = sprintf('%s analog model: no changes (all defaults). Ready for runAnalysis.', side);
    else
        observation = sprintf('%s analog model configured: %s. Ready for runAnalysis.', side, strjoin(parts, ', '));
    end
end
