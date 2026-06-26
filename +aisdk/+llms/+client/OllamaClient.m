classdef OllamaClient < aisdk.llms.client.ClientBase
%OllamaClient Client for Ollama chat completions.
%
%   CLIENT = aisdk.llms.client.OllamaClient(MODELNAME) creates an OllamaClient
%   for the specified model.
%
%   CLIENT = aisdk.llms.client.OllamaClient(MODELNAME, Name=Value) specifies options using
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
%   MinP                    - Minimum probability ratio for controlling the
%                             diversity of the output. Default value is 0;
%                             higher values imply that only the more likely
%                             words can appear in any particular place.
%                             This is also known as min-p sampling.
%
%   TopK                    - Maximum number of most likely tokens that are
%                             considered for output. Default is Inf, allowing
%                             all tokens. Smaller values reduce diversity in
%                             the output.
%
%   TailFreeSamplingZ       - Reduce the use of less probable tokens, based on
%                             the second-order differences of ordered
%                             probabilities. Default value is 1, disabling
%                             tail-free sampling. Lower values reduce
%                             diversity, with some authors recommending
%                             values around 0.95. Tail-free sampling is
%                             slower than using TopP or TopK.
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
%   StreamFcn               - Function to callback when streaming the result.
%
%   TimeOut                 - Connection Timeout in seconds. Default is 120.
%
%   APIKey                  - API key for authentication. If omitted, reads from
%                             OLLAMA_API_KEY environment variable.
%
%   BaseURL                 - Ollama server endpoint. If omitted, reads from
%                             OLLAMA_API_ENDPOINT environment variable, or defaults
%                             to "http://127.0.0.1:11434".
%

