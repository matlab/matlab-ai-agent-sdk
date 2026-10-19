function workspace = clearSolution(workspace)
%clearSolution Remove stale solution state from the agent workspace.
%   Called whenever the problem changes so that inspection/generation tools
%   cannot operate on a solution that no longer matches the problem.

% Copyright 2026 The MathWorks, Inc.

    % Note: workspace.contract is intentionally NOT cleared here. The contract
    % records the declared configuration and must survive solution invalidation
    % so saveContract can serialize it after a reconfigure.
    stale = ["solution","activeSolution","approximated","replaced"];
    for f = stale
        if isfield(workspace, f)
            workspace = rmfield(workspace, f);
        end
    end
end
