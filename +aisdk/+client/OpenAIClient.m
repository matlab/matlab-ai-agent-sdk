classdef OpenAIClient < aisdk.client.internal.OpenAIBase
%OpenAIClient Client for OpenAI chat completions.
%
%   CLIENT = aisdk.LLMClient("openai", MODELNAME) creates an OpenAIClient
%   for the specified model.
%
%   CLIENT = aisdk.LLMClient("openai", MODELNAME, Name=Value) specifies
%   options using one or more name-value arguments:
%
%   Temperature             - Temperature value for controlling the randomness
%                             of the output. Default value is 1.
%                             Higher values increase the randomness (in some
%                             sense, the "creativity") of outputs, lower
%                             values reduce it. Setting Temperature=0 removes
%                             randomness from the output altogether.
%
%   TopP                    - Top probability mass value for controlling the
%                             diversity of the output. Default value is 1;
%                             lower values imply that only the more likely
%                             words can appear in any particular place.
%                             This is also known as top-p sampling.
%
%   StopSequences           - Vector of strings that when encountered, will
%                             stop the generation of tokens. Default
%                             value is empty.
%                             Example: ["The end.", "And that's all she wrote."]
%
%   MaxNumTokens            - Maximum number of tokens in the generated response.
%                             Default value is inf.
%
%   ResponseFormat          - The format of response the model returns.
%                             "text" (default) | "json" | struct | string with JSON Schema
%
%   PresencePenalty         - Penalty value for using a token in the response
%                             that has already been used. Default value is 0.
%                             Higher values reduce repetition of words in the output.
%
%   FrequencyPenalty        - Penalty value for using a token that is frequent
%                             in the output. Default value is 0.
%                             Higher values reduce repetition of words in the output.
%
%   APIKey                  - API key for OpenAI. If omitted, reads from
%                             OPENAI_API_KEY environment variable.
%
%   ReasoningEffort         - Reasoning effort level for reasoning models.
%                             "auto" (default) | "none" | "minimal" | "low"
%                             | "medium" | "high" | "xhigh"
%                             Only included in the API call when not "auto".
%
%   Verbosity               - Verbosity level for model output.
%                             "auto" (default) | "low" | "medium" | "high"
%                             Only included in the API call when not "auto".
%
%   StreamFcn               - Function to callback when streaming the result.
%
%   TimeOut                 - Connection Timeout in seconds. Default is 120.
%
%   BaseURL                 - OpenAI API endpoint. If omitted, reads from
%                             OPENAI_API_ENDPOINT environment variable, or defaults
%                             to "https://api.openai.com/v1/".
%
%   See also aisdk.LLMClient, aisdk.client.OpenAIResponsesClient

