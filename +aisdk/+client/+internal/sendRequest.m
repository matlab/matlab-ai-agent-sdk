function response = sendRequest(parameters, token, endpoint, timeout, streamFcn, streamerFactory, sendFcn)
% This function is undocumented and will change in a future release

%sendRequest Sends a request to an ENDPOINT using PARAMETERS and
%   api key TOKEN. TIMEOUT is the number of seconds to wait for initial
%   server connection. streamFcn is empty or a callback function.
%   streamerFactory constructs the API-specific response consumer.
%   sendFcn is an optional function handle called as
%   RESPONSE = sendFcn(REQUEST, ENDPOINT, httpOpts, CONSUMER), where
%   CONSUMER is [] for non-streaming requests. By default, it wraps
%   matlab.net.http.RequestMessage.send. Tests can supply sendFcn to
%   replace the HTTP transport.

%   Copyright 2026 The MathWorks, Inc.

arguments
    parameters
    token
    endpoint
    timeout
    streamFcn
    streamerFactory (1,1) function_handle
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
if isempty(streamFcn)
    response = sendFcn(request, endpoint, httpOpts, []);
else
    % User defined a stream callback function
    consumer = streamerFactory(streamFcn);
    if isa(consumer, "aisdk.client.internal.SSEResponseStreamer")
        request.Header(end+1) = matlab.net.http.HeaderField("Accept", "text/event-stream");
    end
    response = sendFcn(request, endpoint, httpOpts, consumer);
    if ~isempty(consumer.StreamError)
        aisdk.internal.throwError("aisdk:apiReturnedError", consumer.StreamError);
    end
end

response.Body.Data = aisdk.client.internal.decodeResponseBody(response.Body.Data);

% A successful streamed body is consumed by the API-specific consumer.
% Reconstruct the fields that the corresponding non-streamed decoder
% expects. Preserve error bodies verbatim for provider error reporting.
if ~isempty(streamFcn) && response.StatusCode == "OK"

    response.Body.Data = consumer.mergeResponseData(response.Body.Data);
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
