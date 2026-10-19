function [observation, workspace] = listSolutions(workspace, feasibleOnly)
%listSolutions List the candidate solutions the solver explored (ID, bytes, feasibility, table size, max error); set feasibleOnly to true to limit the list to feasible candidates.
%   Returns ID, memory, feasibility, table size, and error for each
%   candidate so the agent (or user) can pick an alternative by ID.

% Copyright 2026 The MathWorks, Inc.

    arguments
        workspace
        feasibleOnly (1,1) logical = false  % List only feasible candidates.
    end

    if ~isfield(workspace, "solution")
        observation = "No solution available. Call solveProblem first.";
        return
    end

    if feasibleOnly
        cands = workspace.solution.FeasibleSolutions;
    else
        cands = workspace.solution.AllSolutions;
    end

    if isempty(cands)
        observation = "No candidates to list.";
        return
    end

    header = sprintf("%-6s %-12s %-10s %-12s %-12s", "ID", "Bytes", "Feasible", "TableSize", "MaxError");
    rows = strings(1, numel(cands));
    for i = 1:numel(cands)
        c = cands(i);
        err = getErrorValue(c);
        rows(i) = sprintf("%-6d %-12d %-10s %-12d %-12g", ...
            c.ID, totalMemoryUsage(c,'bytes'), string(c.Feasible), ...
            numel(c.TableData.TableValues), err.MaxErrorInSolution);
    end
    observation = strjoin([header, rows], newline) + newline + ...
        "Use selectSolution with an ID to make one active.";
end
