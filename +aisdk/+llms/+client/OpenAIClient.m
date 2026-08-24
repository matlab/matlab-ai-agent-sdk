classdef OpenAIClient < aisdk.llms.client.ClientBase
%OpenAIClient Client for OpenAI chat completions.
%
%   CLIENT = aisdk.llms.client.OpenAIClient(MODELNAME) creates an OpenAIClient
%   for the specified model.
%
%   CLIENT = aisdk.llms.client.OpenAIClient(MODELNAME, Name=Value) specifies options using
%   one or more name-value arguments:
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

% Copyright 2026 The MathWorks, Inc.

    properties (Constant)
        API = "openai"
    end

    properties
        %ResponseFormat   Response format, "text" or "json" or struct or JSON schema string.
        ResponseFormat      {aisdk.llms.internal.mustBeResponseFormat} = "text"

        %ReasoningEffort   Reasoning effort level for reasoning models.
        ReasoningEffort (1,1) string {aisdk.llms.internal.mustBeReasoningEffort} = "auto"

        %Verbosity   Verbosity level for the model output.
        Verbosity       (1,1) string {aisdk.llms.internal.mustBeVerbosity} = "auto"

        %Temperature   Temperature of generation.
        Temperature         {aisdk.llms.internal.mustBeValidTemperature} = "auto"

        %TopP   Top probability mass to consider for generation.
        TopP                {aisdk.llms.internal.mustBeValidProbability} = "auto"

        %StopSequences   Sequences to stop the generation of tokens.
        StopSequences       {aisdk.llms.internal.mustBeValidStop} = []

        %MaxNumTokens   Maximum number of tokens in the generated response.
        MaxNumTokens  (1,1) {mustBeNumeric,mustBePositive} = inf

        %PresencePenalty   Penalty for using a token that has already been used.
        PresencePenalty     {aisdk.llms.internal.mustBeValidPenalty} = "auto"

        %FrequencyPenalty   Penalty for using a token that is frequent in the training data.
        FrequencyPenalty    {aisdk.llms.internal.mustBeValidPenalty} = "auto"

        %TimeOut   Connection timeout in seconds.
        TimeOut       (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = 120

        %StreamFcn   Function to callback when streaming.
        StreamFcn
    end

    methods
        function this = OpenAIClient(modelName, nvp)
            arguments
                modelName             (1,1) string
                nvp.Temperature             {aisdk.llms.internal.mustBeValidTemperature} = "auto"
                nvp.TopP                    {aisdk.llms.internal.mustBeValidProbability} = "auto"
                nvp.StopSequences           {aisdk.llms.internal.mustBeValidStop} = []
                nvp.MaxNumTokens      (1,1) {mustBeNumeric,mustBePositive} = inf
                nvp.PresencePenalty         {aisdk.llms.internal.mustBeValidPenalty} = "auto"
                nvp.FrequencyPenalty        {aisdk.llms.internal.mustBeValidPenalty} = "auto"
                nvp.ResponseFormat          {aisdk.llms.internal.mustBeResponseFormat} = "text"
                nvp.ReasoningEffort   (1,1) string {aisdk.llms.internal.mustBeReasoningEffort} = "auto"
                nvp.Verbosity         (1,1) string {aisdk.llms.internal.mustBeVerbosity} = "auto"
                nvp.TimeOut           (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = 120
                nvp.StreamFcn         (1,1) {mustBeA(nvp.StreamFcn,'function_handle')}
                nvp.APIKey                  {aisdk.llms.internal.mustBeNonzeroLengthTextScalar}
                nvp.BaseURL           (1,1) string = ""
                nvp.ContextSize       (1,1) {aisdk.llms.internal.mustBePositiveIntegerOrNaN} = NaN
            end

            this.ModelName = modelName;
            this.APIKey = this.parseAPIKey(nvp);
            this.BaseURL = this.parseEndpoint(nvp);
            this.ContextSize = nvp.ContextSize;

            this.Temperature = nvp.Temperature;
            this.TopP = nvp.TopP;
            this.StopSequences = nvp.StopSequences;
            this.MaxNumTokens = nvp.MaxNumTokens;
            this.PresencePenalty = nvp.PresencePenalty;
            this.FrequencyPenalty = nvp.FrequencyPenalty;
            this.ResponseFormat = nvp.ResponseFormat;
            this.ReasoningEffort = nvp.ReasoningEffort;
            this.Verbosity = nvp.Verbosity;
            this.TimeOut = nvp.TimeOut;

            if isfield(nvp, "StreamFcn")
                this.StreamFcn = nvp.StreamFcn;
            else
                this.StreamFcn = [];
            end
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
            %   be a string or an array of aisdk.llms.message.LLMMessage objects.
            %
            %   [TEXT, MESSAGES] = generate(__, Tools=TOOLS) specifies
            %   tools as aisdk.llms.tool.LLMTool objects or a pre-converted cell/struct.
            %
            %   [TEXT, MESSAGES] = generate(__, ToolChoice=CHOICE) specifies
            %   the tool choice setting.

            arguments
                this                        (1,1) aisdk.llms.client.OpenAIClient
                messagesIn                        {aisdk.llms.internal.mustBeMessagesInput}
                nvp.Tools                         = []
                nvp.ToolChoice              (1,:) = "auto"
                nvp.Temperature                   {aisdk.llms.internal.mustBeValidTemperature} = this.Temperature
                nvp.TopP                          {aisdk.llms.internal.mustBeValidProbability} = this.TopP
                nvp.StopSequences                 {aisdk.llms.internal.mustBeValidStop} = this.StopSequences
                nvp.MaxNumTokens            (1,1) {mustBeNumeric,mustBePositive} = this.MaxNumTokens
                nvp.PresencePenalty                {aisdk.llms.internal.mustBeValidPenalty} = this.PresencePenalty
                nvp.FrequencyPenalty               {aisdk.llms.internal.mustBeValidPenalty} = this.FrequencyPenalty
                nvp.NumCompletions          (1,1) {mustBeNumeric,mustBePositive,mustBeInteger} = 1
                nvp.Seed                          {mustBeNumeric} = []
                nvp.ResponseFormat                {aisdk.llms.internal.mustBeResponseFormat} = this.ResponseFormat
                nvp.ReasoningEffort         (1,1) string {aisdk.llms.internal.mustBeReasoningEffort} = this.ReasoningEffort
                nvp.Verbosity               (1,1) string {aisdk.llms.internal.mustBeVerbosity} = this.Verbosity
                nvp.TimeOut                 (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = this.TimeOut
                nvp.StreamFcn                     = this.StreamFcn
            end

            messagesIn = aisdk.llms.client.ClientBase.normalizeMessages(messagesIn);
            [functionsStruct, functionNames] = this.convertToolsWithNames(nvp.Tools);

            aisdk.llms.client.ClientBase.validateToolChoice(nvp.ToolChoice, functionNames);
            toolChoice = aisdk.llms.client.ClientBase.convertToolChoice(nvp.ToolChoice, functionNames);

            apiMessages = this.convertMessages(messagesIn);

            try
                [text, messageBody, response] = aisdk.llms.client.internal.callOpenAIChatAPI(apiMessages, functionsStruct, ...
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
                    error(ME.identifier, ME.message);
                end
                throw(ME);
            end

            this.handleErrorResponse(response);

            if ~isempty(text)
                text = aisdk.llms.client.internal.reformatOutput(text, nvp.ResponseFormat);
            end

            info = struct("Tokens", parseUsage(response));

            if isfield(messageBody, "tool_calls")
                toolCalls = messageBody.tool_calls;
                if iscell(toolCalls)
                    toolCalls = [toolCalls{:}];
                end
                messages = aisdk.LLMToolCallMessage.empty(1,0);
                for i = 1:numel(toolCalls)
                    tc = toolCalls(i);
                    if isfield(tc, "id")
                        id = string(tc.id);
                    else
                        id = "";
                    end
                    args = jsondecode(tc.function.arguments);
                    if ~isstruct(args)
                        error("llms:invalidToolCallArguments", ...
                            aisdk.llms.internal.MessageCatalog.getMessage("llms:invalidToolCallArguments", class(args)));
                    end
                    messages(end+1) = aisdk.LLMToolCallMessage(tc.function.name, args, ToolCallID=id); %#ok<AGROW>
                end
            else
                messages = aisdk.LLMTextMessage(messageBody.content, Role="assistant");
            end
        end

    end

    methods (Access=protected)
        function messagesOut = convertMessages(~, messages)
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
                        imgData = msg.Image;
                        base64Str = matlab.net.base64encode(aisdk.llms.internal.encodeImageToPNG(imgData));
                        dataURI = "data:image/png;base64," + base64Str;
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

        function endpoint = parseEndpoint(this, nvp)
            envVarName = upper(this.API) + "_API_ENDPOINT";
            if isfield(nvp, "BaseURL") && strlength(nvp.BaseURL) > 0
                endpoint = nvp.BaseURL;
            elseif isenv(envVarName)
                endpoint = getenv(envVarName);
            else
                endpoint = "https://api.openai.com/v1/";
            end
            if ~endsWith(endpoint, "/")
                endpoint = endpoint + "/";
            end
            endpoint = endpoint + "chat/completions";
        end

        function err = extractErrorMessage(~, data)
            if isfield(data, "error") && isstruct(data.error) && isfield(data.error, "message")
                err = string(data.error.message);
            else
                err = string.empty;
            end
        end
    end

end

function usage = parseUsage(response)
    data = response.Body.Data;
    if isfield(data, "usage")
        u = data.usage;
        inputTokens = u.prompt_tokens;
        outputTokens = u.completion_tokens;
        totalTokens = u.total_tokens;
        if isfield(u, "prompt_tokens_details") && isfield(u.prompt_tokens_details, "cached_tokens")
            cachedInputTokens = u.prompt_tokens_details.cached_tokens;
        else
            cachedInputTokens = 0;
        end
    else
        inputTokens = 0;
        outputTokens = 0;
        totalTokens = 0;
        cachedInputTokens = 0;
    end
    usage = struct("NumInputTokens", inputTokens, "NumOutputTokens", outputTokens, ...
        "NumTotalTokens", totalTokens, "NumCachedInputTokens", cachedInputTokens);
end
