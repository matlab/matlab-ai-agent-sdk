classdef tSSEResponseStreamer < matlab.unittest.TestCase
% Tests for SSE framing before JSON decoding.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function dataLineWithTwoSpaces_preservesSecondSpace(testCase)
            streamer = hSSEResponseStreamer;
            data = hResponseStreamerUtils.streamBytes("data:  <something>" + newline);

            streamer.doPutData(data, false);

            testCase.verifyEqual(streamer.Payloads, " <something>");
        end
    end
end
