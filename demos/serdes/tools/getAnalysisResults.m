function [observation, workspace] = getAnalysisResults(workspace, nvp)
%getAnalysisResults Query specific results from the last analysis.
%   [OBSERVATION, WORKSPACE] = getAnalysisResults(WORKSPACE, ...) extracts
%   detailed results: adapted EQ parameters, pulse response, bathtub curves,
%   or full metrics struct.

    arguments (Input)
        workspace struct
        nvp.Query (1,1) string = "metrics" % Query type: "metrics", "adaptedtaps", "adaptedctle", "pulse", "channelimpulse", "bathtub", or "history"
    end

    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    if ~isfield(workspace, 'sys')
        observation = "No analysis results available. Call runAnalysis first.";
        return;
    end

    sys = workspace.sys;
    results = workspace.analysisResults;
    query = lower(nvp.Query);

    switch query
        case "metrics"
            m = workspace.metrics;
            % EH/EW are per-eye vectors (PAM4 -> 3 eyes). Format each element
            % explicitly and comma-join so the model sees discrete per-eye
            % values, not run-together digits. VEC is vertical eye closure in
            % dB (a scalar), not a percentage.
            ehStr = strjoin(compose("%.1f", m.EH(:)'*1e3), ", ");
            ewStr = strjoin(compose("%.2f", m.EW(:)'), ", ");
            nEye = numel(m.EH);
            observation = sprintf( ...
                ['Metrics: COM=%.2f dB, VEC=%.2f dB. %d eye(s) — worst-case minEH=%.1f mV, minEW=%.2f ps. ' ...
                'Per-eye EH=[%s] mV, per-eye EW=[%s] ps.'], ...
                m.COM, m.VEC, nEye, m.minEH*1e3, m.minEW, ehStr, ewStr);

        case "adaptedtaps"
            % DFE adapted taps: outparams is a cell array, each entry has a block-named field
            taps = [];
            if isfield(results, 'outparams') && iscell(results.outparams)
                for k = 1:numel(results.outparams)
                    op = results.outparams{k};
                    if isfield(op, 'DFECDR') && isfield(op.DFECDR, 'TapWeights')
                        taps = op.DFECDR.TapWeights;
                        break;
                    elseif isfield(op, 'DFE') && isfield(op.DFE, 'TapWeights')
                        taps = op.DFE.TapWeights;
                        break;
                    end
                end
            end
            if ~isempty(taps)
                workspace.adaptedDFETaps = taps;
                observation = sprintf('Adapted DFE taps (%d): [%s].', numel(taps), num2str(taps, '%.4f '));
            else
                observation = 'No adapted DFE taps found in results (DFE may not be in adaptive mode).';
            end

        case "adaptedctle"
            cfgSel = [];
            if isfield(results, 'outparams') && iscell(results.outparams)
                for k = 1:numel(results.outparams)
                    op = results.outparams{k};
                    if isfield(op, 'CTLE') && isfield(op.CTLE, 'ConfigSelect')
                        cfgSel = op.CTLE.ConfigSelect;
                        break;
                    end
                end
            end
            if ~isempty(cfgSel)
                workspace.adaptedCTLEConfig = cfgSel;
                observation = sprintf('Adapted CTLE ConfigSelect: %d.', cfgSel);
            else
                observation = 'No adapted CTLE config found in results.';
            end

        case "pulse"
            pulse = results.impulse(:, 2);
            workspace.pulseResponse = pulse;
            workspace.pulseTimeVector = (0:numel(pulse)-1)' * sys.dt;
            observation = sprintf('Pulse response extracted: %d samples, dt=%.3e s, peak=%.4f V. Use plotSerdesResults Type="pulse" to visualize.', ...
                numel(pulse), sys.dt, max(abs(pulse)));

        case "channelimpulse"
            imp = results.impulse(:, 1);
            workspace.channelImpulse = imp;
            observation = sprintf('Channel impulse extracted: %d samples, peak=%.4f V. Use plotSerdesResults Type="impulse" to visualize.', ...
                numel(imp), max(abs(imp)));

        case "bathtub"
            if isfield(sys.Metrics, 'bathtub')
                workspace.bathtub = sys.Metrics.bathtub;
                observation = 'Bathtub curve data extracted. Use plotSerdesResults Type="bathtub" to visualize.';
            else
                observation = 'No bathtub data available in analysis results.';
            end

        case "history"
            if isfield(workspace, 'iterations')
                n = numel(workspace.iterations);
                lines = cell(1, n);
                for i = 1:n
                    m = workspace.iterations{i}.metrics;
                    tag = "";
                    if isfield(workspace.iterations{i}, 'tag')
                        tag = workspace.iterations{i}.tag;
                    end
                    lines{i} = sprintf('  %d [%s]: COM=%.2f, EH=%.4f V, EW=%.1f ps', ...
                        i, tag, m.COM, m.minEH, m.minEW*1e12);
                end
                observation = sprintf('Iteration history (%d runs):\n%s', n, strjoin(lines, '\n'));
            else
                observation = 'No iteration history.';
            end

        otherwise
            observation = sprintf('Unknown query "%s". Valid: metrics, adaptedtaps, adaptedctle, pulse, channelimpulse, bathtub, history.', query);
    end
end
