function [observation, workspace] = measureWaveform(workspace, nvp)
%measureWaveform Measure eye diagram metrics or jitter from a waveform.
%   [OBSERVATION, WORKSPACE] = measureWaveform(WORKSPACE, ...) builds an eye
%   diagram (eyeDiagramSI) or runs jitter decomposition on the equalized
%   waveform stored in workspace.

    arguments (Input)
        workspace struct
        nvp.Type (1,1) string = "eye"  % Measurement type: "eye" or "jitter"
        nvp.Mask (1,1) string = ""     % Compliance mask name (e.g., "CEI-56G-LR")
    end

    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    assert(isfield(workspace, 'waveform') && isfield(workspace.waveform, 'signal'), ...
        'measureWaveform:noWaveform', ...
        'No waveform in workspace. Call equalizeWaveform or runSimulation first.');

    signal = workspace.waveform.signal;
    dt = workspace.waveform.sampleInterval;
    symbolTime = workspace.waveform.symbolTime;
    modulation = workspace.waveform.modulation;

    measType = lower(nvp.Type);

    switch measType
        case "eye"
            eyeObj = eyeDiagramSI;
            eyeObj.SampleInterval = dt;
            eyeObj.SymbolTime = symbolTime;
            eyeObj.Modulation = modulation;
            eyeObj(signal);

            eh = eyeHeight(eyeObj);
            ew = eyeWidth(eyeObj);
            eyeCom = com(eyeObj);

            workspace.eyeMetrics = struct( ...
                'eyeHeight', eh, ...
                'eyeWidth', ew, ...
                'COM', eyeCom, ...
                'modulation', modulation);

            observation = string(sprintf( ...
                'Eye measured: EH=%.1f mV, EW=%.2f ps, COM=%.2f dB (PAM%d).', ...
                eh*1e3, ew*1e12, eyeCom, modulation));

            % Compliance mask check
            if nvp.Mask ~= ""
                try
                    marginVal = margin(eyeObj, nvp.Mask);
                    workspace.eyeMetrics.mask = nvp.Mask;
                    workspace.eyeMetrics.margin = marginVal;
                    if marginVal > 0
                        observation = observation + sprintf(' Mask "%s": PASS (margin=%.2f%%).', nvp.Mask, marginVal);
                    else
                        observation = observation + sprintf(' Mask "%s": FAIL (margin=%.2f%%).', nvp.Mask, marginVal);
                    end
                catch
                    observation = observation + sprintf(' Mask "%s" not recognized. Omit Mask for measurement without compliance check.', nvp.Mask);
                end
            end

        case "jitter"
            jitterResult = jitter(signal, dt, symbolTime);

            workspace.jitterMetrics = struct( ...
                'TJrms', jitterResult.TJrms, ...
                'TJpkpk', jitterResult.TJpkpk, ...
                'RJrms', jitterResult.RJrms, ...
                'DJrms', jitterResult.DJrms, ...
                'DJpkpk', jitterResult.DJpkpk, ...
                'DDJrms', jitterResult.DDJrms, ...
                'DDJpkpk', jitterResult.DDJpkpk, ...
                'DCDpkpk', jitterResult.DCDpkpk, ...
                'ISIrms', jitterResult.ISIrms, ...
                'ISIpkpk', jitterResult.ISIpkpk);

            observation = sprintf( ...
                'Jitter decomposition: TJ=%.2f ps rms (%.2f ps pk-pk), RJ=%.2f ps, DJ=%.2f ps, DDJ=%.2f ps, DCD=%.2f ps pk-pk, ISI=%.2f ps rms.', ...
                jitterResult.TJrms*1e12, jitterResult.TJpkpk*1e12, ...
                jitterResult.RJrms*1e12, jitterResult.DJrms*1e12, ...
                jitterResult.DDJrms*1e12, jitterResult.DCDpkpk*1e12, ...
                jitterResult.ISIrms*1e12);

        otherwise
            observation = sprintf('Unknown Type "%s". Valid: "eye", "jitter".', measType);
    end
end
