function [observation, workspace] = plotSweepResults(workspace, nvp)
%plotSweepResults Plot metrics across sweep iterations or configurations.
%   [OBSERVATION, WORKSPACE] = plotSweepResults(WORKSPACE, ...) creates bar,
%   line, heatmap, or Pareto plots from iteration history or comparison results.

    arguments (Input)
        workspace struct
        nvp.PlotStyle (1,1) string = "bar"        % Plot style: "bar", "line", "stem", "heatmap" (for 2D sweep data), "impulse" (overlay impulse responses), or "stacked" (vertically stacked subplots, one per metric in Metrics)
        nvp.Metric (1,1) string = "COM"           % Metric name to plot: "COM", "EH", "EW", or "VEC"
        nvp.Metrics (1,1) string = ""             % Comma-separated metric names for stacked plot (e.g., "COM,EH,EW"). Overrides Metric when PlotStyle="stacked".
        nvp.XLabels (1,:) string = string.empty   % String array of x-axis tick labels
        nvp.XAxisLabel (1,1) string = ""          % X-axis label string (e.g., "Configuration")
        nvp.YAxisLabel (1,1) string = ""          % Y-axis label string (e.g., "COM (dB)")
        nvp.Title (1,1) string = ""               % Plot title string
        nvp.ReferenceLine (1,1) string = ""       % Reference line spec: "MetricName=value" (e.g., "COM=3"). Draws horizontal line on matching subplot.
        nvp.OutputFile (1,1) string = ""          % Output PNG file path (auto-generated if omitted)
    end

    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    % Auto-switch to impulse overlay if Metric suggests impulse intent
    if ismember(lower(nvp.Metric), ["impulse", "impulseresponse", "channelimpulseresponse"])
        nvp.PlotStyle = "impulse";
    end

    % Gather data from sweep, iterations, or comparison
    if isfield(workspace, 'sweep') && ~isempty(workspace.sweep)
        sw = workspace.sweep;
        metricField = char(nvp.Metric);
        if isfield(sw, metricField)
            values = sw.(metricField);
        else
            values = sw.COM;
            metricField = 'COM';
        end

        % 2D sweep: render heatmap and return early
        is2D = isfield(sw, 'parameter2') && ~isempty(sw.parameter2) && ismatrix(values) && min(size(values)) > 1;
        if is2D
            fig = figure('Position', [100 100 800 600]);
            imagesc(sw.values2, sw.values, values);
            set(gca, 'YDir', 'normal');
            colorbar;
            colormap(parula);
            xlabel(sw.parameter2);
            ylabel(sw.parameter);
            if nvp.XAxisLabel ~= "", xlabel(nvp.XAxisLabel); end
            if nvp.YAxisLabel ~= "", ylabel(nvp.YAxisLabel); end
            titleStr = nvp.Title;
            if titleStr == ""
                titleStr = sprintf('%s: %s vs %s', nvp.Metric, sw.parameter, sw.parameter2);
            end
            title(titleStr);

            outFile = nvp.OutputFile;
            if outFile == ""
                outFile = string(fullfile(tempdir, sprintf('serdes_heatmap_%s.png', datestr(now, 'HHMMSS'))));
            end
            exportgraphics(fig, char(outFile), 'Resolution', 300);

            if ~isfield(workspace, 'plots')
                workspace.plots = {};
            end
            workspace.plots{end+1} = struct('type', 'heatmap', 'metric', nvp.Metric, 'file', outFile);

            [bestVal, bestLinIdx] = max(values(:));
            [bestI, bestJ] = ind2sub(size(values), bestLinIdx);
            observation = sprintf('Heatmap saved: %s. %s range [%.2f, %.2f]. Best=%.2f at %s=%.4g, %s=%.4g.', ...
                outFile, nvp.Metric, min(values(:)), max(values(:)), bestVal, ...
                sw.parameter, sw.values(bestI), sw.parameter2, sw.values2(bestJ));
            return;
        end

        % Impulse overlay: plot all stored impulse responses on one axes
        if lower(nvp.PlotStyle) == "impulse"
            if ~isfield(sw, 'impulses') || isempty(sw.impulses)
                observation = 'No impulse data stored in sweep. Re-run sweepParameter to collect impulse responses.';
                return;
            end
            fig = figure('Position', [100 100 800 600]);
            hold on;
            labels = string.empty;
            for k = 1:numel(sw.impulses)
                imp = sw.impulses{k};
                t = (0:length(imp.response)-1) * imp.dt * 1e9;
                plot(t, imp.response, 'LineWidth', 1.2);
                labels(k) = sprintf('%s = %g', sw.parameter, sw.values(k));
            end
            hold off;
            legend(labels, 'Location', 'best');
            xlabel('Time (ns)');
            ylabel('Impulse Response');
            titleStr = nvp.Title;
            if titleStr == ""
                titleStr = sprintf('Channel Impulse Response: %s Sweep', sw.parameter);
            end
            title(titleStr);
            grid on;

            outFile = nvp.OutputFile;
            if outFile == ""
                outFile = string(fullfile(tempdir, sprintf('serdes_impulse_%s.png', datestr(now, 'HHMMSS'))));
            end
            exportgraphics(fig, char(outFile), 'Resolution', 300);

            if ~isfield(workspace, 'plots')
                workspace.plots = {};
            end
            workspace.plots{end+1} = struct('type', 'impulse_overlay', 'metric', 'impulse', 'file', outFile);

            observation = sprintf('Impulse response overlay saved: %s. %d traces plotted for %s = [%s].', ...
                outFile, numel(sw.impulses), sw.parameter, strjoin(string(sw.values), ', '));
            return;
        end

        % Stacked subplots: one per metric, shared x-axis
        if lower(nvp.PlotStyle) == "stacked"
            metricsStr = nvp.Metrics;
            if metricsStr == ""
                metricsStr = nvp.Metric;
            end
            metricList = strtrim(split(metricsStr, ","));
            nMetrics = numel(metricList);
            unitMap = struct('COM','dB','EH','mV','EW','ps','VEC','dB');

            fig = figure('Position', [100 100 800 200*nMetrics]);
            xVals = sw.values;

            % Parse reference line: "COM=3" or just "3" (applies to first metric)
            refMetric = ""; refVal = NaN;
            if nvp.ReferenceLine ~= ""
                parts = split(nvp.ReferenceLine, "=");
                if numel(parts) == 2
                    refMetric = upper(strtrim(parts(1)));
                    refVal = str2double(parts(2));
                elseif numel(parts) == 1
                    refVal = str2double(parts(1));
                    if ~isnan(refVal)
                        refMetric = upper(strtrim(metricList(1)));
                    end
                end
            end

            for mi = 1:nMetrics
                mName = upper(strtrim(metricList(mi)));
                ax = subplot(nMetrics, 1, mi);
                if isfield(sw, char(mName))
                    yData = sw.(char(mName));
                else
                    yData = zeros(size(xVals));
                end
                % Unit conversion for display
                if mName == "EH"
                    yData = yData * 1e3;
                end
                plot(ax, xVals, yData, '-o', 'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerFaceColor', 'auto');
                hold(ax, 'on');
                if mName == refMetric && ~isnan(refVal)
                    yline(ax, refVal, '--r', sprintf('%s = %g', refMetric, refVal), 'LineWidth', 1.2);
                end
                hold(ax, 'off');
                grid(ax, 'on');
                unitStr = "";
                if isfield(unitMap, char(mName))
                    unitStr = " (" + string(unitMap.(char(mName))) + ")";
                end
                ylabel(ax, mName + unitStr);
                if mi < nMetrics
                    set(ax, 'XTickLabel', []);
                else
                    if nvp.XAxisLabel ~= ""
                        xlabel(ax, nvp.XAxisLabel);
                    else
                        xlabel(ax, sw.parameter);
                    end
                end
            end
            if nvp.Title ~= ""
                sgtitle(nvp.Title);
            else
                sgtitle(sprintf('%s vs %s', strjoin(metricList, ', '), sw.parameter));
            end
            linkaxes(findall(fig, 'Type', 'axes'), 'x');

            outFile = nvp.OutputFile;
            if outFile == ""
                outFile = string(fullfile(tempdir, sprintf('serdes_stacked_%s.png', datestr(now, 'HHMMSS'))));
            end
            exportgraphics(fig, char(outFile), 'Resolution', 300);

            if ~isfield(workspace, 'plots')
                workspace.plots = {};
            end
            workspace.plots{end+1} = struct('type', 'stacked', 'metrics', strjoin(metricList, ','), 'file', outFile);

            observation = string(sprintf('Stacked plot saved: %s. Metrics: %s vs %s (%d points).', ...
                outFile, strjoin(metricList, ', '), sw.parameter, numel(xVals)));
            if refMetric ~= ""
                observation = observation + string(sprintf(' Reference line: %s = %g.', refMetric, refVal));
            end
            return;
        end

        if ~isempty(nvp.XLabels) && numel(nvp.XLabels) == numel(values)
            xLabels = nvp.XLabels;
        else
            xLabels = string(sw.values);
        end
    elseif isfield(workspace, 'comparison') && ~isempty(workspace.comparison)
        names = [workspace.comparison.name];
        metricField = char(nvp.Metric);
        if isfield(workspace.comparison, metricField)
            values = [workspace.comparison.(metricField)];
        else
            values = [workspace.comparison.COM];
            metricField = 'COM';
        end
        xLabels = names;
    elseif isfield(workspace, 'iterations') && ~isempty(workspace.iterations)
        n = numel(workspace.iterations);
        values = zeros(1, n);
        metricField = char(nvp.Metric);
        for i = 1:n
            m = workspace.iterations{i}.metrics;
            if isfield(m, metricField)
                val = m.(metricField);
                values(i) = val(1);
            end
        end
        if ~isempty(nvp.XLabels) && numel(nvp.XLabels) == n
            xLabels = nvp.XLabels;
        else
            xLabels = "Iter " + string(1:n);
            for i = 1:n
                if isfield(workspace.iterations{i}, 'tag') && workspace.iterations{i}.tag ~= ""
                    xLabels(i) = workspace.iterations{i}.tag;
                end
            end
        end
    else
        observation = 'No sweep data. Run sweepParameter, compareConfigurations, or multiple runAnalysis calls first.';
        return
    end

    fig = figure('Position', [100 100 800 500]);

    switch lower(nvp.PlotStyle)
        case "bar"
            bar(values, 'LineWidth', 1);
            ax = gca;
            ax.XTick = 1:numel(values);
            ax.XTickLabel = xLabels;
            ax.XTickLabelRotation = 45;
            hold on;
            plot(1:numel(values), values, 'k.', 'MarkerSize', 12);
            hold off;

        case "line"
            plot(values, '-o', 'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', 'auto');
            ax = gca;
            ax.XTick = 1:numel(values);
            ax.XTickLabel = xLabels;

        case "stem"
            stem(values, 'filled', 'LineWidth', 1.5, 'MarkerSize', 8);
            ax = gca;
            ax.XTick = 1:numel(values);
            ax.XTickLabel = xLabels;

        otherwise
            bar(values, 'LineWidth', 1);
            ax = gca;
            ax.XTick = 1:numel(values);
            ax.XTickLabel = xLabels;
            hold on;
            plot(1:numel(values), values, 'k.', 'MarkerSize', 12);
            hold off;
    end

    % Labels
    titleStr = nvp.Title;
    if titleStr == ""
        titleStr = sprintf('%s Comparison', nvp.Metric);
    end
    title(titleStr);

    xLabel = nvp.XAxisLabel;
    if xLabel ~= "", xlabel(xLabel); end

    yLabel = nvp.YAxisLabel;
    if yLabel == ""
        yLabel = nvp.Metric;
    end
    ylabel(yLabel);
    grid on;

    % Save
    outFile = nvp.OutputFile;
    if outFile == ""
        outFile = string(fullfile(tempdir, sprintf('serdes_sweep_%s.png', datestr(now, 'HHMMSS'))));
    end
    exportgraphics(fig, char(outFile), 'Resolution', 300);

    if ~isfield(workspace, 'plots')
        workspace.plots = {};
    end
    workspace.plots{end+1} = struct('type', 'sweep', 'metric', nvp.Metric, 'file', outFile);

    [bestVal, bestIdx] = max(values);
    observation = sprintf('Sweep plot saved: %s. %s range: [%.2f, %.2f], best=%.2f at "%s".', ...
        outFile, nvp.Metric, min(values), max(values), bestVal, xLabels(bestIdx));
end
