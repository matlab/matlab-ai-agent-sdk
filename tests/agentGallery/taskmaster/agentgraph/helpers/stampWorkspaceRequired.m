function [observation, workspace] = stampWorkspaceRequired(workspace, label)
%stampWorkspaceRequired Workspace-aware test tool with a REQUIRED argument.
%   Exists to prove AgentGraph rejects it as a FunctionNode's tool: a
%   FunctionNode calls the tool with no arguments, so LABEL could never arrive.

% Copyright 2026 The MathWorks, Inc.

    arguments (Input)
        workspace struct
        label (1,1) string   % Text to append
    end

    if ~isfield(workspace, "stamps")
        workspace.stamps = strings(1, 0);
    end
    workspace.stamps(end+1) = label;
    observation = "stamped: " + label;
end
