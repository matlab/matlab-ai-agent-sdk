classdef (Abstract) Engine
%ENGINE  Abstract traversal strategy for an AgentGraph.
%
%   An Engine decides HOW a graph is walked: the order nodes run in and how the
%   result of one node influences the next. AgentGraph holds the graph DATA
%   (nodes, edges); the Engine holds the ALGORITHM. Swap the engine to swap the
%   traversal style (e.g. topological sort, walk-and-decide, route dispatch)
%   without touching the graph or node code.
%
%   CONTRACT: engines share the traverse(...) signature but NOT their
%   preconditions. Each concrete engine MUST document its graph contract --
%   e.g. whether it requires an acyclic graph (DAG) or tolerates cycles -- so
%   callers pair a graph with a compatible engine.
%
%   See also agentgraph.ToposortEngine, agentgraph.AgentGraph.

    methods (Abstract)
        %TRAVERSE  Walk GRAPH from PROMPT and return the final result.
        %   [RESULT, WORKSPACE] = TRAVERSE(THIS, GRAPH, PROMPT, WORKSPACE,
        %   ALLTOOLS, CLIENT) traverses GRAPH (an agentgraph.AgentGraph),
        %   running its nodes per this engine's strategy, and returns the final
        %   RESULT string plus the updated shared WORKSPACE.
        %
        %   [...] = TRAVERSE(..., GoalNode=NAME) is an optional partial-traversal
        %   hint: run NAME and its ancestors instead of the whole graph. Engines
        %   that do not support goal-targeting may ignore it. Cross-call
        %   memoization state (which nodes have already run) is carried in
        %   WORKSPACE, not in the engine, so a stateless engine stays reusable.
        [result, workspace] = traverse(this, graph, prompt, workspace, allTools, client, nvp)
    end
end
