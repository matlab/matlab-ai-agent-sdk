function [observation, workspace] = plotSerdesResults(workspace, nvp)
%plotSerdesResults Render a SerDes visualization and save to file.
%   [OBSERVATION, WORKSPACE] = plotSerdesResults(WORKSPACE, ...) creates plots
%   of eye diagrams, pulse responses, impulse responses, waveforms, bathtub
%   curves, or frequency responses. Output appears in MATLAB and is saved to PNG.

    arguments (Input)
        workspace struct
        nvp.Type (1,1) string = "eye"             % Plot type: "eye", "pulse", "impulse", "alignedpulse", "waveform", "frequency", or "bathtub"
        nvp.Title (1,1) string = ""               % Custom title string for the plot axis
        nvp.Colormap (1,1) string = "si"          % Colormap name: "si", "parula", or "jet"
        nvp.OutputFile (1,1) string = ""          % Output PNG file path (auto-generated if omitted)
        nvp.NumSymbols double = []               % For waveform plots: show only first N symbols (default: all)
        nvp.Display (1,1) logical = true          % Show the figure in a MATLAB window (default true). Set false for headless/batch runs that only need the saved PNG.
    end

    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    plotType = lower(nvp.Type);
    if contains(plotType, "eye") || contains(plotType, "stat")
        plotType = "eye";
    end

    % Render on-screen when Display=true so the user actually sees the plot;
    % render off-screen for headless/batch runs (PNG only).
    if nvp.Display
        figVisible = 'on';
    else
        figVisible = 'off';
    end
    fig = figure('Visible', figVisible, 'Position', [100 100 800 600]);

    switch plotType
        case "eye"
            assert(isfield(workspace, 'sys'), 'plotSerdesResults:noSystem', ...
                'No analyzed system. Call runAnalysis first.');
            plotStatEye(workspace.sys);
            defaultTitle = "Statistical Eye Diagram";

        case "pulse"
            assert(isfield(workspace, 'sys'), 'plotSerdesResults:noSystem', ...
                'No analyzed system. Call runAnalysis first.');
            plotPulse(workspace.sys);
            defaultTitle = "Pulse Response";

        case "impulse"
            assert(isfield(workspace, 'sys'), 'plotSerdesResults:noSystem', ...
                'No analyzed system. Call runAnalysis first.');
            plotImpulse(workspace.sys);
            defaultTitle = "Channel Impulse Response";

        case "alignedpulse"
            assert(isfield(workspace, 'sys'), 'plotSerdesResults:noSystem', ...
                'No analyzed system. Call runAnalysis first.');
            plotAlignedPulse(workspace.sys);
            defaultTitle = "Aligned Pulse Response";

        case "waveform"
            assert(isfield(workspace, 'waveform'), 'plotSerdesResults:noWaveform', ...
                'No waveform. Call loadWaveform or generateStimulus first.');
            signal = workspace.waveform.signal;
            time = workspace.waveform.time;
            if ~isempty(nvp.NumSymbols)
                sps = workspace.waveform.samplesPerSymbol;
                nSamples = min(nvp.NumSymbols * sps, numel(signal));
                signal = signal(1:nSamples);
                time = time(1:nSamples);
            end
            plot(time * 1e9, signal * 1e3);
            xlabel('Time (ns)');
            ylabel('Voltage (mV)');
            defaultTitle = "Time-Domain Waveform";

        case "frequency"
            if isfield(workspace, 'sparam')
                if isfield(workspace.sparam, 'insertionLoss')
                    freq = workspace.sparam.insertionLossFreq;
                    il = workspace.sparam.insertionLoss;
                    plot(freq/1e9, il, 'LineWidth', 1.5);
                    xlabel('Frequency (GHz)');
                    ylabel('Magnitude (dB)');
                    defaultTitle = "Insertion Loss";
                elseif isfield(workspace.sparam, 'returnLoss')
                    freq = workspace.sparam.returnLossFreq;
                    rl = workspace.sparam.returnLoss;
                    plot(freq/1e9, rl, 'LineWidth', 1.5);
                    xlabel('Frequency (GHz)');
                    ylabel('Magnitude (dB)');
                    defaultTitle = "Return Loss";
                end
            elseif isfield(workspace, 'rxBlockTypes') && any(workspace.rxBlockTypes == "CTLE")
                idx = find(workspace.rxBlockTypes == "CTLE", 1);
                ctleObj = workspace.rxBlocks{idx};
                [f, H] = response(ctleObj);
                plot(f/1e9, 20*log10(abs(H)), 'LineWidth', 1.5);
                xlabel('Frequency (GHz)');
                ylabel('Magnitude (dB)');
                defaultTitle = "CTLE Frequency Response";
            else
                close(fig);
                observation = "No frequency data available. Load S-parameters (loadSParameters) or configure a CTLE (configureCTLE) first.";
                return
            end

        case "bathtub"
            assert(isfield(workspace, 'sys') && isfield(workspace.sys.Metrics, 'bathtub'), ...
                'plotSerdesResults:noBathtub', 'No bathtub data available.');
            bathtub = workspace.sys.Metrics.bathtub;
            semilogy(bathtub.timing, bathtub.BER);
            xlabel('Timing Offset (UI)');
            ylabel('BER');
            defaultTitle = "Bathtub Curve";

        case "adaptation"
            if ~isfield(workspace, 'waveform') || ~isfield(workspace.waveform, 'tapHistory')
                close(fig);
                observation = "No tap adaptation data. Call equalizeWaveform first (DFE/DFECDR must be in adaptive mode).";
                return
            end
            th = workspace.waveform.tapHistory;
            nTaps = size(th, 2);
            nSym = size(th, 1);
            plot(1:nSym, th);
            xlabel('Symbol');
            ylabel('Tap Weight (V)');
            legEntries = arrayfun(@(i) sprintf('Tap %d', i), 1:nTaps, 'UniformOutput', false);
            legend(legEntries, 'Location', 'best');
            defaultTitle = "DFE Tap Adaptation";

        otherwise
            close(fig);
            observation = sprintf('Unknown Type "%s". Valid: eye, pulse, impulse, alignedpulse, waveform, frequency, bathtub, adaptation.', plotType);
            return
    end

    % Apply colormap for eye plots
    if plotType == "eye"
        cmapLower = lower(nvp.Colormap);
        if contains(cmapLower, "si") || contains(cmapLower, "signal")
            colormap(serdes.utilities.SignalIntegrityColorMap);
        else
            colormap(nvp.Colormap);
        end
        colorbar;
    end

    % Title
    if nvp.Title ~= ""
        title(nvp.Title);
    else
        title(defaultTitle);
    end
    grid on;

    % Save
    outFile = nvp.OutputFile;
    if outFile == ""
        outFile = string(fullfile(tempdir, sprintf('serdes_%s_%s.png', plotType, datestr(now, 'HHMMSS'))));
    end
    exportgraphics(fig, char(outFile), 'Resolution', 300);
    % Keep the figure open when Display=true so the user can see it; only
    % close it in headless mode (where it was never shown).
    if nvp.Display
        drawnow;
    else
        close(fig);
    end

    if ~isfield(workspace, 'plots')
        workspace.plots = {};
    end
    workspace.plots{end+1} = struct('type', plotType, 'file', outFile);

    if nvp.Display
        visNote = "Figure is open in a MATLAB window";
    else
        visNote = "Rendered headless (no window)";
    end
    observation = sprintf('%s plot saved: %s. %s.', defaultTitle, outFile, visNote);
end
