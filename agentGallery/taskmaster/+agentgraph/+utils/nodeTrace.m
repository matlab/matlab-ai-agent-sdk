function trace = nodeTrace(workspace, level)
%NODETRACE  Names of nodes completed at a graph level, in execution order.

% Copyright 2026 The MathWorks, Inc.

arguments
    workspace struct
    level (1,:) string {mustBeNonempty}
end

trace = agentgraph.internal.Workspace.nodeTrace(workspace, level);
end
