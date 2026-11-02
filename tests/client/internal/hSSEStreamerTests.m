classdef (Abstract) hSSEStreamerTests < hResponseStreamerCommon
% Shared ResponseStreamer tests and helpers for SSE-framed APIs.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        % SSE lines other than "data:" lines.
        NonDataLine = struct( ...
            "comment", ": some comment", ...
            "event",   "event: response.output_text.delta", ...
            "id",      "id: 42", ...
            "retry",   "retry: 3000");

        DataPrefix = struct( ...
            "withoutSpace", "data:", ...
            "withSpace", "data: ");
    end

    methods (Access = protected)
        function data = formatStreamEvent(~, event)
            data = hResponseStreamerUtils.sseDataChunk(event);
        end
    end

    methods (Test, TestTags = {'Unit'})
        function nonDataLine_isIgnored(testCase, NonDataLine)
            streamer = feval(testCase.StreamerFactory, @(~) []);
            chunk = hResponseStreamerUtils.streamBytes([ ...
                'data: ' char(testCase.textEvent("Hel")) newline ...
                char(NonDataLine) newline ...
                'data: ' char(testCase.textEvent("lo")) newline]);

            streamer.doPutData(chunk, false);

            testCase.verifyEqual(streamer.ResponseText, 'Hello');
        end

        function nonDataJsonLine_isIgnored(testCase)
            streamer = feval(testCase.StreamerFactory, @(~) []);
            chunk = hResponseStreamerUtils.streamBytes([ ...
                'data: ' char(testCase.textEvent("Hel")) newline ...
                char(testCase.textEvent("ignored")) newline ...
                'data: ' char(testCase.textEvent("lo")) newline]);

            streamer.doPutData(chunk, false);

            testCase.verifyEqual(streamer.ResponseText, 'Hello');
        end

        function bareJsonOnlyChunk_isIgnored(testCase)
            streamer = feval(testCase.StreamerFactory, @(~) []);
            chunk = hResponseStreamerUtils.streamBytes( ...
                [char(testCase.textEvent("ignored")) newline]);

            streamer.doPutData(chunk, false);

            testCase.verifyEmpty(streamer.ResponseText);
        end

        function dataLine_isParsed(testCase, DataPrefix)
            streamer = feval(testCase.StreamerFactory, @(~) []);
            chunk = hResponseStreamerUtils.streamBytes( ...
                DataPrefix + testCase.textEvent("Hi") + newline);

            streamer.doPutData(chunk, false);

            testCase.verifyEqual(streamer.ResponseText, 'Hi');
        end
    end
end
