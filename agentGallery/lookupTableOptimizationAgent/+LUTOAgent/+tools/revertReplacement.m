function [observation, workspace] = revertReplacement(workspace)
%revertReplacement Undo the most recent in-model block replacement and restore the original block (same MATLAB session only).
%   Only works within the same MATLAB session that performed the replace.

% Copyright 2026 The MathWorks, Inc.

    arguments
        workspace
    end

    if ~isfield(workspace, "replaced") || ~workspace.replaced
        observation = "Nothing to revert: no in-model replacement has been made this session.";
        return
    end

    revertToOriginal(workspace.activeSolution);
    workspace.replaced = false;

    observation = "Reverted: the original block has been restored in '" + ...
        string(workspace.functionSpec) + "'.";
end
