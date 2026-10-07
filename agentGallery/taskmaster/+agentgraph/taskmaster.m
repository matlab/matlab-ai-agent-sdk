function router = taskmaster(graph, client, nvp)
%TASKMASTER  Create a routing AI agent for an AgentGraph.
%   ROUTER = TASKMASTER(GRAPH, CLIENT) returns an aisdk.AIAgent whose graph
%   tool can drive GRAPH to one target node and its ancestors. The router can
%   also use ordinary tools supplied with Tools=.

% Copyright 2026 The MathWorks, Inc.

arguments
    graph (1,1) agentgraph.AgentGraph
    client
    nvp.SystemPrompt (1,1) string = defaultSystemPrompt()
    nvp.Tools (1,:) aisdk.tool.LLMTool = aisdk.tool.LLMTool.empty(1,0)
    nvp.Messages (1,:) aisdk.message.LLMMessage = aisdk.message.LLMMessage.empty(1,0)
    nvp.Workspace (1,1) struct = struct()
    nvp.DisplayMode (1,1) string = "detailed"
    nvp.MaxIterations (1,1) {mustBePositive} = aisdk.AIAgent.DefaultMaxIterations
    nvp.ResponseFormat = "text"
end

graphTool = graph.asTool();
if ~isempty(nvp.Tools) && any([nvp.Tools.Name] == graphTool.Name)
    agentgraph.internal.MessageCatalog.throwError( ...
        "agentgraph:duplicateToolName", graphTool.Name);
end

router = aisdk.AIAgent(client, ...
    SystemPrompt=nvp.SystemPrompt, ...
    Tools=[nvp.Tools, graphTool], ...
    Messages=nvp.Messages, Workspace=nvp.Workspace, ...
    DisplayMode=nvp.DisplayMode, MaxIterations=nvp.MaxIterations, ...
    ResponseFormat=nvp.ResponseFormat);
graphTool.attachRouter(router);
end

function prompt = defaultSystemPrompt()
promptFile = fullfile(fileparts(mfilename("fullpath")), ...
    "prompts", "taskmaster.md");
prompt = string(fileread(promptFile));
end
