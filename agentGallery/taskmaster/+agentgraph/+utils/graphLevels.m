function levels = graphLevels(workspace)
%GRAPHLEVELS  Dotted paths of graph records present in a workspace.

% Copyright 2026 The MathWorks, Inc.

arguments
    workspace struct
end

levels = agentgraph.internal.graphLevels(workspace);
end
