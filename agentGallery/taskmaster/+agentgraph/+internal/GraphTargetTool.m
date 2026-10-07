classdef GraphTargetTool < aisdk.tool.BuiltInTool
%GRAPHTARGETTOOL  LLM tool that drives a graph to one selected target node.
%   A value copy can have its own WorkspacePath for a nested run. Copies share
%   RouterLink so they can read the current request from the same routing agent.

% Copyright 2026 The MathWorks, Inc.

    properties (SetAccess = immutable)
        Graph agentgraph.AgentGraph
    end

    properties (SetAccess = private)
        WorkspacePath (1,:) string
        OutputArguments (1,:) aisdk.LLMToolArgument
    end

    properties (Access = private)
        RouterLink (1,1) agentgraph.internal.RouterLink
    end

    methods
        function this = GraphTargetTool(graph)
            arguments
                graph (1,1) agentgraph.AgentGraph
            end
            description = "Run the graph to a target node and its ancestors. " + ...
                "Available targets:" + newline + graph.describeNodes();
            this.Name = "runToTargetNode";
            this.Description = description;
            this.DisplayTitle = this.Name;
            this.Annotations = struct();
            this.InputArguments = aisdk.LLMToolArgument("TargetNode", ...
                DataType="string", Required=true, ...
                Description="Target node to run. One of: " + ...
                    graph.dependencyString() + ".");
            this.OutputArguments = aisdk.LLMToolArgument("observation", ...
                DataType="string", Description="What ran and its result.");
            this.Workspace = "agent";
            this.ApprovalRequest = "never";
            this.Graph = graph;
            this.WorkspacePath = graph.Name;
            this.RouterLink = agentgraph.internal.RouterLink();
        end
    end

    methods (Hidden)
        function attachRouter(this, router)
        %ATTACHROUTER  Share one router with every value copy of this tool.
            arguments
                this (1,1) agentgraph.internal.GraphTargetTool
                router (1,1) aisdk.AIAgent
            end
            this.RouterLink.Router = router;
        end

        function tool = bindWorkspacePath(this, path)
        %BINDWORKSPACEPATH  Return a value copy for one nested occurrence.
            arguments
                this (1,1) agentgraph.internal.GraphTargetTool
                path (1,:) string {mustBeNonempty}
            end
            tool = this;
            tool.WorkspacePath = path;
        end
    end

    methods (Access = protected)
        function signature = displaySignature(this)
            signature = this.Name + "(TargetNode)";
        end

        function label = displayTypeLabel(~)
            label = "GraphTargetTool";
        end

        function label = displayWorkspaceLabel(this)
            label = """" + this.Workspace + """";
        end

        function [output, workspace] = evaluateImpl(this, args, workspace)
            arguments
                this (1,1) agentgraph.internal.GraphTargetTool
                args (1,1) struct
                workspace struct
            end

            if ~isfield(args, "TargetNode")
                aisdk.internal.throwError( ...
                    "aisdk:requiredArgumentNotFound", "TargetNode");
            end
            targetNode = string(args.TargetNode);
            if ~isscalar(targetNode) || ...
                    ~ismember(targetNode, [this.Graph.Nodes.Name])
                agentgraph.internal.MessageCatalog.throwError( ...
                    "agentgraph:unknownTargetNode", this.Graph.Name, ...
                    join(targetNode, ", "));
            end

            request = this.latestRequest();
            path = this.WorkspacePath;
            workspace = agentgraph.internal.Workspace.recordPrompt( ...
                workspace, path, request);
            before = agentgraph.internal.Workspace.nodeTrace(workspace, path);
            selected = this.Graph.executionOrder(targetNode);
            [result, workspace] = this.Graph.traverseAtWorkspacePath( ...
                request, workspace, path, TargetNode=targetNode, ReuseCache=true);
            after = agentgraph.internal.Workspace.nodeTrace(workspace, path);
            executed = after(numel(before)+1:end);
            reused = setdiff(selected, executed, "stable");

            executedText = join(executed, ", ");
            if isempty(executed)
                executedText = "none";
            end
            observation = "Ran to '" + targetNode + "'. Executed: " + ...
                executedText + ".";
            if ~isempty(reused)
                observation = observation + " Reused existing results for: " + ...
                    join(reused, ", ") + ".";
            end
            output = struct("observation", observation + newline + result);
        end
    end

    methods (Access = private)
        function request = latestRequest(this)
            if isempty(this.RouterLink.Router)
                agentgraph.internal.MessageCatalog.throwError( ...
                    "agentgraph:routerNotAttached");
            end
            messages = this.RouterLink.Router.Messages;
            for i = numel(messages):-1:1
                if isa(messages(i), "aisdk.LLMTextMessage") && ...
                        messages(i).Role == "user"
                    request = string(messages(i).Text);
                    return;
                end
            end
            agentgraph.internal.MessageCatalog.throwError( ...
                "agentgraph:routerRequestMissing");
        end
    end
end
