classdef OpenAIResponsesClient < aisdk.client.internal.OpenAIBase
%OpenAIResponsesClient Client for the OpenAI Responses API.
%
%   CLIENT = aisdk.LLMClient("openai-responses", MODELNAME) creates an
%   OpenAIResponsesClient for the specified model.
%
%   CLIENT = aisdk.LLMClient("openai-responses", MODELNAME, Name=Value)
%   specifies options using one or more name-value arguments:
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
%   MaxNumTokens            - Maximum number of tokens in the generated response.
%                             Default value is inf.
%
%   ResponseFormat          - The format of response the model returns.
%                             "text" (default) | "json" | struct | string with JSON Schema
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
%   The Responses API has no equivalent of StopSequences, PresencePenalty,
%   FrequencyPenalty, NumCompletions or Seed. To use them, create a client
%   with aisdk.LLMClient("openai") instead.
%
%   See also aisdk.LLMClient, aisdk.client.OpenAIClient

% Copyright 2026 The MathWorks, Inc.

    properties (Constant, Hidden)
        API = "openai"
    end

    methods
        function this = OpenAIResponsesClient(modelName, nvp)
            arguments
                modelName             (1,1) string
                nvp.Temperature             {aisdk.internal.mustBeValidTemperature} = "auto"
                nvp.TopP                    {aisdk.internal.mustBeValidProbability} = "auto"
                nvp.MaxNumTokens      (1,1) {aisdk.internal.mustBePositiveIntegerOrInf} = inf
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
        end

        function [text, messages, info] = generate(this, messagesIn, nvp)
            %generate   Generate a response by calling the OpenAI Responses API.
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
                this                        (1,1) aisdk.client.OpenAIResponsesClient
                messagesIn                        {aisdk.internal.mustBeMessagesInput}
                nvp.Tools                         = []
                nvp.ToolChoice              (1,:) = "auto"
                nvp.Temperature                   {aisdk.internal.mustBeValidTemperature} = this.Temperature
                nvp.TopP                          {aisdk.internal.mustBeValidProbability} = this.TopP
                nvp.MaxNumTokens            (1,1) {aisdk.internal.mustBePositiveIntegerOrInf} = this.MaxNumTokens
                nvp.ResponseFormat                {aisdk.internal.mustBeResponseFormat} = this.ResponseFormat
                nvp.ReasoningEffort         (1,1) string {aisdk.internal.mustBeReasoningEffort} = this.ReasoningEffort
                nvp.Verbosity               (1,1) string {aisdk.internal.mustBeVerbosity} = this.Verbosity
                nvp.TimeOut                 (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = this.TimeOut
                nvp.StreamFcn                     = this.StreamFcn
            end

            [apiMessages, functionsStruct, toolChoice] = this.prepareRequest(messagesIn, nvp);

            try
                [text, outputItems, response] = aisdk.client.internal.callResponsesAPI(apiMessages, functionsStruct, ...
                    ModelName=this.ModelName, ToolChoice=toolChoice, ...
                    Temperature=nvp.Temperature, TopP=nvp.TopP, ...
                    MaxNumTokens=nvp.MaxNumTokens, ...
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

            if isempty(nvp.StreamFcn)
                this.validateResponsesReply(response);
            end

            [text, messages, info] = this.processAPIResponse(text, outputItems, response, nvp.ResponseFormat);
        end
    end

    methods (Access=protected)
        function messages = buildOutputMessages(this, ~, output)
            %buildOutputMessages Build LLMMessage objects from the Responses
            %   OUTPUT items, in order. Consecutive message items become one
            %   LLMTextMessage, and item types other than message and
            %   function_call are skipped.
            parts = {};
            pendingText = "";
            for i = 1:numel(output)
                item = output{i};
                if ~isstruct(item) || ~isfield(item, "type")
                    continue
                end
                switch string(item.type)
                    case "message"
                        pendingText = pendingText + aisdk.client.internal.outputMessageText(item);
                    case "function_call"
                        parts = appendTextMessage(parts, pendingText);
                        pendingText = "";
                        parts{end+1} = this.toolCallMessage(item.name, ...
                            functionCallArguments(item), functionCallID(item)); %#ok<AGROW>
                end
            end
            parts = appendTextMessage(parts, pendingText);
            if isempty(parts)
                messages = aisdk.LLMTextMessage("", Role="assistant");
            else
                messages = [parts{:}];
            end
        end

        function toolStruct = encodeTool(this, tool)
            %encodeTool Encode an LLMTool in the flat Responses function-tool format.
            toolStruct = encodeTool@aisdk.client.ClientBase(this, tool);
            funcStruct = toolStruct.function;
            toolStruct = struct("type", "function", ...
                "name", funcStruct.name, ...
                "description", funcStruct.description, ...
                "parameters", funcStruct.parameters);
        end

        function toolChoice = convertToolChoice(this, toolChoice, functionNames)
            %convertToolChoice Convert the tool choice to the flat Responses format.
            toolChoice = convertToolChoice@aisdk.client.ClientBase(this, toolChoice, functionNames);
            if isstruct(toolChoice)
                toolChoice = struct("type", "function", "name", toolChoice.function.name);
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
                            "type", "function_call_output", ...
                            "call_id", msg.ToolCallID, ...
                            "output", msg.Result);

                    case 'aisdk.LLMImageMessage'
                        imgPart = struct("type", "input_image", ...
                            "image_url", this.imageDataURI(msg), "detail", msg.Detail);
                        idx = idx + 1;
                        messagesOut{idx} = struct("role", msg.Role, "content", {{imgPart}});

                    case 'aisdk.LLMToolCallMessage'
                        idx = idx + 1;
                        messagesOut{idx} = struct( ...
                            "type", "function_call", ...
                            "call_id", msg.ToolCallID, ...
                            "name", msg.Name, ...
                            "arguments", jsonencode(msg.Arguments));

                end
            end
            messagesOut = messagesOut(1:idx);
        end

        function validateResponsesReply(this, response)
            %validateResponsesReply Error if an OK response body reports a failed
            %   response or has no readable Responses output.
            data = response.Body.Data;
            if response.StatusCode ~= "OK"
                return
            end
            if isstruct(data) && isscalar(data) && isfield(data, "status") && string(data.status) == "failed"
                err = this.extractErrorMessage(data);
                if isempty(err)
                    err = string(jsonencode(data));
                end
                aisdk.internal.throwError("aisdk:apiReturnedError", err);
            end
            if hasReadableOutput(data)
                return
            end
            if isstruct(data) && isfield(data, "choices")
                aisdk.internal.throwError("aisdk:responseIsChatCompletions", this.BaseURL);
            end
            aisdk.internal.throwError("aisdk:unreadableResponse", this.BaseURL);
        end

        function path = endpointPath(~)
            path = "responses";
        end

        function usage = parseUsage(~, response)
            data = response.Body.Data;
            inputTokens = 0;
            outputTokens = 0;
            totalTokens = 0;
            cachedInputTokens = 0;
            if isfield(data, "usage") && isfield(data.usage, "input_tokens")
                u = data.usage;
                inputTokens = u.input_tokens;
                outputTokens = u.output_tokens;
                if isfield(u, "total_tokens")
                    totalTokens = u.total_tokens;
                else
                    totalTokens = inputTokens + outputTokens;
                end
                if isfield(u, "input_tokens_details") && isfield(u.input_tokens_details, "cached_tokens")
                    cachedInputTokens = u.input_tokens_details.cached_tokens;
                end
            end
            usage = struct("NumInputTokens", inputTokens, "NumOutputTokens", outputTokens, ...
                "NumTotalTokens", totalTokens, "NumCachedInputTokens", cachedInputTokens);
        end
    end

end

function tf = hasReadableOutput(data)
    % True when DATA has an "output" array whose items all carry a "type".
    tf = isstruct(data) && isscalar(data) && isfield(data, "output");
    if ~tf || isempty(data.output)
        return
    end
    output = data.output;
    if isstruct(output)
        tf = isfield(output, "type");
    elseif iscell(output)
        tf = all(cellfun(@(item) isstruct(item) && isscalar(item) && isfield(item, "type"), output));
    else
        tf = false;
    end
end

function parts = appendTextMessage(parts, text)
    if strlength(text) > 0
        parts{end+1} = aisdk.LLMTextMessage(text, Role="assistant");
    end
end

function id = functionCallID(item)
    if isfield(item, "call_id")
        id = string(item.call_id);
    else
        id = "";
    end
end

function args = functionCallArguments(item)
    % A call taking no arguments may report them as an empty string or omit the field.
    if isfield(item, "arguments")
        args = item.arguments;
    else
        args = "";
    end
end
