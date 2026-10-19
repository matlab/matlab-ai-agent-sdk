function [response, streamedText] = sendRequest(parameters, token, endpoint, timeout, streamFcn, sendFcn)
% This function is undocumented and will change in a future release

%sendRequest Sends a request to an ENDPOINT using PARAMETERS and
%   api key TOKEN. TIMEOUT is the number of seconds to wait for initial
%   server connection. STREAMFCN is an optional callback function.

%   Copyright 2026 The MathWorks, Inc.

arguments
    parameters
    token
    endpoint
    timeout
    streamFcn = []
    sendFcn = @defaultSend
end

% Define the headers for the API request

headers = matlab.net.http.HeaderField('Content-Type', 'application/json');
if ~isempty(token) && strlength(token) > 0
    headers = [headers ...
        matlab.net.http.HeaderField('Authorization', "Bearer " + token)...
        matlab.net.http.HeaderField('api-key', token)];
end

% Define the request message
request = matlab.net.http.RequestMessage('post', headers, parameters);

% set the timeout
httpOpts = matlab.net.http.HTTPOptions;
httpOpts.ConnectTimeout = timeout;
httpOpts.ResponseTimeout = timeout;
httpOpts.ProxyURI = getenv("HTTPS_PROXY");

% Send the request and store the response
streamedUsage = struct.empty;
streamedOutput = {};
if isempty(streamFcn)
    response = sendFcn(request, endpoint, httpOpts, []);
    streamedText = "";
else
    % User defined a stream callback function
    consumer = aisdk.utils.ResponseStreamer(streamFcn);
    response = sendFcn(request, endpoint, httpOpts, consumer);
    streamedText = consumer.ResponseText;
    streamedUsage = consumer.Usage;
    streamedOutput = consumer.StreamedOutputItems;
    if ~isempty(consumer.StreamError)
        aisdk.internal.throwError("aisdk:apiReturnedError", consumer.StreamError);
    end
end

response.Body.Data = aisdk.client.internal.decodeResponseBody(response.Body.Data);

% A streamed body is consumed by the consumer, so the token counts and the
% output items it reassembled are folded back into the response body for the
% caller to parse like a non-streamed one.
if ~isempty(streamedUsage) || ~isempty(streamedOutput)
    response.Body.Data = mergeStreamedFields(response.Body.Data, streamedUsage, streamedOutput);
end
end

function data = mergeStreamedFields(data, usage, output)
    if iscell(data)
        % Ollama streams NDJSON chunks; the counts belong on the final one.
        last = data{end};
        if ~isstruct(last)
            last = struct();
        end
        data{end} = mergeStreamedFields(last, usage, output);
        return
    end
    if ~isstruct(data)
        % Chat Completions and Responses stream SSE, which does not decode
        % to JSON.
        data = struct();
    end
    % Chat Completions and Responses.
    if isfield(usage, "usage")
        data.usage = usage.usage;
    end
    % Ollama.
    if isfield(usage, "prompt_eval_count")
        data.prompt_eval_count = usage.prompt_eval_count;
    end
    if isfield(usage, "eval_count")
        data.eval_count = usage.eval_count;
    end
    % Responses.
    if ~isempty(output)
        data.output = output;
    end
end

function response = defaultSend(request, endpoint, httpOpts, consumer)
    % send() does not accept [] as a consumer — it only has two forms:
    % send(req, uri, opts) and send(req, uri, opts, consumer)
    if isempty(consumer)
        response = send(request, matlab.net.URI(endpoint), httpOpts);
    else
        response = send(request, matlab.net.URI(endpoint), httpOpts, consumer);
    end
end
