classdef (Abstract) ResponseStreamer < matlab.net.http.io.BinaryConsumer
%ResponseStreamer Shared byte buffering for streamed API responses.

%   Copyright 2026 The MathWorks, Inc.

    properties
        ResponseText = ''
        StreamFcn
        % Incomplete holds bytes after the last newline received.
        Incomplete = uint8.empty(0,1)
        Usage = struct.empty
        StreamedOutputItems = {}
        StreamError = string.empty
    end

    methods
        function this = ResponseStreamer(streamFcn)
            this.StreamFcn = streamFcn;
        end
    end

    methods (Abstract)
        data = mergeResponseData(this, data)
    end

    methods (Access=protected)
        function json = decodeJSON(~, text)
            try
                json = jsondecode(text);
            catch
                aisdk.internal.throwError("aisdk:stream:responseStreamer:InvalidInput");
            end
        end
    end

    methods
        function [len,stop] = putData(this, data)
            [len,stop] = this.putData@matlab.net.http.io.BinaryConsumer(data);
            stop = doPutData(this, data, stop);
        end
    end

    methods (Hidden)
        function stop = doPutData(this, data, stop)
            % Decode only complete lines. Holding the trailing bytes also
            % preserves a multi-byte UTF-8 character split across chunks.
            bytes = [this.Incomplete; data(:)];
            this.Incomplete = uint8.empty(0,1);
            if ~isempty(data)
                lastNewline = find(bytes == 10, 1, "last");
                if isempty(lastNewline)
                    lastNewline = 0;
                end
                this.Incomplete = bytes(lastNewline+1:end);
                bytes = bytes(1:lastNewline);
            end

            lines = split(string(native2unicode(bytes.', 'UTF-8')), newline);
            lines = strip(lines, "right", char(13));
            lines = lines(strlength(lines) > 0);
            stop = processLines(this, lines, stop);
            if stop
                % Discard the tail so the final empty-data callback cannot
                % process bytes received after the terminal event.
                this.Incomplete = uint8.empty(0,1);
            end
        end
    end

    methods (Abstract, Access=protected)
        stop = processLines(this, lines, stop)
    end
end
