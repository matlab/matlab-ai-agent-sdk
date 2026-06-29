classdef (Abstract) ClientBase < matlab.mixin.CustomDisplay
%ClientBase Abstract base class for LLM clients.
%
%   This is an abstract base class that provides common properties and
%   the call interface for aisdk.llms.client.OpenAIClient and aisdk.llms.client.OllamaClient.
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

    properties (Abstract, Constant)
        %API   Provider name used for environment variable prefixes.
        API (1,1) string
    end

    properties (SetAccess=protected)
        %ModelName   Name of the model to use.
        ModelName (1,1) string

        %BaseURL   API endpoint URL.
        BaseURL  (1,1) string
    end

    properties (Hidden, Access=protected, Transient)
        %APIKey   API key for authentication.
        APIKey    (1,1) string
    end

    properties (Hidden)
        % test seam
        sendRequestFcn = @aisdk.llms.client.internal.sendRequestWrapper
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
            if isa(input, 'aisdk.llms.message.LLMMessage')
                message = input;
            elseif isstring(input) || ischar(input)
                message = aisdk.LLMTextMessage(string(input));
            else
                error("llms:client:InvalidMessageInput", ...
                    aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:client:InvalidMessageInput"));
            end
        end
    end

    methods (Access=protected)
        function groups = getPropertyGroups(obj)
            props = properties(obj);
            leading = ["API"; "ModelName"; "BaseURL"; "MaxNumTokens"; "ReasoningEffort"];
            server = ["StopSequences"; "StreamFcn"; "TimeOut"];
            leading = leading(ismember(leading, props));
            server = server(ismember(server, props));
            others = props(~ismember(props, [leading; server]));
            groups = matlab.mixin.util.PropertyGroup([leading; server; others]);
        end
    end

    methods (Access=protected, Static)
        function validateToolChoice(toolChoice, functionNames)
            if ~isempty(toolChoice)
                mustBeTextScalar(toolChoice);
                if isempty(functionNames) && ~ismember(toolChoice, ["auto", "none"])
                    error("llms:mustSetFunctionsForCall", aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:mustSetFunctionsForCall"));
                end
                if ~isempty(functionNames)
                    mustBeMember(toolChoice, ["none","auto","required", functionNames]);
                end
            end
        end

        function toolChoice = convertToolChoice(toolChoice, functionNames)
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
    end

    methods (Access=protected)
        function toolStruct = encodeTool(~, tool)
            %encodeTool Encode an LLMTool into OpenAI Chat Completions format.
            %   Produces the {type: "function", function: {name, description, parameters}}
            %   structure. Override in subclasses for APIs that require a different format.
            if isa(tool, 'aisdk.llms.tool.LocalLLMTool')
                funcStruct = struct( ...
                    "name", tool.Name, ...
                    "description", tool.Description, ...
                    "parameters", aisdk.llms.client.ClientBase.argumentsToSchema(tool.InputArguments));
            elseif isa(tool, 'aisdk.llms.tool.MCPTool')
                funcStruct = struct( ...
                    "name", tool.Name, ...
                    "description", tool.Description, ...
                    "parameters", tool.InputArguments);
            else
                error("llms:unsupportedToolType", ...
                    aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:unsupportedToolType"));
            end
            toolStruct = struct("type", "function", "function", funcStruct);
        end

        function [functionsStruct, functionNames] = convertToolsWithNames(this, tools)
            %convertToolsWithNames Convert Tools to functionsStruct and extract names.
            %   If tools is an array of aisdk.llms.tool.LLMTool objects, convert
            %   to a cell array of structs and return function names.
            if isempty(tools)
                functionsStruct = [];
                functionNames = [];
            elseif isa(tools, 'aisdk.llms.tool.LLMTool')
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

    methods (Access=protected)
        function apiKey = parseAPIKey(this, nvp)
            %parseAPIKey Parse APIKey from nvp or environment variable.
            %
            %   APIKEY = parseAPIKey(OBJ, NVP)
            %   returns the APIKey from the name-value pairs NVP,
            %   or reads it from the {PROVIDER}_API_KEY environment variable.
            %   Returns empty string if no API key is found.

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
            error("llms:apiReturnedError", ...
                aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:apiReturnedError", err));
        end
    end

    methods (Access=private, Static)
        function str = argumentsToSchema(args)
            %argumentsToSchema Convert LLMToolArgument array to JSON Schema struct.
            str = struct();
            str.type = "object";
            params = struct();
            requiredParams = strings(1,0);
            for i = 1:numel(args)
                thisDescription = struct();
                if strlength(args(i).DataType) > 0
                    thisDescription.type = args(i).DataType;
                end
                if strlength(args(i).Description) > 0
                    thisDescription.description = args(i).Description;
                end
                params.(args(i).Name) = thisDescription;
                if args(i).Required
                    requiredParams(end + 1) = args(i).Name; %#ok<AGROW>
                end
            end
            str.properties = params;
            if ~isempty(requiredParams)
                str.required = requiredParams;
            end
            if isfield(str, 'required') && numel(str.required) == 1
                str.required = {str.required};
            end
        end
    end
end
