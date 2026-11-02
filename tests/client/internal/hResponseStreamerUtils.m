classdef hResponseStreamerUtils
% Generic helpers for ResponseStreamer tests.

%   Copyright 2026 The MathWorks, Inc.

    methods (Static)
        function data = streamBytes(text)
            data = unicode2native(char(text), 'UTF-8')';
        end

        function data = sseDataChunk(text)
            data = hResponseStreamerUtils.streamBytes(['data: ' char(text) newline]);
        end

        function data = ndjsonChunk(text)
            data = hResponseStreamerUtils.streamBytes([char(text) newline]);
        end

    end
end
