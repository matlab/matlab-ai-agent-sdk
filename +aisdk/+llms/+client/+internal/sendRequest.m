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
if isempty(streamFcn)
    response = sendFcn(request, endpoint, httpOpts, []);
    streamedText = "";
else
    % User defined a stream callback function
    consumer = aisdk.llms.utils.ResponseStreamer(streamFcn);
    response = sendFcn(request, endpoint, httpOpts, consumer);
    streamedText = consumer.ResponseText;
    streamedUsage = consumer.Usage;
end

response.Body.Data = aisdk.llms.client.internal.decodeResponseBody(response.Body.Data);

if ~isempty(streamedUsage)
    response.Body.Data = mergeStreamedUsage(response.Body.Data, streamedUsage);
end
end

function data = mergeStreamedUsage(data, usage)
    fields = fieldnames(usage);
    if isstruct(data)
        for k = 1:numel(fields)
            data.(fields{k}) = usage.(fields{k});
        end
    elseif iscell(data)
        last = data{end};
        if ~isstruct(last)
            last = struct();
        end
        for k = 1:numel(fields)
            last.(fields{k}) = usage.(fields{k});
        end
        data{end} = last;
    else
        data = usage;
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
