function [observation, workspace] = inspectSolution(workspace)
%inspectSolution Report detailed metrics for the active solution: feasibility, error, memory, table size, breakpoint counts, data type, and interpolation.
%   Summarizes feasibility, error, memory, table size, breakpoints, data
%   types, and interpolation for workspace.activeSolution.

% Copyright 2026 The MathWorks, Inc.

    arguments
        workspace
    end

    if ~isfield(workspace, "activeSolution") || ~isa(workspace.activeSolution, 'FunctionApproximation.LUTSolution')
        observation = "No solution available. Call solveProblem first.";
        return
    end
    snap = LUTOAgent.internal.solutionSnapshot(workspace.activeSolution);

    lines = [
        sprintf("Solution ID: %d", snap.solutionID)
        "Feasible: " + string(snap.feasible)
        sprintf("MaxError=%g (upper bound %g)", snap.maxError, snap.errorUpperBound)
        sprintf("Memory=%d bytes (%d bits)", snap.memoryBytes, snap.memoryBits)
        sprintf("Table size: %d entries across %d input(s)", snap.tableSize, snap.numInputs)
        "Breakpoints per dim: [" + strtrim(num2str(snap.breakpointsPerDim)) + "]"
        "Table data type: " + snap.tableDataType
        "Interpolation: " + snap.interpolation
        "Even spacing: " + string(snap.evenSpacing)
    ];
    if isfield(snap, "percentReduction")
        lines(end+1) = sprintf("Memory reduction vs original LUT: %.1f%%", snap.percentReduction);
    end
    observation = strjoin(lines, newline);
end
