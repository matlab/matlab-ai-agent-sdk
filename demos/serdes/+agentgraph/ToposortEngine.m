classdef ToposortEngine < agentgraph.Engine
%TOPOSORTENGINE  Default engine: topological order, then run nodes in sequence.
%
%   Runs the graph in topological order so every node runs after its
%   prerequisites, executing nodes one at a time and threading a running
%   nodeHistory + workspace forward.
%
%   FULL vs PARTIAL traversal:
%     - By default, runs the WHOLE graph (every node, once).
%     - With GoalNode=NAME, runs only NAME and its ancestors (partial traversal).
%       This lets an orchestrator "re-drive the DAG to a chosen target".
%
%   GRAPH CONTRACT: requires an ACYCLIC graph (DAG). Cyclic graphs are
%   unsupported -- use a walk-based engine for those. The ordering (and its DAG
%   guard) is delegated to AgentGraph.executionOrder, which throws
%   agentgraph:cyclicGraph rather than failing cryptically.
%
%   See also agentgraph.Engine, agentgraph.AgentGraph.

    methods
        function [result, workspace] = traverse(this, graph, prompt, workspace, allTools, client, nvp)
            arguments
                this
                graph (1,1) agentgraph.AgentGraph
                prompt (1,1) string
                workspace struct
                allTools (1,:) aisdk.llms.tool.LLMTool
                client
                nvp.GoalNode (1,1) string = ""
            end

            % Itinerary: whole graph, or the goal + its ancestors. Ordering and
            % the DAG guard live in AgentGraph so they are defined once.
            order = graph.executionOrder(nvp.GoalNode);

            nodeHistory = strings(1, 0);
            result = "";

            for i = 1:numel(order)
                nodeName = order(i);

                node = graph.getNode(nodeName);
                nodePrompt = graph.buildNodePrompt(prompt, nodeHistory);

                [nodeResult, workspace] = node.execute( ...
                    nodePrompt, workspace, allTools, client, graph.Observer);

                nodeHistory(end+1) = nodeName + ": " + nodeResult; %#ok<AGROW>
                result = nodeResult;
            end
        end
    end
end
