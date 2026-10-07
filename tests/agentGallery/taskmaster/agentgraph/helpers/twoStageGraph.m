function graph = twoStageGraph(name)
%TWOSTAGEGRAPH  A -> B, each with a Description for a routing prompt to quote.
%   The smallest graph a taskmaster can route into: two nodes, one edge, and
%   Descriptions, since describeNodes() is what the routing prompt is built from.

% Copyright 2026 The MathWorks, Inc.

    nodes = [
        agentgraph.FunctionNode("A", @(w) deal("resultA",w), ...
            Description="First stage")
        agentgraph.FunctionNode("B", @(w) deal("resultB",w), ...
            Description="Second stage")
    ];
    graph = agentgraph.AgentGraph(nodes, ["A","B"], Name=name);
end