% Copyright 2026 The MathWorks, Inc.

    properties (Constant)
        API = "ollama"
    end

    properties
        %ResponseFormat   Response format, "text" or "json" or struct or JSON schema string.
        ResponseFormat      {aisdk.llms.internal.mustBeResponseFormat} = "text"

        %Temperature   Temperature of generation.
        Temperature         {aisdk.llms.internal.mustBeValidTemperature} = "auto"

        %TopP   Top probability mass to consider for generation.
        TopP                {aisdk.llms.internal.mustBeValidProbability} = "auto"

        %MinP   Minimum probability ratio to consider for generation.
        MinP                {aisdk.llms.internal.mustBeValidProbability} = "auto"

        %TopK   Maximum number of most likely tokens considered for output.
        TopK                {aisdk.llms.internal.mustBeValidTopK} = "auto"

        %TailFreeSamplingZ   Tail-free sampling parameter.
        TailFreeSamplingZ   {aisdk.llms.internal.mustBeValidTailFreeSamplingZ} = "auto"

        %StopSequences   Sequences to stop the generation of tokens.
        StopSequences       {aisdk.llms.internal.mustBeValidStop} = []

        %MaxNumTokens   Maximum number of tokens in the generated response.
        MaxNumTokens  (1,1) {mustBeNumeric,mustBePositive} = inf

        %TimeOut   Connection timeout in seconds.
        TimeOut       (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = 120

        %StreamFcn   Function to callback when streaming.
        StreamFcn
    end

    methods
        function this = OllamaClient(modelName, nvp)
            arguments
                modelName             (1,1) string
                nvp.Temperature             {aisdk.llms.internal.mustBeValidTemperature} = "auto"
                nvp.TopP                    {aisdk.llms.internal.mustBeValidProbability} = "auto"
                nvp.MinP                    {aisdk.llms.internal.mustBeValidProbability} = "auto"
                nvp.TopK                    {aisdk.llms.internal.mustBeValidTopK} = "auto"
                nvp.TailFreeSamplingZ       {aisdk.llms.internal.mustBeValidTailFreeSamplingZ} = "auto"
                nvp.StopSequences           {aisdk.llms.internal.mustBeValidStop} = []
                nvp.MaxNumTokens      (1,1) {mustBeNumeric,mustBePositive} = inf
                nvp.ResponseFormat          {aisdk.llms.internal.mustBeResponseFormat} = "text"
                nvp.TimeOut           (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = 120
                nvp.StreamFcn         (1,1) {mustBeA(nvp.StreamFcn,'function_handle')}
                nvp.APIKey                  {aisdk.llms.internal.mustBeNonzeroLengthTextScalar}
                nvp.BaseURL           (1,1) string = ""
            end

            this.ModelName = modelName;
            this.APIKey = this.parseAPIKey(nvp);
            this.BaseURL = this.parseEndpoint(nvp);

            this.Temperature = nvp.Temperature;
            this.TopP = nvp.TopP;
            this.MinP = nvp.MinP;
            this.TopK = nvp.TopK;
            this.TailFreeSamplingZ = nvp.TailFreeSamplingZ;
            this.StopSequences = nvp.StopSequences;
            this.MaxNumTokens = nvp.MaxNumTokens;
            this.ResponseFormat = nvp.ResponseFormat;
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
            %generate   Generate a response by calling the Ollama chat completion API.
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
                this                        (1,1) aisdk.llms.client.OllamaClient
                messagesIn                        {aisdk.llms.internal.mustBeMessagesInput}
                nvp.Tools                         = []
                nvp.ToolChoice              (1,:) = "auto"
                nvp.Temperature                   {aisdk.llms.internal.mustBeValidTemperature} = this.Temperature
                nvp.TopP                          {aisdk.llms.internal.mustBeValidProbability} = this.TopP
                nvp.MinP                          {aisdk.llms.internal.mustBeValidProbability} = this.MinP
                nvp.TopK                          {aisdk.llms.internal.mustBeValidTopK} = this.TopK
                nvp.TailFreeSamplingZ             {aisdk.llms.internal.mustBeValidTailFreeSamplingZ} = this.TailFreeSamplingZ
                nvp.StopSequences                 {aisdk.llms.internal.mustBeValidStop} = this.StopSequences
                nvp.MaxNumTokens            (1,1) {mustBeNumeric,mustBePositive} = this.MaxNumTokens
                nvp.Seed                          {mustBeNumeric} = []
                nvp.ResponseFormat                {aisdk.llms.internal.mustBeResponseFormat} = this.ResponseFormat
                nvp.TimeOut                 (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = this.TimeOut
                nvp.StreamFcn                     = this.StreamFcn
            end

            messagesIn = aisdk.llms.client.ClientBase.normalizeMessages(messagesIn);
            [functionsStruct, ~] = this.convertToolsWithNames(nvp.Tools);

            apiMessages = this.convertMessages(messagesIn);

            try
                [text, message, response] = aisdk.llms.client.internal.callOllamaChatAPI(...
                    this.ModelName, apiMessages, functionsStruct, ...
                    Temperature=nvp.Temperature, ...
                    TopP=nvp.TopP, MinP=nvp.MinP, TopK=nvp.TopK, ...
                    TailFreeSamplingZ=nvp.TailFreeSamplingZ, ...
                    StopSequences=nvp.StopSequences, MaxNumTokens=nvp.MaxNumTokens, ...
                    Seed=nvp.Seed, ResponseFormat=nvp.ResponseFormat, ...
                    TimeOut=nvp.TimeOut, StreamFcn=nvp.StreamFcn, ...
                    Endpoint=this.BaseURL, sendRequestFcn=this.sendRequestFcn);
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

            if isfield(message, "tool_calls")
                toolCalls = message.tool_calls;
                if iscell(toolCalls)
                    toolCalls = [toolCalls{:}];
                end
                messages = aisdk.LLMToolCallMessage.empty(1,0);
                for i = 1:numel(toolCalls)
                    tc = toolCalls(i).function;
                    if isfield(tc, "index")
                        % index is always numeric when present
                        id = string(tc.index);
                    else
                        id = "";
                    end
                    if isstring(tc.arguments) || ischar(tc.arguments)
                        args = jsondecode(tc.arguments);
                    else
                        args = tc.arguments;
                    end
                    if ~isstruct(args)
                        error("llms:invalidToolCallArguments", ...
                            aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:invalidToolCallArguments", class(args)));
                    end
                    messages(end+1) = aisdk.LLMToolCallMessage(tc.name, args, ToolCallID=id); %#ok<AGROW>
                end
            else
                messages = aisdk.LLMTextMessage(message.content, Role="assistant");
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
                        idx = idx + 1;
                        messagesOut{idx} = struct("role", msg.Role, "content", msg.Content);

                    case 'aisdk.LLMToolResultMessage'
                        idx = idx + 1;
                        messagesOut{idx} = struct( ...
                            "role", "tool", ...
                            "tool_call_id", msg.ToolCallID, ...
                            "tool_name", msg.Name, ...
                            "content", msg.Content);

                    case 'aisdk.LLMImageMessage'
                        imgData = msg.Content;
                        base64Str = matlab.net.base64encode(aisdk.llms.internal.encodeImageToPNG(imgData));
                        idx = idx + 1;
                        messagesOut{idx} = struct("role", msg.Role, "content", "", "images", {{base64Str}});

                    case 'aisdk.LLMToolCallMessage'
                        toolCall = struct( ...
                            "id", msg.ToolCallID, ...
                            "type", "function", ...
                            "function", struct("name", msg.Name, "arguments", msg.Arguments));
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
                endpoint = "http://127.0.0.1:11434";
            end
            if ~endsWith(endpoint, "/")
                endpoint = endpoint + "/";
            end
            endpoint = endpoint + "api/chat";
        end

        function err = extractErrorMessage(~, data)
            if isfield(data, "error") && (ischar(data.error) || isstring(data.error))
                err = string(data.error);
            else
                err = string.empty;
            end
        end
    end

end

function usage = parseUsage(response)
    data = response.Body.Data;
    if iscell(data)
        data = data{1};
    end
    inputTokens = 0;
    outputTokens = 0;
    if isfield(data, "prompt_eval_count")
        inputTokens = data.prompt_eval_count;
    end
    if isfield(data, "eval_count")
        outputTokens = data.eval_count;
    end
    usage = struct("NumInputTokens", inputTokens, "NumOutputTokens", outputTokens, ...
        "NumTotalTokens", inputTokens + outputTokens, "NumCachedInputTokens", 0);
end
