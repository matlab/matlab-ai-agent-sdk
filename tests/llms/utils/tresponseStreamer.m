classdef tresponseStreamer < matlab.unittest.TestCase
% Tests for aisdk.llms.utils.ResponseStreamer.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function textDelta_appendsToResponseText(testCase)
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"choices":[{"delta":{"content":"Hello"}}]}');
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(streamer.ResponseText, 'Hello');
        end

        function textDelta_callsStreamFcn(testCase)
            received = {};
            streamer = aisdk.llms.utils.ResponseStreamer(@(txt) iCapture(txt));
            chunk = iMakeChunk('{"choices":[{"delta":{"content":"Hi"}}]}');
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(received{end}, 'Hi');

            function iCapture(txt)
                received{end+1} = txt;
            end
        end

        function doneMessage_returnsStopTrue(testCase)
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('[DONE]');
            stop = streamer.doPutData(chunk, false);
            testCase.verifyTrue(stop);
        end

        function finishReasonStop_returnsStopTrue(testCase)
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"choices":[{"finish_reason":"stop","delta":{"content":""}}]}');
            stop = streamer.doPutData(chunk, false);
            testCase.verifyTrue(stop);
        end

        function toolCallDelta_buildsToolCallJSON(testCase)
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"choices":[{"delta":{"tool_calls":{"id":"call_1","type":"function","function":{"name":"add","arguments":""}}}}]}');
            streamer.doPutData(chunk, false);
            result = jsondecode(streamer.ResponseText);
            testCase.verifyEqual(result.id, 'call_1');
            testCase.verifyEqual(result.function.name, 'add');
        end

        function toolCallArgDelta_appendsArguments(testCase)
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            firstChunk = iMakeChunk('{"choices":[{"delta":{"tool_calls":{"id":"call_1","type":"function","function":{"name":"add","arguments":"{"}}}}]}');
            streamer.doPutData(firstChunk, false);
            argChunk = iMakeChunk('{"choices":[{"delta":{"tool_calls":{"function":{"arguments":"\"a\":1}"}}}}]}');
            streamer.doPutData(argChunk, false);
            result = jsondecode(streamer.ResponseText);
            testCase.verifyEqual(result.function.arguments, '{"a":1}');
        end

        function incompleteJSON_buffersForNextCall(testCase)
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            partial = iMakeChunk('{"choices":[{"delta":{"content":"par');
            streamer.doPutData(partial, false);
            testCase.verifyEqual(streamer.Incomplete, ...
                '{"choices":[{"delta":{"content":"par');
        end

        function invalidJSON_midStream_throwsError(testCase)
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk(sprintf('not-json\n{"choices":[{"delta":{"content":"ok"}}]}'));
            testCase.verifyError( ...
                @() streamer.doPutData(chunk, false), ...
                "llms:stream:responseStreamer:InvalidInput");
        end

        function ollamaFormat_extractsMessageContent(testCase)
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"message":{"content":"Hello from Ollama"},"done":false}');
            streamer.doPutData(chunk, false);
            testCase.verifySubstring(streamer.ResponseText, "Hello from Ollama");
        end

        function ollamaFormat_doneTrue_returnsStop(testCase)
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"message":{"content":"done"},"done":true}');
            stop = streamer.doPutData(chunk, false);
            testCase.verifyTrue(stop);
        end
    end
end

function data = iMakeChunk(text)
    line = "data: " + text;
    data = unicode2native(char(line + newline), 'UTF-8')';
end
