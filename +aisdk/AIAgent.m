classdef AIAgent < handle
%AIAgent Agent for AI chat completions with agentic tool-calling loop.
%
%   AGENT = AIAgent(CLIENT, SYSTEMPROMPT) creates an AIAgent with the
%   specified client (aisdk.llms.client.OpenAIClient or aisdk.llms.client.OllamaClient)
%   and system prompt.
%
%   AGENT = AIAgent(CLIENT, SYSTEMPROMPT, TOOLS) specifies tools to use.
%
%   AGENT = AIAgent(CLIENT, SYSTEMPROMPT, Messages=msgs) uses existing messages.
%
%   AIAgent Properties:
%       Client           - The LLM client used for API calls
%       SystemPrompt     - System prompt
%       Tools            - Tools available to the agent during a run call
%       Messages         - Array of aisdk.llms.message.LLMMessage objects
%       Workspace        - Struct for passing data between tool calls
%       Verbose          - Print debug output (true/false)
%       ResponseFormat   - Format of response ("text", "json", struct, or JSON schema string)
%
%   AIAgent Methods:
%       run              - Run agentic loop with tool calling until completion

% Copyright 2024-2026 The MathWorks, Inc.

    properties
        %Client   The LLM client used for API calls
        Client
    end

    properties (SetAccess=protected)
        %SystemPrompt   System prompt
        SystemPrompt = []

        %Tools   Tools available to the agent during a run call.
        Tools (1,:) aisdk.llms.tool.LLMTool
    end

    properties
        %Messages   Array of aisdk.llms.message.LLMMessage objects
        Messages(1,:) aisdk.llms.message.LLMMessage

        %Workspace   Struct for passing data between tool calls
        Workspace struct

        Verbose(1,1) logical = false

        %ResponseFormat   Response format, "text" or "json" or struct or JSON schema string.
        ResponseFormat      {aisdk.llms.internal.mustBeResponseFormat} = "text"

        %MaxIterations   Maximum tool-calling iterations per run call.
        MaxIterations(1,1) double {mustBePositive} = aisdk.AIAgent.DefaultMaxIterations
    end

    properties (SetAccess=private)
        %NumInputTokens   Cumulative input (prompt) tokens across all generate calls.
        NumInputTokens(1,1) double = 0

        %NumCachedInputTokens   Cumulative cached input tokens across all generate calls.
        NumCachedInputTokens(1,1) double = 0

        %NumOutputTokens   Cumulative output (completion) tokens across all generate calls.
        NumOutputTokens(1,1) double = 0

        %NumTotalTokens   Cumulative total tokens across all generate calls.
        NumTotalTokens(1,1) double = 0

        ApprovedTools(1,:) string
    end

    properties (Hidden)
        ApprovalFcn
    end

    properties (Constant, Hidden)
        DefaultMaxIterations = 25
    end

    methods
        function this = AIAgent(client, systemPrompt, tools, nvp)
            arguments
                client                       (1,1) {mustBeClient}
                systemPrompt                       {aisdk.llms.internal.mustBeTextOrEmpty} = []
                tools                        (1,:) aisdk.llms.tool.LLMTool = aisdk.llms.tool.LLMTool.empty(1,0)
                nvp.Messages                 (1,:) aisdk.llms.message.LLMMessage = aisdk.llms.message.LLMMessage.empty(1,0)
                nvp.ResponseFormat                 {aisdk.llms.internal.mustBeResponseFormat} = "text"
                nvp.Workspace                (1,1) struct = struct()
                nvp.Verbose                  (1,1) logical = false
                nvp.MaxIterations            (1,1) {mustBePositive} = aisdk.AIAgent.DefaultMaxIterations
                nvp.ApprovalFcn                    (1,1) {mustBeA(nvp.ApprovalFcn,'function_handle')} = @aisdk.llms.internal.uiconfirm
            end

            this.Client = client;
            this.ResponseFormat = nvp.ResponseFormat;
            this.Messages = nvp.Messages;
            this.Workspace = nvp.Workspace;
            this.Verbose = nvp.Verbose;
            this.MaxIterations = nvp.MaxIterations;
            this.ApprovalFcn = nvp.ApprovalFcn;

            if isempty(tools)
                this.Tools = aisdk.llms.tool.LLMTool.empty(1,0);
            else
                this.Tools = tools;
            end

            if ~isempty(systemPrompt)
                systemPrompt = string(systemPrompt);
                if systemPrompt ~= ""
                   this.SystemPrompt = systemPrompt;
                end
            end
        end

        function response = run(this, query, nvp)
            %run   Run agentic loop with tool calling until completion.
            %
            %   RESPONSE = run(AGENT, QUERY) runs the agentic loop for the
            %   specified QUERY string and returns the final text response.

            arguments
                this (1,1) aisdk.AIAgent
                query {aisdk.llms.internal.mustBeMessagesInput}
                nvp.Tools(1, :) aisdk.llms.tool.LLMTool = this.Tools
                nvp.ToolChoice (1,:) {mustBeTextScalar} = "auto"
                nvp.ResponseFormat      {aisdk.llms.internal.mustBeResponseFormat} = this.ResponseFormat
                nvp.MaxIterations (1,1) {mustBePositive} = this.MaxIterations
            end

            newMessages = aisdk.llms.client.ClientBase.normalizeMessages(query);
            this.Messages = [this.Messages, newMessages];

            allTexts = string.empty(1,0);
            currentToolChoice = nvp.ToolChoice;

            for iteration = 1:nvp.MaxIterations
                this.print("[think]");

                if ~isempty(this.SystemPrompt)
                    messagesWithSystem = [
                        aisdk.LLMTextMessage(this.SystemPrompt, Role="system"), ...
                        this.Messages];
                else
                    messagesWithSystem = this.Messages;
                end

                [text, msgs, info] = this.Client.generate(messagesWithSystem, ...
                    Tools=nvp.Tools, ToolChoice=currentToolChoice, ...
                    ResponseFormat=nvp.ResponseFormat);

                % Revert to "auto" after the first call so the model can
                % produce a final text response and exit the loop.
                if ~ismember(currentToolChoice, ["auto", "none"])
                    currentToolChoice = "auto";
                end
                this.print(text);
                this.Messages = [this.Messages, msgs];

                this.NumInputTokens       = this.NumInputTokens       + info.Tokens.NumInputTokens;
                this.NumOutputTokens      = this.NumOutputTokens      + info.Tokens.NumOutputTokens;
                this.NumTotalTokens       = this.NumTotalTokens       + info.Tokens.NumTotalTokens;
                this.NumCachedInputTokens = this.NumCachedInputTokens + info.Tokens.NumCachedInputTokens;

                if isstruct(text)
                    % assumes tool calls never produce structured text content
                    response = text;
                    return;
                end

                if strlength(text) > 0
                    allTexts(end+1) = text; %#ok<AGROW>
                end

                toolCalls = msgs(arrayfun(@(m) isa(m, 'aisdk.LLMToolCallMessage'), msgs));
                if isempty(toolCalls)
                    if ~isempty(allTexts)
                        response = join(allTexts, newline);
                    else
                        response = text;
                    end
                    return;
                end

                for i = 1:numel(toolCalls)
                    tc = toolCalls(i);
                    try
                        tool = nvp.Tools.selectTool(tc.Name);
                    catch ME
                        output = "Error: " + ME.message;
                        this.print("[function return] " + string(jsonencode(output)));
                        this.Messages(end+1) = aisdk.LLMToolResultMessage( ...
                            string(output), ToolCallID=tc.ToolCallID, Name=tc.Name);
                        continue
                    end
                    if tool.RequiresApproval == "once" && ismember(tc.Name, this.ApprovedTools)
                        % Already approved in a previous round
                    elseif tool.RequiresApproval ~= "never"
                        approval = this.ApprovalFcn(tool, tc.Arguments);
                        if ~approval.Approved
                            msg = "User denied tool execution of " + tc.Name;
                            if strlength(approval.Reason) > 0
                                msg = msg + ": " + approval.Reason;
                            end
                            this.print("[denied] " + msg);
                            this.Messages(end+1) = aisdk.LLMToolResultMessage( ...
                                msg, ToolCallID=tc.ToolCallID, Name=tc.Name);
                            continue
                        end
                        if approval.Permanent
                            this.ApprovedTools(end+1) = tc.Name;
                        end
                        if strlength(approval.Reason) > 0
                            this.print("[approved] " + approval.Reason);
                            this.Messages(end+1) = aisdk.LLMTextMessage(approval.Reason);
                        end
                    end
                    this.print("[call function " + tc.Name + " with inputs " + jsonencode(tc.Arguments) + "]");
                    try
                        [output, workspaceOut] = evaluate(tool, tc.Arguments, this.Workspace);
                        this.Workspace = workspaceOut;
                    catch ME
                        output = "Error: " + ME.message;
                    end
                    this.print("[function return] " + string(jsonencode(output)));
                    if isstring(output) || ischar(output)
                        resultStr = string(output);
                    else
                        resultStr = jsonencode(output);
                    end
                    this.Messages(end+1) = aisdk.LLMToolResultMessage(resultStr, ...
                        ToolCallID=tc.ToolCallID, Name=tc.Name);
                end
            end

            if ~isempty(allTexts)
                response = join(allTexts, newline);
            else
                response = "";
            end
            warning("aiAgent:MaxIterationsReached", ...
                "Tool calling loop reached maximum of %d iterations.", nvp.MaxIterations);
        end

    end

    methods (Access=private)
        function print(this, msg)
            if this.Verbose
                if isstruct(msg)
                    disp(jsonencode(msg));
                else
                    disp(msg);
                end
            end
        end

    end


end

function mustBeClient(value)
if ~isa(value, 'aisdk.llms.client.ClientBase')
    error("llms:invalidClientType", ...
        aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:invalidClientType"));
end
end
