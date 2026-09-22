classdef AgentNode < agentgraph.Node
%AGENTNODE  A graph node that runs an LLM agent with a specific tool subset.

    properties
        Name          % (1,1) string — validation lives on abstract Node
        ToolNames     (1,:) string
        SystemPrompt  (1,1) string
        MaxIterations (1,1) double = 25
    end

    methods
        function this = AgentNode(name, nvp)
            arguments
                name (1,1) string
                nvp.ToolNames     (1,:) string = string.empty
                nvp.SystemPrompt  (1,1) string = ""
                nvp.Description   (1,1) string = ""
                nvp.MaxIterations (1,1) double = 25
            end
            this.Name = name;
            this.ToolNames = nvp.ToolNames;
            this.SystemPrompt = nvp.SystemPrompt;
            this.Description = nvp.Description;
            this.MaxIterations = nvp.MaxIterations;
        end

        function [result, workspace] = execute(this, nodePrompt, workspace, allTools, client, observer)
            arguments
                this
                nodePrompt (1,1) string
                workspace struct
                allTools (1,:) aisdk.llms.tool.LLMTool
                client
                observer = []
            end

            if isempty(allTools)
                nodeTools = allTools;
            else
                toolNames = [allTools.Name];
                nodeTools = allTools(ismember(toolNames, this.ToolNames));
            end

            agent = aisdk.AIAgent(client, ...
                SystemPrompt  = this.SystemPrompt, ...
                Tools         = nodeTools, ...
                Workspace     = workspace, ...
                DisplayMode   = "detailed", ...
                MaxIterations = this.MaxIterations);

            fprintf("\n== [AgentNode: %s] ==\n", this.Name);

            if ~isempty(observer)
                observer.nodeRunning(this.Name);
                drawnow
            end

            try
                response = agent.run(nodePrompt);
                workspace = agent.Workspace;

                if isstring(response) || ischar(response)
                    result = string(response);
                else
                    result = string(jsonencode(response));
                end

                if ~isempty(observer)
                    observer.nodeDone(this.Name, result);
                    drawnow
                end

                if ~isfield(workspace, 'tokenUsage')
                    workspace.tokenUsage = struct('input', 0, 'output', 0, 'total', 0, 'cached', 0);
                end
                workspace.tokenUsage.input  = workspace.tokenUsage.input  + agent.NumInputTokens;
                workspace.tokenUsage.output = workspace.tokenUsage.output + agent.NumOutputTokens;
                workspace.tokenUsage.total  = workspace.tokenUsage.total  + agent.NumTotalTokens;
                workspace.tokenUsage.cached = workspace.tokenUsage.cached + agent.NumCachedInputTokens;
            catch err
                if ~isempty(observer)
                    observer.nodeError(this.Name, err);
                end
                rethrow(err);
            end
        end
    end
end
