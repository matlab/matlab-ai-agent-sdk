classdef (Abstract) OpenAIBase < aisdk.client.ClientBase
% This class is undocumented and will change in a future release

%OpenAIBase Shared implementation of the OpenAI clients.
%
%   Holds the logic that does not depend on the wire format: endpoint
%   resolution, request preparation, error extraction and the properties
%   both OpenAI clients support. Subclasses declare their API-specific
%   properties, their own generate method and how LLMMessage objects are
%   built from their output.

% Copyright 2026 The MathWorks, Inc.

    properties
        %ResponseFormat   Response format, "text" or "json" or struct or JSON schema string.
        ResponseFormat      {aisdk.internal.mustBeResponseFormat} = "text"

        %ReasoningEffort   Reasoning effort level for reasoning models.
        ReasoningEffort (1,1) string {aisdk.internal.mustBeReasoningEffort} = "auto"

        %Verbosity   Verbosity level for the model output.
        Verbosity       (1,1) string {aisdk.internal.mustBeVerbosity} = "auto"

        %Temperature   Temperature of generation.
        Temperature         {aisdk.internal.mustBeValidTemperature} = "auto"

        %TopP   Top probability mass to consider for generation.
        TopP                {aisdk.internal.mustBeValidProbability} = "auto"

        %MaxNumTokens   Maximum number of tokens in the generated response.
        MaxNumTokens  (1,1) {aisdk.internal.mustBePositiveIntegerOrInf} = inf

        %TimeOut   Connection timeout in seconds.
        TimeOut       (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = 120

        %StreamFcn   Function to callback when streaming.
        StreamFcn
    end

    methods (Abstract, Access=protected)
        %endpointPath   Path appended to the base URL, e.g. "responses".
        path = endpointPath(this)

        %parseUsage   Token counts from the usage field of a response.
        usage = parseUsage(this, response)

        %buildOutputMessages   LLMMessage objects from the unformatted TEXT and
        %   the API-specific OUTPUT of a successful response.
        messages = buildOutputMessages(this, text, output)
    end

    methods (Access=protected)
        function this = OpenAIBase(modelName, nvp)
            %OpenAIBase Set the properties both OpenAI clients share.
            %   NVP is the struct of validated name-value arguments of the
            %   subclass constructor.
            this.ModelName = modelName;
            this.APIKey = this.parseAPIKey(nvp);
            this.BaseURL = this.parseEndpoint(nvp);
            this.ContextSize = nvp.ContextSize;

            this.Temperature = nvp.Temperature;
            this.TopP = nvp.TopP;
            this.MaxNumTokens = nvp.MaxNumTokens;
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

        function [apiMessages, functionsStruct, toolChoice] = prepareRequest(this, messagesIn, nvp)
            %prepareRequest Convert messages, tools and tool choice to the
            %   wire format of the subclass.
            messagesIn = aisdk.client.ClientBase.normalizeMessages(messagesIn);
            [functionsStruct, functionNames] = this.convertToolsWithNames(nvp.Tools);

            aisdk.client.ClientBase.validateToolChoice(nvp.ToolChoice, functionNames);
            toolChoice = this.convertToolChoice(nvp.ToolChoice, functionNames);

            apiMessages = this.convertMessages(messagesIn);
        end

        function [text, messages, info] = processAPIResponse(this, text, output, response, responseFormat)
            %processAPIResponse Raise API errors and build the generate outputs
            %   from the response TEXT and the API-specific OUTPUT.
            this.handleErrorResponse(response);

            messages = this.buildOutputMessages(text, output);

            hasToolCalls = any(arrayfun(@(m) isa(m, 'aisdk.LLMToolCallMessage'), messages));
            text = aisdk.client.internal.reformatOutput(text, responseFormat, ...
                HasToolCalls=hasToolCalls);

            info = struct("Tokens", this.parseUsage(response));
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
            endpoint = endpoint + this.endpointPath();
        end

        function err = extractErrorMessage(~, data)
            if isfield(data, "error") && isstruct(data.error) && isfield(data.error, "message")
                err = string(data.error.message);
            else
                err = string.empty;
            end
        end

        function msg = toolCallMessage(~, name, arguments, id)
            %toolCallMessage Build an LLMToolCallMessage from a tool name,
            %   its arguments as JSON text or a decoded struct, and its ID.
            %   Empty arguments become an empty struct.
            if ~isstruct(arguments)
                if isempty(arguments) || strlength(arguments) == 0
                    arguments = struct();
                else
                    arguments = jsondecode(arguments);
                end
            end
            if ~isstruct(arguments)
                aisdk.internal.throwError("aisdk:invalidToolCallArguments", class(arguments));
            end
            msg = aisdk.LLMToolCallMessage(name, arguments, ToolCallID=id);
        end
    end

    methods (Access=protected, Static)
        function dataURI = imageDataURI(msg)
            %imageDataURI Encode the image of an LLMImageMessage as a PNG data URI.
            base64Str = matlab.net.base64encode(aisdk.internal.encodeImageToPNG(msg.Image));
            dataURI = "data:image/png;base64," + base64Str;
        end
    end

end