% Copyright 2026 The MathWorks, Inc.

    properties (Constant, Hidden)
        API = "openai"
    end

    properties
        %StopSequences   Sequences to stop the generation of tokens.
        StopSequences       {aisdk.internal.mustBeValidStop} = []

        %PresencePenalty   Penalty for using a token that has already been used.
        PresencePenalty     {aisdk.internal.mustBeValidPenalty} = "auto"

        %FrequencyPenalty   Penalty for using a token that is frequent in the training data.
        FrequencyPenalty    {aisdk.internal.mustBeValidPenalty} = "auto"
    end

    methods
        function this = OpenAIClient(modelName, nvp)
            arguments
                modelName             (1,1) string
                nvp.Temperature             {aisdk.internal.mustBeValidTemperature} = "auto"
                nvp.TopP                    {aisdk.internal.mustBeValidProbability} = "auto"
                nvp.StopSequences           {aisdk.internal.mustBeValidStop} = []
                nvp.MaxNumTokens      (1,1) {aisdk.internal.mustBePositiveIntegerOrInf} = inf
                nvp.PresencePenalty         {aisdk.internal.mustBeValidPenalty} = "auto"
                nvp.FrequencyPenalty        {aisdk.internal.mustBeValidPenalty} = "auto"
                nvp.ResponseFormat          {aisdk.internal.mustBeResponseFormat} = "text"
                nvp.ReasoningEffort   (1,1) string {aisdk.internal.mustBeReasoningEffort} = "auto"
                nvp.Verbosity         (1,1) string {aisdk.internal.mustBeVerbosity} = "auto"
                nvp.TimeOut           (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = 120
                nvp.StreamFcn         (1,1) {mustBeA(nvp.StreamFcn,'function_handle')}
                nvp.APIKey                  {aisdk.internal.mustBeNonzeroLengthTextScalar}
                nvp.BaseURL           (1,1) string = ""
                nvp.ContextSize       (1,1) {aisdk.internal.mustBePositiveIntegerOrNaN} = NaN
            end

            this@aisdk.client.internal.OpenAIBase(modelName, nvp);
            this.StopSequences = nvp.StopSequences;
            this.PresencePenalty = nvp.PresencePenalty;
            this.FrequencyPenalty = nvp.FrequencyPenalty;
        end

        function this = set.StopSequences(this, value)
            if isempty(value)
                this.StopSequences = [];
            else
                this.StopSequences = string(value);
            end
        end

        function [text, messages, info] = generate(this, messagesIn, nvp)
            %generate   Generate a response by calling the OpenAI chat completion API.
            %
            %   [TEXT, MESSAGES] = generate(CLIENT, MESSAGESIN)
            %   generates a response with the specified MESSAGESIN, which can
            %   be a string or an array of aisdk.message.LLMMessage objects.
            %
            %   [TEXT, MESSAGES] = generate(__, Tools=TOOLS) specifies
            %   tools as aisdk.tool.LLMTool objects or a pre-converted cell/struct.
            %
            %   [TEXT, MESSAGES] = generate(__, ToolChoice=CHOICE) specifies
            %   the tool choice setting.

            arguments
                this                        (1,1) aisdk.client.OpenAIClient
                messagesIn                        {aisdk.internal.mustBeMessagesInput}
                nvp.Tools                         = []
                nvp.ToolChoice              (1,:) = "auto"
                nvp.Temperature                   {aisdk.internal.mustBeValidTemperature} = this.Temperature
                nvp.TopP                          {aisdk.internal.mustBeValidProbability} = this.TopP
                nvp.StopSequences                 {aisdk.internal.mustBeValidStop} = this.StopSequences
                nvp.MaxNumTokens            (1,1) {aisdk.internal.mustBePositiveIntegerOrInf} = this.MaxNumTokens
                nvp.PresencePenalty                {aisdk.internal.mustBeValidPenalty} = this.PresencePenalty
                nvp.FrequencyPenalty               {aisdk.internal.mustBeValidPenalty} = this.FrequencyPenalty
                nvp.NumCompletions          (1,1) {mustBeNumeric,mustBePositive,mustBeInteger} = 1
                nvp.Seed                          {mustBeNumeric} = []
                nvp.ResponseFormat                {aisdk.internal.mustBeResponseFormat} = this.ResponseFormat
                nvp.ReasoningEffort         (1,1) string {aisdk.internal.mustBeReasoningEffort} = this.ReasoningEffort
                nvp.Verbosity               (1,1) string {aisdk.internal.mustBeVerbosity} = this.Verbosity
                nvp.TimeOut                 (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = this.TimeOut
                nvp.StreamFcn                     = this.StreamFcn
            end

            [apiMessages, functionsStruct, toolChoice] = this.prepareRequest(messagesIn, nvp);

            try
                [text, messageBody, response] = aisdk.client.internal.callChatCompletionsAPI(apiMessages, functionsStruct, ...
                    ModelName=this.ModelName, ToolChoice=toolChoice, ...
                    Temperature=nvp.Temperature, ...
                    TopP=nvp.TopP, ...
                    StopSequences=nvp.StopSequences, MaxNumTokens=nvp.MaxNumTokens, ...
                    PresencePenalty=nvp.PresencePenalty, FrequencyPenalty=nvp.FrequencyPenalty, ...
                    NumCompletions=nvp.NumCompletions, Seed=nvp.Seed, ...
                    ResponseFormat=nvp.ResponseFormat, ...
                    ReasoningEffort=nvp.ReasoningEffort, Verbosity=nvp.Verbosity, ...
                    APIKey=this.APIKey, TimeOut=nvp.TimeOut, StreamFcn=nvp.StreamFcn, ...
                    sendRequestFcn=this.sendRequestFcn, Endpoint=this.BaseURL);
            catch ME
                if ismember(ME.identifier, ...
                    ["MATLAB:webservices:UnknownHost","MATLAB:webservices:Timeout"])
                    % Report the plain connection problem, without the chain
                    % of causes from inside the web services stack.
                    error(ME.identifier, "%s", ME.message);
                end
                throw(ME);
            end

            [text, messages, info] = this.processAPIResponse(text, messageBody, response, nvp.ResponseFormat);
        end

    end

    methods (Access=protected)
        function messages = buildOutputMessages(this, text, message)
            %buildOutputMessages Build LLMMessage objects from a Chat Completions
            %   assistant MESSAGE. TEXT that accompanies tool calls comes first.
            if ~isfield(message, "tool_calls")
                messages = aisdk.LLMTextMessage(message.content, Role="assistant");
                return
            end
            toolCalls = message.tool_calls;
            messages = aisdk.LLMToolCallMessage.empty(1,0);
            for i = 1:numel(toolCalls)
                tc = toolCalls{i};
                if isfield(tc, "id")
                    id = string(tc.id);
                else
                    id = "";
                end
                messages(end+1) = this.toolCallMessage(tc.function.name, tc.function.arguments, id); %#ok<AGROW>
            end
            if strlength(text) > 0
                messages = [aisdk.LLMTextMessage(text, Role="assistant"), messages];
            end
        end

        function messagesOut = convertMessages(this, messages)
            messagesOut = cell(1, numel(messages));
            idx = 0;
            for i = 1:numel(messages)
                msg = messages(i);
                switch class(msg)
                    case 'aisdk.LLMTextMessage'
                        role = msg.Role;
                        if role == "system"
                            role = "developer";
                        end
                        idx = idx + 1;
                        messagesOut{idx} = struct("role", role, "content", msg.Text);

                    case 'aisdk.LLMToolResultMessage'
                        idx = idx + 1;
                        messagesOut{idx} = struct( ...
                            "role", "tool", ...
                            "tool_call_id", msg.ToolCallID, ...
                            "name", msg.Name, ...
                            "content", msg.Result);

                    case 'aisdk.LLMImageMessage'
                        dataURI = this.imageDataURI(msg);
                        imgPart = struct("type", "image_url", ...
                            "image_url", struct("url", dataURI, "detail", msg.Detail));
                        idx = idx + 1;
                        messagesOut{idx} = struct("role", msg.Role, "content", {{imgPart}});

                    case 'aisdk.LLMToolCallMessage'
                        toolCall = struct( ...
                            "id", msg.ToolCallID, ...
                            "type", "function", ...
                            "function", struct("name", msg.Name, "arguments", jsonencode(msg.Arguments)));
                        % Merge into preceding assistant message if possible
                        if idx > 0 && isfield(messagesOut{idx}, "role") && messagesOut{idx}.role == "assistant"
                            if isfield(messagesOut{idx}, "tool_calls")
                                if iscell(messagesOut{idx}.tool_calls)
                                    messagesOut{idx}.tool_calls{end+1} = toolCall;
                                else
                                    messagesOut{idx}.tool_calls = [messagesOut{idx}.tool_calls; toolCall];
                                end
                            else
                                messagesOut{idx}.tool_calls = {toolCall};
                            end
                        else
                            idx = idx + 1;
                            messagesOut{idx} = struct("role", "assistant", "content", "", "tool_calls", []);
                            messagesOut{idx}.tool_calls = {toolCall};
                        end

                end
            end
            messagesOut = messagesOut(1:idx);
        end

        function path = endpointPath(~)
            path = "chat/completions";
        end

        function usage = parseUsage(~, response)
            data = response.Body.Data;
            inputTokens = 0;
            outputTokens = 0;
            totalTokens = 0;
            cachedInputTokens = 0;
            if isfield(data, "usage") && isfield(data.usage, "prompt_tokens")
                u = data.usage;
                inputTokens = u.prompt_tokens;
                outputTokens = u.completion_tokens;
                totalTokens = u.total_tokens;
                if isfield(u, "prompt_tokens_details") && isfield(u.prompt_tokens_details, "cached_tokens")
                    cachedInputTokens = u.prompt_tokens_details.cached_tokens;
                end
            end
            usage = struct("NumInputTokens", inputTokens, "NumOutputTokens", outputTokens, ...
                "NumTotalTokens", totalTokens, "NumCachedInputTokens", cachedInputTokens);
        end
    end

end
