function [observation, workspace] = compareSolution(workspace)
%compareSolution Plot original vs. approximation and the error profile for the current active solution (shown in the MATLAB UI) and report max/mean absolute error; this samples the full input range and can take seconds to minutes, so call it once as a verification step rather than repeatedly.
%   Opens the comparison/feasibility plots (visible in the MATLAB UI) and
%   returns a numeric summary of the error across the input range.
%
%   Note: the underlying compare() API samples the approximation across the
%   full input range and can be slow (seconds to minutes for large ranges or
%   fine breakpoints). Call it once as a verification step, not repeatedly.

% Copyright 2026 The MathWorks, Inc.

    arguments
        workspace
    end

    if ~isfield(workspace, "activeSolution") || ~isa(workspace.activeSolution, 'FunctionApproximation.LUTSolution')
        observation = "No solution available. Call solveProblem first.";
        return
    end

    fprintf("[LUTO Agent] Comparing original vs. approximation across the input " + ...
        "range. This may take a while.\n");

    try
        data = compare(workspace.activeSolution);
    catch err
        observation = "Comparison failed: " + string(err.message) + " " + ...
            "The active solution may be infeasible or not yet solved.";
        return
    end
    workspace.compareData = data;

    absErr = abs(data.Original - data.Approximate);
    observation = sprintf(...
        "Comparison plotted in MATLAB (original vs. approximation + error). " + ...
        "Sampled %d points over the range. MaxAbsError=%g, MeanAbsError=%g.", ...
        numel(data.Breakpoints), max(absErr), mean(absErr));
end
