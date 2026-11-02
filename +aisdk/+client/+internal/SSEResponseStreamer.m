classdef (Abstract) SSEResponseStreamer < aisdk.client.internal.ResponseStreamer
%SSEResponseStreamer Shared parsing for server-sent event streams.

%   Copyright 2026 The MathWorks, Inc.

    methods
        function this = SSEResponseStreamer(streamFcn)
            this@aisdk.client.internal.ResponseStreamer(streamFcn);
        end
    end

    methods (Access=protected)
        function stop = processLines(this, lines, stop)
            lines = lines(startsWith(lines, "data:"));
            lines = erase(lines, lineBoundary + "data:" + optionalPattern(" "));

            for k = 1:numel(lines)
                stop = processData(this, lines(k), stop);
                if stop
                    return
                end
            end
        end

        function stop = processData(this, data, stop)
            stop = processEvent(this, this.decodeJSON(data), stop);
        end
    end

    methods (Abstract, Access=protected)
        stop = processEvent(this, event, stop)
    end
end
