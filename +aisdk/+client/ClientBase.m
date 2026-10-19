classdef (Abstract) ClientBase < matlab.mixin.CustomDisplay
%ClientBase Abstract base class for LLM clients.
%
%   This is an abstract base class that provides common properties and
%   the call interface for aisdk.client.OpenAIClient,
%   aisdk.client.OpenAIResponsesClient and aisdk.client.OllamaClient.
%
%   ClientBase Properties:
%       ModelName   - Name of the model to use.
%       APIKey      - API key for authentication.
%       BaseURL     - API endpoint URL.
%
%   ClientBase Methods:
%       call        - Generate a response by calling the chat completion API.
%

% Copyright 2026 The MathWorks, Inc.

    properties (Abstract, Constant, Hidden)
        %API   Provider name used for environment variable prefixes.
        API (1,1) string
    end

    properties (SetAccess=protected)
        %ModelName   Name of the model to use.
        ModelName (1,1) string

        %BaseURL   API endpoint URL.
        BaseURL  (1,1) string
    end

    properties
        %ContextSize   Maximum context window size in tokens.
        ContextSize (1,1) double {aisdk.internal.mustBePositiveIntegerOrNaN} = NaN
    end

    properties (Hidden, GetAccess=protected, SetAccess=public, Transient)
        %APIKey   API key for authentication.
        APIKey    (1,1) string
    end

    properties (Hidden)
        % test seam
        sendRequestFcn = @aisdk.client.internal.sendRequestWrapper
    end

    methods (Abstract)
        %generate   Generate a response by calling the chat completion API.
        [text, message, info] = generate(this, messagesStruct, nvp)
    end

    methods (Abstract, Access=protected)
        %convertMessages   Convert an array of LLMMessage objects to the
        %   provider-specific cell array of structs format.
        messagesOut = convertMessages(this, messages)

        %extractErrorMessage   Extract error text from a provider-specific
        %   error response body. Return string.empty if the format is
        %   unrecognized (base class will fall back to the HTTP status code).
        err = extractErrorMessage(this, data)
    end

    methods (Abstract, Access=protected)
        %parseEndpoint   Parse BaseURL from nvp or environment variable,
        %   falling back to a provider-specific default.
        endpoint = parseEndpoint(this, nvp)
    end

    methods (Static)
        function message = normalizeMessages(input)
            %normalizeMessages Convert input to an LLMMessage array.
            %   Accepts a string/char (wrapped as user text message)
            %   or an LLMMessage array (returned as-is).
            if isa(input, 'aisdk.message.LLMMessage')
                message = input;
            elseif isstring(input) || ischar(input)
                message = aisdk.LLMTextMessage(string(input));
            else
                aisdk.internal.throwError("aisdk:client:InvalidMessageInput");
            end
        end
    end

    methods (Access=protected)
        function groups = getPropertyGroups(obj)
            props = properties(obj);
            leading = ["ModelName"; "BaseURL"; "MaxNumTokens"; "ReasoningEffort"];
            server = ["StopSequences"; "StreamFcn"; "TimeOut"];
            leading = leading(ismember(leading, props));
            generation = ["ResponseFormat"; "Verbosity"; "Temperature"; "TopP"; "PresencePenalty"; "FrequencyPenalty"];
            server = server(ismember(server, props));
            generation = generation(ismember(generation, props));
            others = props(~ismember(props, [leading; server; generation]));
            groups = matlab.mixin.util.PropertyGroup([leading; server; generation; others]);
        end
    end

    methods (Access=protected, Static)
        function validateToolChoice(toolChoice, functionNames)
            if ~isempty(toolChoice)
                mustBeTextScalar(toolChoice);
                if isempty(functionNames) && ~ismember(toolChoice, ["auto", "none"])
                    aisdk.internal.throwError("aisdk:mustSetFunctionsForCall");
                end
                if ~isempty(functionNames)
                    mustBeMember(toolChoice, ["none","auto","required", functionNames]);
                end
            end
        end
    end

    methods (Access=protected)
        function toolChoice = convertToolChoice(~, toolChoice, functionNames)
            %convertToolChoice Convert the tool choice to the Chat Completions format.
            %   Override in subclasses for APIs that require a different format.
            if isempty(toolChoice)
                if ~isempty(functionNames)
                    toolChoice = "auto";
                end
            elseif ismember(toolChoice, ["auto", "none"]) && isempty(functionNames)
                toolChoice = strings(1,0);
            elseif ~ismember(toolChoice,["auto","none","required"])
                toolChoice = struct("type","function","function",struct("name",toolChoice));
            end
        end

        function toolStruct = encodeTool(~, tool)
            %encodeTool Encode an LLMTool into OpenAI Chat Completions format.
            %   Produces the {type: "function", function: {name, description, parameters}}
            %   structure. Override in subclasses for APIs that require a different format.
            funcStruct = struct( ...
                "name", tool.Name, ...
                "description", tool.Description, ...
                "parameters", tool.inputSchema());
            toolStruct = struct("type", "function", "function", funcStruct);
        end

        function [functionsStruct, functionNames] = convertToolsWithNames(this, tools)
            %convertToolsWithNames Convert Tools to functionsStruct and extract names.
            %   If tools is an array of aisdk.tool.LLMTool objects, convert
            %   to a cell array of structs and return function names.
            if isempty(tools)
                functionsStruct = [];
                functionNames = [];
            elseif isa(tools, 'aisdk.tool.LLMTool')
                numTools = numel(tools);
                functionsStruct = cell(1, numTools);
                functionNames = strings(1, numTools);
                for i = 1:numTools
                    functionsStruct{i} = this.encodeTool(tools(i));
                    functionNames(i) = tools(i).Name;
                end
            else
                functionsStruct = tools;
                functionNames = [];
            end
        end
    end

    methods (Static, Hidden)
        function obj = loadobj(obj)
            %loadobj   Read the API key from the {PROVIDER}_API_KEY
            %   environment variable when loading a client.
            if isa(obj, "aisdk.client.ClientBase")
                obj.APIKey = obj.parseAPIKey();
            end
        end
    end

    methods (Access=protected)
        function apiKey = parseAPIKey(this, nvp)
            %parseAPIKey Parse APIKey from nvp or environment variable.
            %
            %   APIKEY = parseAPIKey(OBJ, NVP)
            %   returns the APIKey from the name-value pairs NVP,
            %   or reads it from the {PROVIDER}_API_KEY environment variable.
            %   Returns empty string if no API key is found.
            %
            %   APIKEY = parseAPIKey(OBJ) reads the environment variable only.
            arguments
                this
                nvp (1,1) struct = struct()
            end

            envVarName = upper(this.API) + "_API_KEY";
            if isfield(nvp, "APIKey") && strlength(nvp.APIKey) > 0
                apiKey = nvp.APIKey;
            elseif isenv(envVarName)
                apiKey = getenv(envVarName);
            else
                apiKey = "";
            end
        end


        function handleErrorResponse(this, response)
            if response.StatusCode == "OK"
                return
            end
            err = this.extractErrorMessage(response.Body.Data);
            if isempty(err)
                err = "HTTP " + string(response.StatusCode) + ": " + jsonencode(response.Body.Data);
            end
            if response.StatusCode == "Unauthorized" && strlength(this.APIKey) == 0
                aisdk.internal.throwError("aisdk:client:missingAPIKey", err);
            end
            aisdk.internal.throwError("aisdk:apiReturnedError", err);
        end
    end

end
