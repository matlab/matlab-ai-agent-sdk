classdef AgentGraph
%AGENTGRAPH  Holds a graph's nodes and edges; delegates traversal to an Engine.
%
%   AgentGraph is graph DATA plus stateless helpers. It does not decide how the
%   graph is walked -- that is the Engine's job (see agentgraph.Engine). Swap
%   the Engine to swap the traversal strategy.

    properties
        Nodes
        Edges    (:,2) string
        Engine   (1,1) agentgraph.Engine = agentgraph.ToposortEngine()
        Observer
    end

    methods
        function this = AgentGraph(nodes, edges, nvp)
            arguments
                nodes
                edges (:,2) string
                nvp.Engine   (1,1) agentgraph.Engine = agentgraph.ToposortEngine()
                nvp.Observer = []
            end
            this.Nodes = nodes;
            this.Edges = edges;
            this.Engine = nvp.Engine;
            if isa(nvp.Observer, 'function_handle')
                this.Observer = nvp.Observer(this);
            else
                this.Observer = nvp.Observer;
            end
        end

        function [result, workspace] = run(this, client, prompt, workspace, allTools, nvp)
        %RUN  Run the graph via its Engine. Public entry point for callers.
        %
        %   [RESULT, WORKSPACE] = RUN(THIS, CLIENT, PROMPT, WORKSPACE, ALLTOOLS)
        %   runs the whole graph.
        %
        %   [...] = RUN(..., GoalNode=NAME) asks the engine to run only NAME and
        %   its ancestors (partial traversal). Pure pass-through to the engine --
        %   AgentGraph does not interpret the goal; the engine does.
            arguments
                this
                client
                prompt (1,1) string
                workspace struct
                allTools (1,:) aisdk.llms.tool.LLMTool
                nvp.GoalNode (1,1) string = ""
            end

            [result, workspace] = this.Engine.traverse( ...
                this, prompt, workspace, allTools, client, GoalNode=nvp.GoalNode);
        end

        function names = executionOrder(this, goalNode)
        %ORDEREDNODENAMES  Dependency-ordered node names (ancestors before node).
        %
        %   NAMES = ORDEREDNODENAMES(THIS) returns every node name in topological
        %   order (each node after its prerequisites).
        %
        %   NAMES = ORDEREDNODENAMES(THIS, GOALNODE) returns only GOALNODE and its
        %   ancestors, in topological order -- the itinerary for a partial,
        %   run-to-goal traversal.
        %
        %   This is the single place the digraph/DAG-guard/toposort logic lives;
        %   both dependencyString and the engine call it so ordering is defined once.
            arguments
                this
                goalNode (1,1) string = ""
            end

            edges = this.Edges;
            allNames = [this.Nodes.Name];

            if isempty(edges)
                names = allNames;
                if goalNode ~= "" && ismember(goalNode, names)
                    names = goalNode;   % isolated goal has no ancestors
                end
                return;
            end

            g = digraph(edges(:,1), edges(:,2));

            if ~isdag(g)
                error("agentgraph:cyclicGraph", ...
                    "AgentGraph requires an acyclic graph (DAG); the graph " + ...
                    "contains a cycle.");
            end

            if goalNode ~= ""
                % Ancestor subgraph: reverse edges, reach back from the goal.
                reachable = dfsearch(flipedge(g), goalNode);
                sg = subgraph(g, reachable);
                idx = toposort(sg);
                names = string(sg.Nodes.Name(idx)');
                return;
            end

            idx = toposort(g);
            names = string(g.Nodes.Name(idx)');

            % Include any isolated nodes (no edges) that digraph never saw.
            isolatedNodes = allNames(~ismember(allNames, names));
            names = [names, isolatedNodes];
        end

        function text = dependencyString(this)
        %DEPENDENCYSTRING  Arrow-separated node names in dependency order.
            text = strjoin(this.executionOrder(), " -> ");
        end

        function text = describeNodes(this)
        %DESCRIBENODEROLES  Dependency-ordered nodes annotated with their roles.
        %   Returns one line per node, "name: Description", in dependency order,
        %   so an orchestrator learns what each goal node is FOR (not just its
        %   name). Nodes with an empty Description are listed by name only. This
        %   is how a taskmaster learns the graph's strategy without a hand-written
        %   per-graph hint -- the roles live on the nodes (see graphConfig).
            names = this.executionOrder();
            lines = strings(1, numel(names));
            for i = 1:numel(names)
                node = this.getNode(names(i));
                if node.Description ~= ""
                    lines(i) = "- " + names(i) + ": " + node.Description;
                else
                    lines(i) = "- " + names(i);
                end
            end
            text = strjoin(lines, newline);
        end

        function node = getNode(this, name)
        %GETNODE  Return the scalar node with the given Name (errors if absent).
            for i = 1:numel(this.Nodes)
                if this.Nodes(i).Name == name
                    node = this.Nodes(i);
                    return;
                end
            end
            error("agentgraph:NodeNotFound", "Node '%s' not found.", name);
        end

        function nodePrompt = buildNodePrompt(~, prompt, nodeHistory)
        %BUILDNODEPROMPT  Build the next node's prompt from the user prompt + history.
            if isempty(nodeHistory)
                nodePrompt = prompt;
            else
                nodePrompt = prompt + newline + newline + ...
                    "Previous stages completed:" + newline + ...
                    strjoin(nodeHistory, newline);
            end
        end
    end
end
