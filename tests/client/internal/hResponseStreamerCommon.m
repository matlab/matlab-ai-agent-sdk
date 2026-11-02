classdef (Abstract) hResponseStreamerCommon < matlab.unittest.TestCase
% Shared ResponseStreamer behavior tests run by each API-specific stream suite.

%   Copyright 2026 The MathWorks, Inc.

    properties (Abstract, Constant, Access=protected)
        StreamerFactory
    end

    methods (Abstract, Access = protected)
        payload = textEvent(testCase, text)
        data = formatStreamEvent(testCase, event)
    end

    methods (Access = protected)
        function data = textChunk(testCase, text)
            data = testCase.formatStreamEvent(testCase.textEvent(text));
        end

        function data = textEventsChunk(testCase, texts)
            data = uint8.empty(0,1);
            for text = texts
                data = [data; testCase.textChunk(text)]; %#ok<AGROW>
            end
        end

        function data = textEventsCRLFChunk(testCase, texts)
            data = testCase.textEventsChunk(texts);
            text = native2unicode(data', 'UTF-8');
            text = replace(text, newline, [char(13) newline]);
            data = hResponseStreamerUtils.streamBytes(text);
        end

        function data = finalTextChunkWithoutNewline(testCase, text)
            data = testCase.textChunk(text);
            data(end) = [];
        end

        function data = invalidChunk(testCase)
            data = [ ...
                testCase.formatStreamEvent("not-json")
                testCase.textChunk("ok")];
        end

        function [first, rest, expectedIncomplete] = splitTextChunk(testCase, firstPart, restPart)
            text = string(firstPart) + string(restPart);
            data = testCase.textChunk(text);
            textBytes = hResponseStreamerUtils.streamBytes(text);
            matches = strfind(char(data'), char(textBytes'));
            testCase.assertNotEmpty(matches, "Pattern was not found in stream bytes.");
            textStart = matches(1);
            splitAt = textStart + numel(hResponseStreamerUtils.streamBytes(firstPart)) - 1;
            first = data(1:splitAt);
            rest = data(splitAt+1:end);
            expectedIncomplete = native2unicode(first', 'UTF-8');
        end

    end

    methods (Test, TestTags = {'Unit'})
        function textDelta_appendsToResponseText(testCase)
            streamer = feval(testCase.StreamerFactory, @(~) []);

            streamer.doPutData(testCase.textChunk("Hello"), false);

            testCase.verifyEqual(streamer.ResponseText, 'Hello');
        end

        function textDelta_preservesDataPrefixInsideContent(testCase)
            streamer = feval(testCase.StreamerFactory, @(~) []);

            streamer.doPutData( ...
                testCase.textChunk("literal data: value"), false);

            testCase.verifyEqual(streamer.ResponseText, 'literal data: value');
        end

        function textDelta_preservesLiteralBackslashN(testCase)
            streamer = feval(testCase.StreamerFactory, @(~) []);

            streamer.doPutData( ...
                testCase.textChunk("literal \n value"), false);

            testCase.verifyEqual(streamer.ResponseText, 'literal \n value');
        end

        function textDelta_decodesEscapedNewline(testCase)
            received = {};
            streamer = feval(testCase.StreamerFactory, @captureText);
            expected = ['line1' newline 'line2'];

            streamer.doPutData(testCase.textChunk(expected), false);

            testCase.verifyEqual(streamer.ResponseText, expected);
            testCase.verifyEqual(received, {expected});

            function captureText(text)
                received{end+1} = text;
            end
        end

        function textDelta_callsStreamFcn(testCase)
            received = {};
            streamer = feval(testCase.StreamerFactory, @(txt) iCapture(txt));

            streamer.doPutData(testCase.textChunk("Hi"), false);

            testCase.verifyEqual(received, {'Hi'});

            function iCapture(txt)
                received{end+1} = txt;
            end
        end

        function invalidJSON_midStream_throwsError(testCase)
            streamer = feval(testCase.StreamerFactory, @(~) []);

            testCase.verifyError( ...
                @() streamer.doPutData(testCase.invalidChunk(), false), ...
                "aisdk:stream:responseStreamer:InvalidInput");
        end

        function multipleEvents_processedInOneCall(testCase)
            streamer = feval(testCase.StreamerFactory, @(~) []);

            streamer.doPutData( ...
                testCase.textEventsChunk(["Hel" "lo"]), false);

            testCase.verifyEqual(streamer.ResponseText, 'Hello');
        end

        function crlfLineEndings_parseTextEvents(testCase)
            streamer = feval(testCase.StreamerFactory, @(~) []);

            streamer.doPutData( ...
                testCase.textEventsCRLFChunk(["Hel" "lo"]), false);

            testCase.verifyEqual(streamer.ResponseText, 'Hello');
        end

        function incompleteJSON_buffersForNextCall(testCase)
            streamer = feval(testCase.StreamerFactory, @(~) []);
            [partial, ~, expectedIncomplete] = testCase.splitTextChunk("par", "t");

            streamer.doPutData(partial, false);

            testCase.verifyEqual( ...
                string(native2unicode(streamer.Incomplete', 'UTF-8')), ...
                string(expectedIncomplete));
        end

        function incompleteThenRest_completesResponseText(testCase)
            streamer = feval(testCase.StreamerFactory, @(~) []);
            [partial, rest] = testCase.splitTextChunk("par", "t");

            streamer.doPutData(partial, false);
            streamer.doPutData(rest, false);

            testCase.verifyEqual(streamer.ResponseText, 'part');
            testCase.verifyEmpty(streamer.Incomplete);
        end

        function finalLineWithoutNewline_isProcessedAtEndOfStream(testCase)
            streamer = feval(testCase.StreamerFactory, @(~) []);

            streamer.doPutData( ...
                testCase.finalTextChunkWithoutNewline("Hi"), false);
            streamer.doPutData(uint8.empty(0,1), false);

            testCase.verifyEqual(streamer.ResponseText, 'Hi');
        end

        function multiByteCharacterSplitAcrossChunks_reassembles(testCase)
            streamer = feval(testCase.StreamerFactory, @(~) []);
            bytes = testCase.textChunk(char(228));
            splitAt = find(bytes == 0xC3, 1);

            streamer.doPutData(bytes(1:splitAt), false);
            streamer.doPutData(bytes(splitAt+1:end), false);

            testCase.verifyEqual(streamer.ResponseText, char(228));
        end

        function textDelta_appendsAcrossMultipleCalls(testCase)
            streamer = feval(testCase.StreamerFactory, @(~) []);

            streamer.doPutData(testCase.textChunk("A"), false);
            streamer.doPutData(testCase.textChunk("B"), false);
            streamer.doPutData(testCase.textChunk("C"), false);

            testCase.verifyEqual(streamer.ResponseText, 'ABC');
        end

        function textDelta_callsStreamFcnOncePerDelta(testCase)
            received = {};
            streamer = feval(testCase.StreamerFactory, @(txt) iCapture(txt));

            streamer.doPutData( ...
                testCase.textEventsChunk(["one" "two" "three"]), false);

            testCase.verifyEqual(received, {'one','two','three'});

            function iCapture(txt)
                received{end+1} = txt;
            end
        end
    end
end
