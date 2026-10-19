function [observation, workspace] = solveProblem(workspace)
%solveProblem Solve the configured problem and report feasibility, max error against the tolerance bound, memory in bytes, and how many candidate solutions were found; call defineProblem (and optionally configureProblem) first.
%   Runs solve() on workspace.problem, stores the resulting LUTSolution on
%   workspace.solution, and reports feasibility, error, and memory so the
%   agent can decide whether to inspect, reconfigure, or generate output.

% Copyright 2026 The MathWorks, Inc.

    arguments
        workspace
    end

    if ~isfield(workspace, "problem") || ~isa(workspace.problem, 'FunctionApproximation.Problem')
        observation = "No problem defined yet. Call defineProblem first.";
        return
    end

    try
        solution = solve(workspace.problem);
    catch err
        observation = "Solver could not find an approximation with the current " + ...
            "options: " + string(err.message) + " " + ...
            "Consider relaxing AbsTol/RelTol, adding word lengths, " + ...
            "raising MaxMemoryUsage, extending MaxTime, or narrowing the input range, " + ...
            "then call solveProblem again.";
        return
    end

    workspace.solution = solution;
    workspace.activeSolution = solution;   % the candidate inspection acts on
    % A new solve supersedes any earlier generate/replace.
    if isfield(workspace, "approximated"); workspace = rmfield(workspace, "approximated"); end
    if isfield(workspace, "replaced");     workspace = rmfield(workspace, "replaced");     end

    err = getErrorValue(solution);
    memBytes = totalMemoryUsage(solution, 'bytes');
    nFeasible = numel(solution.FeasibleSolutions);
    nAll = numel(solution.AllSolutions);

    lines = [
        "Solve complete."
        "Feasible: " + string(solution.Feasible)
        sprintf("MaxError=%g (upper bound %g)", err.MaxErrorInSolution, err.ErrorUpperBound)
        sprintf("Memory=%d bytes", memBytes)
        sprintf("Candidates: %d feasible of %d explored", nFeasible, nAll)
    ];
    if ~strcmp(string(solution.Feasible), "true")
        lines(end+1) = "No feasible solution met the constraints. " + ...
            "Consider relaxing AbsTol/RelTol, adding word lengths, " + ...
            "raising MaxMemoryUsage, or narrowing the input range, then re-solve.";
    end
    observation = strjoin(lines, newline);
end
