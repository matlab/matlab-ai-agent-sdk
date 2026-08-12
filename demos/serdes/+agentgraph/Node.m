classdef (Abstract) Node
%NODE  Abstract base for anything an engine can run as a graph step.
%
%   A Node is one unit of work in a graph traversal. Engines address nodes by
%   Name and run them via execute(...). Concrete node types (AgentNode,
%   FunctionNode) supply the behaviour.
%
%   Note: SystemPrompt is intentionally NOT part of this contract -- it is
%   specific to LLM-backed nodes (AgentNode) and FunctionNode has none.

    properties (Abstract)
        %Name  Unique identifier (1,1 string) used by engines to address this node.
        Name
    end

    properties
        %Description  Short orchestration-facing role of this node (1,1 string).
        %   Unlike an AgentNode's SystemPrompt (which tells the node's own agent
        %   HOW to do its work), Description tells an ORCHESTRATOR above the graph
        %   what this node is FOR -- e.g. "baseline measurement" vs. "the iterate
        %   lever". Read by AgentGraph.dependencyString so the graph is self-describing
        %   and a taskmaster needs no hand-written per-graph hint. Empty by default.
        Description (1,1) string = ""
    end

    methods (Abstract)
        %EXECUTE  Do this node's unit of work.
        %   [RESULT, WORKSPACE] = EXECUTE(THIS, TASK, WORKSPACE, ALLTOOLS,
        %   CLIENT, OBSERVER) runs the node against TASK, threading the shared
        %   WORKSPACE through, and returns the node's string RESULT plus the
        %   updated WORKSPACE. OBSERVER (optional) receives progress callbacks.
        [result, workspace] = execute(this, nodePrompt, workspace, allTools, client, observer)
    end
end
