function [text, outputItems, response] = callResponsesAPI(inMessages, tools, nvp)
% This function is undocumented and will change in a future release

%callResponsesAPI Calls the OpenAI Responses API.
%
%   INMESSAGES is a cell array of input items and TOOLS a cell array of
%   tool definitions, both matching the JSON format expected by the OpenAI
%   Responses API.
%   Ref: https://platform.openai.com/docs/api-reference/responses/create
%
%   The returned OUTPUTITEMS is the "output" array of the response as a
%   1-by-N cell array of items in their original order, and TEXT is the
%   assistant text of its message items.

%   Copyright 2026 The MathWorks, Inc.

arguments
    inMessages
    tools
    nvp.ToolChoice
    nvp.ModelName
    nvp.Temperature
    nvp.TopP
    nvp.MaxNumTokens
    nvp.ResponseFormat
    nvp.ReasoningEffort (1,1) string = "auto"
    nvp.Verbosity       (1,1) string = "auto"
    nvp.APIKey
    nvp.TimeOut
    nvp.StreamFcn
    nvp.sendRequestFcn
    nvp.Endpoint
end

parameters = buildParametersCall(inMessages, tools, nvp);

[response, streamedText] = nvp.sendRequestFcn(parameters, nvp.APIKey, nvp.Endpoint, nvp.TimeOut, nvp.StreamFcn);

% If the call errors, "output" will not be part of response.Body.Data;
% instead we get response.Body.Data.error.
if response.StatusCode == "OK"
    % A streamed body carries the output items the streamer reassembled,
    % in the same shape a non-streamed body uses.
    outputItems = responseOutputItems(response.Body.Data);
    if isempty(nvp.StreamFcn)
        text = outputText(outputItems);
    else
        % Streaming takes the assistant text from the emitted output_text
        % deltas.
        text = string(streamedText);
        if isempty(text)
            text = "";
        end
    end
else
    text = "";
    outputItems = cell(1,0);
end
end

function parameters = buildParametersCall(inMessages, tools, nvp)
% Builds a struct in the format expected by the Responses API, combining
% INMESSAGES, TOOLS and parameters in NVP.

parameters = struct();
parameters.model = nvp.ModelName;
parameters.input = inMessages;

% Keep the interaction stateless to match the Chat Completions path; the
% caller passes the full conversation on every request.
parameters.store = false;

parameters.stream = ~isempty(nvp.StreamFcn);

if ~isempty(tools)
    parameters.tools = tools;
end

if ~isempty(nvp.ToolChoice)
    parameters.tool_choice = nvp.ToolChoice;
end

if isfield(nvp,"Temperature") && ~isempty(nvp.Temperature) && ~isequal(nvp.Temperature,"auto")
    parameters.temperature = nvp.Temperature;
end

if isfield(nvp,"TopP") && ~isempty(nvp.TopP) && ~isequal(nvp.TopP,"auto")
    parameters.top_p = nvp.TopP;
end

if ~isempty(nvp.MaxNumTokens) && ~isinf(nvp.MaxNumTokens)
    parameters.max_output_tokens = nvp.MaxNumTokens;
end

if nvp.ReasoningEffort ~= "auto"
    parameters.reasoning = struct("effort", nvp.ReasoningEffort);
end

% Verbosity and structured output both live under "text" in the Responses API.
textStruct = struct();
if nvp.Verbosity ~= "auto"
    textStruct.verbosity = nvp.Verbosity;
end
format = buildTextFormat(nvp.ResponseFormat);
if ~isempty(format)
    textStruct.format = format;
end
if ~isempty(fieldnames(textStruct))
    parameters.text = textStruct;
end
end

function format = buildTextFormat(responseFormat)
% Translates ResponseFormat into a Responses API text.format struct.
% Returns [] for plain-text output (no format needed).

format = [];
if strcmp(responseFormat,"json")
    format = struct('type','json_object');
elseif isstruct(responseFormat)
    format = struct('type','json_schema', ...
        'name','computedFromPrototype', 'strict', true, ...
        'schema', aisdk.client.internal.jsonSchemaFromPrototype(responseFormat));
elseif startsWith(string(responseFormat), asManyOfPattern(whitespacePattern)+"{")
    format = struct('type','json_schema', ...
        'name','providedInCall', 'strict', true, ...
        'schema', aisdk.client.internal.VerbatimJSON(responseFormat));
end
end

function items = responseOutputItems(data)
% The "output" array of DATA as a 1-by-N cell array, or an empty cell when
% DATA has no output array.

items = cell(1,0);
if ~isstruct(data) || ~isscalar(data) || ~isfield(data,"output")
    return
end
output = data.output;
if isstruct(output)
    output = num2cell(output);
end
if iscell(output) && ~isempty(output)
    items = reshape(output, 1, []);
end
end

function text = outputText(items)
text = "";
for i = 1:numel(items)
    item = items{i};
    if isstruct(item) && isfield(item,"type") && string(item.type) == "message"
        text = text + aisdk.client.internal.outputMessageText(item);
    end
end
end
