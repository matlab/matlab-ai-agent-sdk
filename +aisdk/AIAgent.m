classdef AIAgent < handle
%AIAgent Agent for AI chat completions with agentic tool-calling loop.
%
%   AGENT = AIAgent(CLIENT) creates an AIAgent with the specified client
%   (aisdk.client.OpenAIClient or aisdk.client.OllamaClient).
%
%   AGENT = AIAgent(CLIENT, SystemPrompt=SP) specifies a system prompt.
%
%   AGENT = AIAgent(CLIENT, Tools=T) specifies tools to use.
%
%   AGENT = AIAgent(CLIENT, SystemPrompt=SP, Tools=T, Messages=msgs)
%   specifies system prompt, tools, and existing messages.
%
%   AIAgent Properties:
%       Client           - The LLM client used for API calls
%       SystemPrompt     - System prompt
%       Tools            - Tools available to the agent during a run call
%       Messages         - Array of aisdk.message.LLMMessage objects
%       Workspace        - Struct for passing data between tool calls
%       DisplayMode      - Display mode ("off" or "detailed")
%       ResponseFormat   - Format of response ("text", "json", struct, or JSON schema string)
%       ContextUsage     - Fraction of context window used
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
        Tools (1,:) aisdk.tool.LLMTool
    end

    properties
        %Messages   Array of aisdk.message.LLMMessage objects
        Messages(1,:) aisdk.message.LLMMessage

        %Workspace   Struct for passing data between tool calls
        Workspace struct

        %DisplayMode   Display mode: "off" or "detailed".
        DisplayMode(1,1) string {mustBeMember(DisplayMode, ["off","detailed"])} = "detailed"

        %ResponseFormat   Response format, "text" or "json" or struct or JSON schema string.
        ResponseFormat      {aisdk.internal.mustBeResponseFormat} = "text"

        %MaxIterations   Maximum tool-calling iterations per run call.
        MaxIterations(1,1) double {mustBePositive} = aisdk.AIAgent.DefaultMaxIterations

        %ApprovalFcn   Callback invoked to obtain a human approval decision.
        ApprovalFcn(1,1) function_handle = @aisdk.utils.uiconfirm
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
    end

    properties (SetAccess=private, Transient)
        %UserApprovedTools   Names of tools the user approved with "allow from
        %   now on" for the current in-memory agent. Transient: approval state
        %   does not persist across save/load, so a loaded agent prompts again.
        UserApprovedTools(1,:) string
    end

    properties (Dependent, SetAccess=private)
        %ContextUsage   Fraction of the context window used
        ContextUsage(1,1) double
    end

    properties (Hidden, SetAccess=private)
        %LastInputTokens   Input tokens from the most recent generate call.
        LastInputTokens(1,1) double = 0
    end

    properties (Constant, Hidden)
        DefaultMaxIterations = 25
    end

    methods
        function this = AIAgent(client, nvp)
            arguments
                client                       (1,1) {mustBeClient}
                nvp.SystemPrompt                   {aisdk.internal.mustBeTextOrEmpty} = []
                nvp.Tools                    (1,:) aisdk.tool.LLMTool = aisdk.tool.LLMTool.empty(1,0)
                nvp.Messages                 (1,:) aisdk.message.LLMMessage = aisdk.message.LLMMessage.empty(1,0)
                nvp.ResponseFormat                 {aisdk.internal.mustBeResponseFormat} = "text"
                nvp.Workspace                (1,1) struct = struct()
                nvp.DisplayMode              (1,1) string {mustBeMember(nvp.DisplayMode, ["off","detailed"])} = "detailed"
                nvp.MaxIterations            (1,1) {mustBePositive} = aisdk.AIAgent.DefaultMaxIterations
                nvp.ApprovalFcn                    (1,1) {mustBeA(nvp.ApprovalFcn,'function_handle')} = @aisdk.utils.uiconfirm
            end

            this.Client = client;
            this.ResponseFormat = nvp.ResponseFormat;
            this.Messages = nvp.Messages;
            this.Workspace = nvp.Workspace;
            this.DisplayMode = nvp.DisplayMode;
            this.MaxIterations = nvp.MaxIterations;
            this.ApprovalFcn = nvp.ApprovalFcn;

            if isempty(nvp.Tools)
                this.Tools = aisdk.tool.LLMTool.empty(1,0);
            else
                this.Tools = nvp.Tools;
            end

            if ~isempty(nvp.SystemPrompt)
                systemPrompt = string(nvp.SystemPrompt);
                if systemPrompt ~= ""
                   this.SystemPrompt = systemPrompt;
                end
            end
        end

        function response = run(this, prompt, nvp)
            %run   Run agentic loop with tool calling until completion.
            %
            %   RESPONSE = run(AGENT, PROMPT) runs the agentic loop for the
            %   specified PROMPT string and returns the final text response.

            arguments
                this (1,1) aisdk.AIAgent
                prompt {aisdk.internal.mustBeMessagesInput}
                nvp.Tools(1, :) aisdk.tool.LLMTool = this.Tools
                nvp.ToolChoice (1,:) {mustBeTextScalar} = "auto"
                nvp.ResponseFormat      {aisdk.internal.mustBeResponseFormat} = this.ResponseFormat
                nvp.MaxIterations (1,1) {mustBePositive} = this.MaxIterations
                nvp.DisplayMode (1,1) string {mustBeMember(nvp.DisplayMode, ["off","detailed"])} = this.DisplayMode
            end

            displayMode = nvp.DisplayMode;

            newMessages = aisdk.client.ClientBase.normalizeMessages(prompt);
            this.Messages = [this.Messages, newMessages];

            allTexts = string.empty(1,0);
            currentToolChoice = nvp.ToolChoice;

            for iteration = 1:nvp.MaxIterations
                this.print(displayMode,"[think]");

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
                this.print(displayMode,text);
                this.Messages = [this.Messages, msgs];

                this.NumInputTokens       = this.NumInputTokens       + info.Tokens.NumInputTokens;
                this.NumOutputTokens      = this.NumOutputTokens      + info.Tokens.NumOutputTokens;
                this.NumTotalTokens       = this.NumTotalTokens       + info.Tokens.NumTotalTokens;
                this.NumCachedInputTokens = this.NumCachedInputTokens + info.Tokens.NumCachedInputTokens;

                if isstruct(text)
                    % assumes tool calls never produce structured text content
                    this.LastInputTokens = info.Tokens.NumInputTokens;
                    response = text;
                    return;
                end

                if strlength(text) > 0
                    allTexts(end+1) = text; %#ok<AGROW>
                end

                toolCalls = msgs(arrayfun(@(m) isa(m, 'aisdk.LLMToolCallMessage'), msgs));
                approvalReasons = string.empty;
                for i = 1:numel(toolCalls)
                    tc = toolCalls(i);
                    try
                        tool = nvp.Tools.select(tc.Name);
                    catch ME
                        output = "Error: " + ME.message;
                        this.print(displayMode,"[function return] " + string(jsonencode(output)));
                        this.Messages(end+1) = aisdk.LLMToolResultMessage( ...
                            string(output), ToolCallID=tc.ToolCallID, Name=tc.Name);
                        continue
                    end
                    if tool.ApprovalRequest == "once" && ismember(tc.Name, this.UserApprovedTools)
                        % Already approved in a previous round
                    elseif tool.ApprovalRequest ~= "never"
                        denialCode = aisdk.internal.MessageCatalog.getMessage( ...
                            "aisdk:agent:denialCodeUserCanceled");
                        decidedByUser = true;
                        try
                            approval = this.ApprovalFcn(tool, tc.Arguments);
                        catch ME
                            % A callback that cannot answer denies the call,
                            % leaving history resumable. The denial did not
                            % come from a human, so it is coded separately.
                            denialCode = aisdk.internal.MessageCatalog.getMessage( ...
                                "aisdk:agent:denialCodeApprovalUnavailable");
                            decidedByUser = false;
                            if strlength(ME.message) > 0
                                reason = aisdk.internal.MessageCatalog.getMessage( ...
                                    "aisdk:agent:approvalFcnFailed", ME.message);
                            else
                                reason = aisdk.internal.MessageCatalog.getMessage( ...
                                    "aisdk:agent:approvalFcnFailedNoMessage");
                            end
                            approval = struct("Approved", false, "Permanent", false, ...
                                "Reason", reason);
                        end
                        % Checked outside the guard above, so a malformed
                        % decision stops the run instead of denying the call.
                        aisdk.internal.mustBeApprovalDecision(approval);
                        if ~approval.Approved
                            denialMessage = approval.Reason;
                            if isempty(denialMessage)
                                denialMessage = "";
                            end
                            denialContent = string(jsonencode( ...
                                struct("error", denialCode, "message", denialMessage)));
                            if decidedByUser
                                lineId = "aisdk:agent:approvalDisplayDenied";
                                lineWithMessageId = "aisdk:agent:approvalDisplayDeniedWithMessage";
                            else
                                lineId = "aisdk:agent:approvalDisplayUnavailable";
                                lineWithMessageId = "aisdk:agent:approvalDisplayUnavailableWithMessage";
                            end
                            this.print(displayMode, approvalDisplayLine( ...
                                lineId, lineWithMessageId, tc.Name, denialMessage));
                            this.Messages(end+1) = aisdk.LLMToolResultMessage( ...
                                denialContent, ToolCallID=tc.ToolCallID, Name=tc.Name);
                            continue
                        end
                        % An "always" tool ignores Permanent, so the display
                        % claims permanence only where it was accumulated.
                        if approval.Permanent && tool.ApprovalRequest == "once"
                            this.UserApprovedTools(end+1) = tc.Name;
                            lineId = "aisdk:agent:approvalDisplayApprovedPermanently";
                            lineWithMessageId = "aisdk:agent:approvalDisplayApprovedPermanentlyWithMessage";
                        else
                            lineId = "aisdk:agent:approvalDisplayApproved";
                            lineWithMessageId = "aisdk:agent:approvalDisplayApprovedWithMessage";
                        end
                        this.print(displayMode, approvalDisplayLine( ...
                            lineId, lineWithMessageId, tc.Name, approval.Reason));
                        if strlength(approval.Reason) > 0
                            approvalReasons(end+1) = tc.Name + ": " + approval.Reason; %#ok<AGROW>
                        end
                    end
                    this.print(displayMode,"[call function " + tc.Name + " with inputs " + jsonencode(tc.Arguments) + "]");
                    try
                        [output, workspaceOut] = evaluate(tool, tc.Arguments, this.Workspace);
                        this.Workspace = workspaceOut;
                    catch ME
                        output = "Error: " + ME.message;
                    end
                    this.print(displayMode,"[function return] " + string(jsonencode(output)));
                    if isstring(output) || ischar(output)
                        resultStr = string(output);
                    else
                        resultStr = jsonencode(output);
                    end
                    this.Messages(end+1) = aisdk.LLMToolResultMessage(resultStr, ...
                        ToolCallID=tc.ToolCallID, Name=tc.Name);
                end
                for j = 1:numel(approvalReasons)
                    this.Messages(end+1) = aisdk.LLMTextMessage(approvalReasons(j));
                end
                this.LastInputTokens = info.Tokens.NumInputTokens;

                if isempty(toolCalls)
                    break
                end
            end

            if isempty(allTexts)
                response = "";
            else
                response = join(allTexts, newline);
            end
            if iteration == nvp.MaxIterations && ~isempty(toolCalls)
                warning("aiAgent:MaxIterationsReached", ...
                    "Tool calling loop reached maximum of %d iterations.", nvp.MaxIterations);
            end
        end

        function resetApproval(this, names)
            %resetApproval   Clear accumulated "allow from now on" approvals.
            %
            %   resetApproval(AGENT) clears every accumulated approval, so
            %   every tool whose effective policy is "once" prompts again on
            %   its next call.
            %
            %   resetApproval(AGENT, NAMES) clears only the approvals for the
            %   named tools. NAMES is a string scalar or vector. Every name
            %   must appear in the UserApprovedTools property; a name that
            %   does not is an error and no approval is cleared.

            arguments
                this  (1,1) aisdk.AIAgent
                names (1,:) string = string.empty(1,0)
            end

            % A defaulted argument does not raise nargin, so nargin is the only
            % way to tell resetApproval(agent) from resetApproval(agent, string.empty).
            if nargin < 2
                this.UserApprovedTools = string.empty(1,0);
                return
            end

            % Every name is checked before the first removal, so a rejected
            % call clears nothing.
            for i = 1:numel(names)
                if ~ismember(names(i), this.UserApprovedTools)
                    error("aisdk:agent:noApprovalToReset", ...
                        aisdk.internal.MessageCatalog.getMessage( ...
                            "aisdk:agent:noApprovalToReset", names(i)));
                end
            end

            this.UserApprovedTools = setdiff(this.UserApprovedTools, names, ...
                "stable");
        end

    end

    methods
        function value = get.ContextUsage(this)
            value = this.LastInputTokens / this.Client.ContextSize;
        end
    end

    methods (Access=private)
        function print(~, displayMode, msg)
            if displayMode == "detailed"
                if isstruct(msg)
                    disp(jsonencode(msg));
                else
                    disp(msg);
                end
            end
        end

    end


end

function line = approvalDisplayLine(lineId, lineWithMessageId, toolName, message)
if strlength(message) > 0
    line = aisdk.internal.MessageCatalog.getMessage(lineWithMessageId, ...
        toolName, message);
else
    line = aisdk.internal.MessageCatalog.getMessage(lineId, toolName);
end
end

function mustBeClient(value)
if ~isa(value, 'aisdk.client.ClientBase')
    aisdk.internal.throwError("aisdk:invalidClientType");
end
end
