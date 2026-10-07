classdef AgentGraph
%AGENTGRAPH  Named DAG of nodes executed in dependency order.
%
%   Runs the whole graph or a target node and its ancestors in topological
%   order, threading the workspace through each node.

% Copyright 2026 The MathWorks, Inc.

    properties (SetAccess = immutable)
        %Name  Persistent graph identity and direct-run workspace label.
        Name     (1,1) string
        %Nodes  The graph's nodes. Non-emptiness is validated on the constructor
        %   argument, not here, because MATLAB rejects the implicit empty default.
        Nodes    (1,:) agentgraph.Node
        Edges    (:,2) string
    end

    properties
        Observer
    end

    methods
        function this = AgentGraph(nodes, edges, nvp)
            arguments
                nodes agentgraph.Node {mustBeNonempty}
                edges (:,2) string
                nvp.Name (1,1) string {mustBeValidVariableName}
                nvp.Observer = []
            end
            if ~isfield(nvp, "Name")
                agentgraph.internal.MessageCatalog.throwError( ...
                    "agentgraph:missingGraphName");
            end
            this.Name = nvp.Name;
            this.Edges = edges;
            this.Nodes = nodes;
            checkNodeNames(this.Name, this.Nodes);
            if isa(nvp.Observer, 'function_handle')
                this.Observer = nvp.Observer(this);
            else
                this.Observer = nvp.Observer;
            end
        end

        function [result, workspace] = traverse(this, prompt, workspace, nvp)
        %TRAVERSE  Run the graph in dependency order.
        %
        %   [RESULT, WORKSPACE] = TRAVERSE(THIS, PROMPT, WORKSPACE) runs the
        %   whole graph under the workspace record named by this.Name.
        %
        %   [...] = TRAVERSE(..., TargetNode=NAME) runs only NAME and its ancestors.
            arguments
                this
                prompt (1,1) string
                workspace struct
                nvp.TargetNode (1,1) string = ""
            end

            [result, workspace] = this.traverseAtWorkspacePath( ...
                prompt, workspace, this.Name, ...
                TargetNode=nvp.TargetNode, ReuseCache=false);
        end

        function workspace = clearCache(this, workspace, nvp)
        %CLEARCACHE  Clear this graph's immediate cache layer at every occurrence.
        %   Node=NAME clears NAME and downstream nodes at that layer only.
            arguments
                this (1,1) agentgraph.AgentGraph
                workspace struct
                nvp.Node (1,1) string = ""
            end
            if nvp.Node ~= ""
                if ~ismember(nvp.Node, [this.Nodes.Name])
                    agentgraph.internal.MessageCatalog.throwError( ...
                        "agentgraph:clearCacheUnknownNode", this.Name, nvp.Node);
                end
                nodeNames = descendantsIncludingSelf(this, nvp.Node);
            end
            paths = agentgraph.internal.Workspace.findRecordPathsByGraphName( ...
                workspace, this.Name);
            for path = paths
                if nvp.Node == ""
                    nodeNames = agentgraph.internal.Workspace.cachedNodes( ...
                        workspace, path);
                end
                workspace = agentgraph.internal.Workspace.clearCache( ...
                    workspace, path, nodeNames);
            end
        end
    end

    methods (Access = ?agentgraph.internal.GraphTargetTool)
        function [result, workspace] = traverseAtWorkspacePath(this, prompt, workspace, path, nvp)
        %TRAVERSEATWORKSPACEPATH  Run at a graph tool's bound workspace path.
            arguments
                this
                prompt (1,1) string
                workspace struct
                path (1,:) string
                nvp.TargetNode (1,1) string = ""
                nvp.ReuseCache (1,1) logical = false
            end
            workspace = agentgraph.internal.Workspace.prepareGraphRecord( ...
                workspace, path, this.Name);

            order = this.executionOrder(nvp.TargetNode);
            nodeHistory = strings(1, 0);
            result = "";

            for nodeName = order
                if nvp.ReuseCache
                    [found, storedResult] = agentgraph.internal.Workspace.cachedResult( ...
                        workspace, path, nodeName);
                    if found
                        nodeHistory(end+1) = nodeName + ": " + storedResult; %#ok<AGROW>
                        result = storedResult;
                        continue;
                    end
                end

                node = this.getNode(nodeName);
                nodePrompt = this.buildNodePrompt(prompt, nodeHistory);
                [nodeResult, workspace] = node.execute( ...
                    workspace, NodePrompt=nodePrompt, ...
                    ParentWorkspacePath=path, Observer=this.Observer);

                % A trace entry means execution completed; a throwing node
                % never reaches this point.
                workspace = agentgraph.internal.Workspace.appendNodeTrace( ...
                    workspace, path, nodeName);
                if nvp.ReuseCache
                    workspace = agentgraph.internal.Workspace.cacheResult( ...
                        workspace, path, nodeName, nodeResult);
                end

                nodeHistory(end+1) = nodeName + ": " + nodeResult; %#ok<AGROW>
                result = nodeResult;
            end
        end
    end

    methods (Hidden)
        function tool = asTool(this)
        %ASTOOL  Offer graph targets to a routing agent as one LLM tool.
            undescribed = strings(1,0);
            for i = 1:numel(this.Nodes)
                if this.Nodes(i).Description == ""
                    undescribed(end+1) = this.Nodes(i).Name; %#ok<AGROW>
                end
            end
            if ~isempty(undescribed)
                agentgraph.internal.MessageCatalog.throwError( ...
                    "agentgraph:missingNodeDescription", this.Name, ...
                    join("'" + undescribed + "'", ", "));
            end
            tool = agentgraph.internal.GraphTargetTool(this);
        end

        function names = executionOrder(this, targetNode)
        %EXECUTIONORDER  Dependency-ordered node names (ancestors before node).
        %
        %   NAMES = EXECUTIONORDER(THIS) returns every node name in topological
        %   order (each node after its prerequisites).
        %
        %   NAMES = EXECUTIONORDER(THIS, TARGETNODE) returns only TARGETNODE and its
        %   ancestors, in topological order -- the itinerary for a partial,
        %   run-to-target traversal.
        %
        %   This is the single place the digraph/DAG-guard/toposort logic lives;
        %   both dependencyString and traversal use it, so ordering is defined once.
            arguments
                this
                targetNode (1,1) string = ""
            end

            edges = this.Edges;
            allNames = [this.Nodes.Name];

            if isempty(edges)
                names = allNames;
                if targetNode ~= "" && ismember(targetNode, names)
                    names = targetNode;   % isolated target has no ancestors
                end
                return;
            end

            g = digraph(edges(:,1), edges(:,2));

            if ~isdag(g)
                agentgraph.internal.MessageCatalog.throwError( ...
                    "agentgraph:cyclicGraph");
            end

            if targetNode ~= ""
                % digraph is built from edge endpoints, so a node no edge mentions
                % has no vertex and dfsearch would throw on it.
                if ~ismember(targetNode, string(g.Nodes.Name)')
                    names = targetNode;
                    return;
                end

                % Ancestor subgraph: reverse edges, reach back from the goal.
                reachable = dfsearch(flipedge(g), targetNode);
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
            text = join(this.executionOrder(), " -> ");
        end

        function text = describeNodes(this)
        %DESCRIBENODES  Dependency-ordered nodes annotated with their roles.
        %   Returns one line per node, "name: Description", in dependency order,
        %   so an orchestrator learns what each goal node is FOR (not just its
        %   name). Nodes with an empty Description are listed by name only. This
        %   is how a taskmaster learns the graph's strategy without a hand-written
        %   per-graph hint -- the roles live on the nodes, set where the graph is
        %   defined.
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
            text = join(lines, newline);
        end

        function node = getNode(this, name)
        %GETNODE  Return the scalar node with the given Name (errors if absent).
            for i = 1:numel(this.Nodes)
                if this.Nodes(i).Name == name
                    node = this.Nodes(i);
                    return;
                end
            end
            agentgraph.internal.MessageCatalog.throwError( ...
                "agentgraph:nodeNotFound", name);
        end

        function nodePrompt = buildNodePrompt(~, prompt, nodeHistory)
        %BUILDNODEPROMPT  Build the next node's prompt from the user prompt + history.
            if isempty(nodeHistory)
                nodePrompt = prompt;
            else
                nodePrompt = prompt + newline + newline + ...
                    "Previous stages completed:" + newline + ...
                    join(nodeHistory, newline);
            end
        end
    end
end

function checkNodeNames(graphName, nodes)
%CHECKNODENAMES  Every node in a graph must have a distinct address.
    names = [nodes.Name];
    [uniqueNames, ~, idx] = unique(names);
    if numel(uniqueNames) < numel(names)
        offenders = uniqueNames(accumarray(idx(:), 1) > 1);
        agentgraph.internal.MessageCatalog.throwError( ...
            "agentgraph:duplicateNodeName", graphName, ...
            join("'" + offenders + "'", ", "));
    end
end

function names = descendantsIncludingSelf(graph, nodeName)
%DESCENDANTSINCLUDINGSELF  Node and all nodes depending on it.
names = nodeName;
if isempty(graph.Edges)
    return;
end
dependencyGraph = digraph(graph.Edges(:,1), graph.Edges(:,2));
if ismember(nodeName, string(dependencyGraph.Nodes.Name)')
    names = string(bfsearch(dependencyGraph, nodeName))';
end
end
