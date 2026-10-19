function [observation, workspace] = selectSolution(workspace, solutionID)
%selectSolution Make a specific candidate active by its numeric solutionID from listSolutions; subsequent inspect, compare, generate, and replace calls then act on that candidate.
%   Subsequent inspect/compare/generate operations act on this candidate.

% Copyright 2026 The MathWorks, Inc.

    arguments
        workspace
        solutionID (1,1) double  % ID from listSolutions.
    end

    if ~isfield(workspace, "solution")
        observation = "No solution available. Call solveProblem first.";
        return
    end

    try
        chosen = solutionFromID(workspace.solution, solutionID);
    catch ME
        observation = sprintf("Could not select solution ID %d: %s", solutionID, ME.message);
        return
    end

    workspace.activeSolution = chosen;
    % Switching the active candidate invalidates prior generate/replace.
    if isfield(workspace, "approximated"); workspace = rmfield(workspace, "approximated"); end
    if isfield(workspace, "replaced");     workspace = rmfield(workspace, "replaced");     end

    err = getErrorValue(chosen);
    observation = sprintf(...
        "Active solution is now ID %d (Feasible=%s, %d bytes, MaxError=%g).", ...
        chosen.ID, string(chosen.Feasible), totalMemoryUsage(chosen,'bytes'), err.MaxErrorInSolution);
end
