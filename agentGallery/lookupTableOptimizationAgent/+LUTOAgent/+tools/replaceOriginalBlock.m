function [observation, workspace] = replaceOriginalBlock(workspace)
%replaceOriginalBlock Replace the original Simulink block or subsystem with the generated LUT approximation; requires a "block" source path and a prior generateApproximation on the active solution, and mutates the user's model.
%   Requires that the problem source was a Simulink block and that
%   generateApproximation has already been called on the active solution.
%   This mutates the user's model, so the tool should require approval.

% Copyright 2026 The MathWorks, Inc.

    arguments
        workspace
    end

    if ~isfield(workspace, "activeSolution") || ~isa(workspace.activeSolution, 'FunctionApproximation.LUTSolution')
        observation = "No solution available. Call solveProblem first.";
        return
    end
    if ~isfield(workspace, "sourceKind") || workspace.sourceKind ~= "block"
        observation = "replaceWithApproximate only works when the problem " + ...
            "source is a Simulink block path. This problem is a " + ...
            char(getfieldOrDefault(workspace, "sourceKind", "non-block")) + " source.";
        return
    end
    if ~isfield(workspace, "approximated") || ~workspace.approximated
        observation = "Call generateApproximation before replaceOriginalBlock.";
        return
    end

    replaceWithApproximate(workspace.activeSolution);
    workspace.replaced = true;

    observation = "Replaced the original block with the optimized LUT subsystem in '" + ...
        string(workspace.functionSpec) + "'. " + ...
        "Use revertReplacement to undo (same MATLAB session only).";
end

function v = getfieldOrDefault(s, f, d)
    if isfield(s, f); v = s.(f); else; v = d; end
end
