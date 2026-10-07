classdef AgentNode < agentgraph.Node
%AGENTNODE  A graph node that runs a supplied AI agent.
%   AgentNode(NAME, AGENT) uses AGENT's client, tools, prompt, and settings.
%   ClearHistory=true restores AGENT's messages as supplied at construction
%   before each run; false continues the conversation across runs.

% Copyright 2026 The MathWorks, Inc.

    properties (SetAccess = immutable)
        % MATLAB cannot default-construct AIAgent, so the required constructor
        % argument validates its type before assignment to this property.
        Agent
        ClearHistory  (1,1) logical
    end

    properties (Access = private)
        InitialMessages (1,:) aisdk.message.LLMMessage
    end

    methods
        function this = AgentNode(name, agent, nvp)
            arguments
                name (1,1) string {mustBeValidVariableName}
                agent (1,1) aisdk.AIAgent
                nvp.Description   (1,1) string = ""
                nvp.ClearHistory  (1,1) logical = true
            end
            this.Name = name;
            this.Agent = agent;
            this.Description = nvp.Description;
            this.ClearHistory = nvp.ClearHistory;
            this.InitialMessages = agent.Messages;
        end

        function [result, workspace] = execute(this, workspace, nvp)
            arguments
                this
                workspace struct
                nvp.NodePrompt (1,1) string
                nvp.ParentWorkspacePath (1,:) string
                nvp.Observer = []
            end
            agent = this.Agent;
            if this.ClearHistory
                agent.Messages = this.InitialMessages;
            end
            agent.Workspace = workspace;
            before = agentgraph.internal.Workspace.tokenCounts(agent);
            tools = agent.Tools;
            for i = 1:numel(tools)
                if isa(tools(i), "agentgraph.internal.GraphTargetTool")
                    tools(i) = tools(i).bindWorkspacePath( ...
                        [nvp.ParentWorkspacePath, this.Name]);
                end
            end

            if ~isempty(nvp.Observer)
                nvp.Observer.nodeRunning(this.Name);
            end

            try
                response = agent.run(nvp.NodePrompt, Tools=tools);
                workspace = agent.Workspace;

                if isstring(response) || ischar(response)
                    result = string(response);
                else
                    result = string(jsonencode(response));
                end

                if ~isempty(nvp.Observer)
                    nvp.Observer.nodeDone(this.Name, result);
                end

                workspace = agentgraph.internal.Workspace.addTokenUsage( ...
                    workspace, agent, before);
            catch err
                % A rethrow binds no output arguments, so the caller receives no
                % workspace containing tool writes made before the failure.
                if ~isempty(nvp.Observer)
                    nvp.Observer.nodeError(this.Name, err);
                end
                rethrow(err);
            end
        end
    end
end
