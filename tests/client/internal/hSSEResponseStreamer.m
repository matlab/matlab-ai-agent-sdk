classdef hSSEResponseStreamer < aisdk.client.internal.SSEResponseStreamer
% SSE streamer that records payloads without decoding JSON.

%   Copyright 2026 The MathWorks, Inc.

    properties
        Payloads = strings(0,1)
    end

    methods
        function this = hSSEResponseStreamer
            this@aisdk.client.internal.SSEResponseStreamer(@(~) []);
        end

        function data = mergeResponseData(~, data)
        end
    end

    methods (Access=protected)
        function event = decodeJSON(~, data)
            event = data;
        end

        function stop = processEvent(this, event, stop)
            this.Payloads(end+1,1) = event;
        end
    end
end
