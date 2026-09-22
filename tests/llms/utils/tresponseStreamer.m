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

        function finishReasonStop_doesNotTerminateStream(testCase)
            % finish_reason no longer terminates the stream; the trailing
            % usage chunk (with include_usage=true) arrives after it, and
            % [DONE] is the real terminator.
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"choices":[{"finish_reason":"stop","delta":{"content":""}}]}');
            stop = streamer.doPutData(chunk, false);
            testCase.verifyFalse(stop);
        end

        function usageChunk_capturesUsage(testCase)
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"choices":[],"usage":{"prompt_tokens":7,"completion_tokens":11,"total_tokens":18}}');
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(streamer.Usage.usage.prompt_tokens, 7);
            testCase.verifyEqual(streamer.Usage.usage.completion_tokens, 11);
        end

        function ollamaDoneChunk_capturesUsage(testCase)
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"message":{"content":""},"done":true,"prompt_eval_count":5,"eval_count":9}');
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(streamer.Usage.prompt_eval_count, 5);
            testCase.verifyEqual(streamer.Usage.eval_count, 9);
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

        function finishReasonToolCalls_doesNotTerminateStream(testCase)
            % Parallel to finishReasonStop_doesNotTerminateStream: the tool_calls
            % variant of finish_reason must not terminate the stream either
            % — the trailing usage chunk still needs to be consumed.
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"choices":[{"finish_reason":"tool_calls","delta":{"content":""}}]}');
            stop = streamer.doPutData(chunk, false);
            testCase.verifyFalse(stop);
        end

        function emptyUsageObject_leavesUsageUnset(testCase)
            % A "usage":{} object should not populate Usage — the guard
            % requires fieldnames(json.usage) to be non-empty.
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"choices":[],"usage":{}}');
            streamer.doPutData(chunk, false);
            testCase.verifyEmpty(streamer.Usage);
        end

        function usageChunk_doesNotInvokeStreamFcn(testCase)
            % A usage-only chunk (empty choices) must not fire the stream
            % callback — that would emit a spurious empty token to the UI.
            calls = 0;
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) iBump());
            chunk = iMakeChunk('{"choices":[],"usage":{"prompt_tokens":1,"completion_tokens":2,"total_tokens":3}}');
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(calls, 0);

            function iBump()
                calls = calls + 1;
            end
        end

        function ollamaPartialUsage_capturesAvailableFields(testCase)
            % If the final chunk carries only one of the two Ollama usage
            % fields, capture what is present and skip the other.
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"message":{"content":""},"done":true,"prompt_eval_count":42}');
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(streamer.Usage.prompt_eval_count, 42);
            testCase.verifyFalse(isfield(streamer.Usage, "eval_count"));
        end

        function ollamaChunkWithoutUsageFields_leavesUsageUnset(testCase)
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"message":{"content":"hi"},"done":false}');
            streamer.doPutData(chunk, false);
            testCase.verifyEmpty(streamer.Usage);
        end

        function ollamaToolCallsMessage_writesJSONToResponseText(testCase)
            % Ollama returns tool calls under message.tool_calls; the
            % streamer serialises them into ResponseText for the client.
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"message":{"content":"","tool_calls":[{"function":{"name":"add","arguments":{"a":1,"b":2}}}]},"done":true}');
            streamer.doPutData(chunk, false);
            decoded = jsondecode(streamer.ResponseText);
            testCase.verifyEqual(decoded.function.name, 'add');
            testCase.verifyEqual(decoded.function.arguments.a, 1);
        end

        function multipleSSELines_processedInOneCall(testCase)
            % One putData call can deliver more than one SSE event; each
            % "data: ..." line must be parsed independently.
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            payload = sprintf(['data: {"choices":[{"delta":{"content":"Hel"}}]}\n' ...
                'data: {"choices":[{"delta":{"content":"lo"}}]}\n']);
            chunk = unicode2native(payload, 'UTF-8')';
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(streamer.ResponseText, 'Hello');
        end

        function incompleteThenRest_completesResponseText(testCase)
            % A chunk split mid-JSON must be buffered, then combined with
            % the remainder on the next call to produce a valid delta.
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            partial = iMakeChunk('{"choices":[{"delta":{"content":"par');
            streamer.doPutData(partial, false);
            rest = iMakeChunk('t"}}]}');
            streamer.doPutData(rest, false);
            testCase.verifyEqual(streamer.ResponseText, 'part');
            testCase.verifyEqual(streamer.Incomplete, "");
        end

        function textDelta_appendsAcrossMultipleCalls(testCase)
            % ResponseText must accumulate across successive putData calls,
            % not be reset each time.
            streamer = aisdk.llms.utils.ResponseStreamer(@(~) []);
            streamer.doPutData(iMakeChunk('{"choices":[{"delta":{"content":"A"}}]}'), false);
            streamer.doPutData(iMakeChunk('{"choices":[{"delta":{"content":"B"}}]}'), false);
            streamer.doPutData(iMakeChunk('{"choices":[{"delta":{"content":"C"}}]}'), false);
            testCase.verifyEqual(streamer.ResponseText, 'ABC');
        end

        function textDelta_callsStreamFcnOncePerDelta(testCase)
            received = {};
            streamer = aisdk.llms.utils.ResponseStreamer(@(txt) iCapture(txt));
            payload = sprintf(['data: {"choices":[{"delta":{"content":"one"}}]}\n' ...
                'data: {"choices":[{"delta":{"content":"two"}}]}\n' ...
                'data: {"choices":[{"delta":{"content":"three"}}]}\n']);
            chunk = unicode2native(payload, 'UTF-8')';
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(numel(received), 3);
            testCase.verifyEqual(received, {'one','two','three'});

            function iCapture(txt)
                received{end+1} = txt;
            end
        end
    end
end

function data = iMakeChunk(text)
    line = "data: " + text;
    data = unicode2native(char(line + newline), 'UTF-8')';
end
