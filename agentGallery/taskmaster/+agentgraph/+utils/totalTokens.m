function total = totalTokens(source)
%TOTALTOKENS  Tokens recorded in a workspace or a live top-level router.
%   For a live top-level router, include its own tokens and the graph-node
%   tokens in its Workspace. Pass a workspace alone for graph-node totals.

% Copyright 2026 The MathWorks, Inc.

arguments
    source
end

if isa(source, "aisdk.AIAgent")
    total = source.NumTotalTokens + ...
        agentgraph.internal.Workspace.totalTokens(source.Workspace);
else
    total = agentgraph.internal.Workspace.totalTokens(source);
end
end
