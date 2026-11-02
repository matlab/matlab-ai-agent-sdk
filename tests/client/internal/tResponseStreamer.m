classdef tResponseStreamer < matlab.unittest.TestCase
% Tests for ResponseStreamer behavior that is independent of API wire format.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        StreamerFactory = struct( ...
            "chatCompletions", @aisdk.client.internal.ChatCompletionsResponseStreamer, ...
            "responses", @aisdk.client.internal.ResponsesResponseStreamer, ...
            "ollama", @aisdk.client.internal.OllamaResponseStreamer);
    end

    methods (Test, TestTags = {'Unit'})
        function constructor_setsStreamFcn(testCase, StreamerFactory)
            streamFcn = @(txt) txt;

            streamer = StreamerFactory(streamFcn);

            testCase.verifyEqual(streamer.StreamFcn, streamFcn);
        end

        function constructor_initializesState(testCase, StreamerFactory)
            streamer = StreamerFactory(@(~) []);

            testCase.verifyEmpty(streamer.ResponseText);
            testCase.verifyClass(streamer.ResponseText, "char");
            testCase.verifyEmpty(streamer.Incomplete);
            testCase.verifyEmpty(streamer.Usage);
            testCase.verifyEmpty(streamer.StreamedOutputItems);
            testCase.verifyEmpty(streamer.StreamError);
        end

        function partialLineWithoutNewline_isBuffered(testCase, StreamerFactory)
            streamer = StreamerFactory(@(~) []);
            bytes = hResponseStreamerUtils.streamBytes("partial line");

            streamer.doPutData(bytes, false);

            testCase.verifyEqual( ...
                string(native2unicode(streamer.Incomplete', 'UTF-8')), ...
                "partial line");
            testCase.verifyEmpty(streamer.ResponseText);
        end

        function emptyDataWithNoBufferedLine_keepsStateUnchanged(testCase, StreamerFactory)
            streamer = StreamerFactory(@(~) []);

            stop = streamer.doPutData(uint8.empty(0,1), false);

            testCase.verifyFalse(stop);
            testCase.verifyEmpty(streamer.ResponseText);
            testCase.verifyEmpty(streamer.Incomplete);
        end

    end
end
