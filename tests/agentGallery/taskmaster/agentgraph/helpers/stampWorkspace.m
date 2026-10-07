function [observation, workspace] = stampWorkspace(workspace, nvp)
%stampWorkspace Workspace-aware test tool with no required arguments.
%   [OBSERVATION, WORKSPACE] = stampWorkspace(WORKSPACE) appends a stamp to
%   workspace.stamps so a caller can prove the workspace was threaded through.

% Copyright 2026 The MathWorks, Inc.

    arguments (Input)
        workspace struct
        nvp.Label (1,1) string = "stamped"   % Text to append
    end

    if ~isfield(workspace, "stamps")
        workspace.stamps = strings(1, 0);
    end
    workspace.stamps(end+1) = nvp.Label;
    observation = "stamped: " + nvp.Label;
end
