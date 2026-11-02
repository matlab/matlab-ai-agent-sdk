classdef tChatCompletionsResponseStreamer < hSSEStreamerTests
% Tests for ResponseStreamer with OpenAI Chat Completions SSE streams.

%   Copyright 2026 The MathWorks, Inc.

    properties (Constant, Access=protected)
        StreamerFactory = @aisdk.client.internal.ChatCompletionsResponseStreamer
    end

    properties (TestParameter)
        TrailingLine = struct( ...
            "partialJSON", 'data: {', ...
            "completeJSON", 'data: {"choices":[{"delta":{"content":"ignored"}}]}');
    end

    methods (Access = protected)
        function payload = textEvent(~, text)
            event = struct("choices", {{struct("delta", struct("content", text))}});
            payload = string(jsonencode(event));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function doneMessage_returnsStopTrue(testCase)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);

            stop = streamer.doPutData(testCase.formatStreamEvent('[DONE]'), false);

            testCase.verifyTrue(stop);
        end

        function doneMessage_discardsTrailingLine(testCase, TrailingLine)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);
            chunk = [
                testCase.textChunk("Hello")
                testCase.formatStreamEvent('[DONE]')
                hResponseStreamerUtils.streamBytes(TrailingLine)
                ];

            stop = streamer.doPutData(chunk, false);
            testCase.verifyTrue(stop);
            % Flush the buffered tail as the HTTP consumer does at the end.
            streamer.doPutData(uint8.empty(0,1), false);

            testCase.verifyEqual(streamer.ResponseText, 'Hello');
            testCase.verifyEmpty(streamer.StreamError);
        end

        function finishReasonStop_doesNotTerminateStream(testCase)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);

            stop = streamer.doPutData(testCase.formatStreamEvent( ...
                '{"choices":[{"finish_reason":"stop","delta":{"content":""}}]}'), false);

            testCase.verifyFalse(stop);
        end

        function finishReasonToolCalls_doesNotTerminateStream(testCase)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);

            stop = streamer.doPutData(testCase.formatStreamEvent( ...
                '{"choices":[{"finish_reason":"tool_calls","delta":{"content":""}}]}'), false);

            testCase.verifyFalse(stop);
        end

        function usageChunk_capturesUsage(testCase)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);

            streamer.doPutData(testCase.formatStreamEvent( ...
                '{"choices":[],"usage":{"prompt_tokens":7,"completion_tokens":11,"total_tokens":18}}'), false);

            testCase.verifyEqual(streamer.Usage.usage.prompt_tokens, 7);
            testCase.verifyEqual(streamer.Usage.usage.completion_tokens, 11);
        end

        function emptyUsageObject_leavesUsageUnset(testCase)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);

            streamer.doPutData( ...
                testCase.formatStreamEvent('{"choices":[],"usage":{}}'), false);

            testCase.verifyEmpty(streamer.Usage);
        end

        function errorEventAfterText_stopsStreamAndRecordsMessage(testCase)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);
            streamer.doPutData(testCase.formatStreamEvent( ...
                '{"choices":[{"delta":{"content":"Partial response"}}]}'), false);

            stop = streamer.doPutData(testCase.formatStreamEvent( ...
                '{"error":{"message":"backend failed"}}'), false);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(streamer.ResponseText, 'Partial response');
            testCase.verifyEqual(streamer.StreamError, "backend failed");
        end

        function errorEvent_discardsTrailingLineAndPreservesError(testCase, TrailingLine)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);
            chunk = [
                testCase.textChunk("Partial response")
                testCase.formatStreamEvent('{"error":{"message":"backend failed"}}')
                hResponseStreamerUtils.streamBytes(TrailingLine)
                ];

            stop = streamer.doPutData(chunk, false);
            testCase.verifyTrue(stop);
            streamer.doPutData(uint8.empty(0,1), false);

            testCase.verifyEqual(streamer.ResponseText, 'Partial response');
            testCase.verifyEqual(streamer.StreamError, "backend failed");
        end

        function usageChunk_doesNotInvokeStreamFcn(testCase)
            calls = 0;
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) iBump());

            streamer.doPutData(testCase.formatStreamEvent( ...
                '{"choices":[],"usage":{"prompt_tokens":1,"completion_tokens":2,"total_tokens":3}}'), false);

            testCase.verifyEqual(calls, 0);

            function iBump()
                calls = calls + 1;
            end
        end

        function toolCallDelta_buildsToolCall(testCase)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);

            streamer.doPutData(testCase.formatStreamEvent( ...
                '{"choices":[{"delta":{"tool_calls":{"index":0,"id":"call_1","type":"function","function":{"name":"add","arguments":""}}}}]}'), false);

            result = streamer.mergeResponseData("").choices.message.tool_calls;
            testCase.verifyEqual(result{1}.id, 'call_1');
            testCase.verifyEqual(result{1}.function.name, 'add');
        end

        function toolCallArgDelta_appendsArguments(testCase)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);

            streamer.doPutData(testCase.formatStreamEvent( ...
                '{"choices":[{"delta":{"tool_calls":{"index":0,"id":"call_1","type":"function","function":{"name":"add","arguments":"{"}}}}]}'), false);
            streamer.doPutData(testCase.formatStreamEvent( ...
                '{"choices":[{"delta":{"tool_calls":{"index":0,"function":{"arguments":"\"a\":1}"}}}}]}'), false);

            result = streamer.mergeResponseData("").choices.message.tool_calls;
            testCase.verifyEqual(result{1}.function.arguments, '{"a":1}');
        end

        function mergeResponseData_rebuildsParallelToolCalls(testCase)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);
            events = {
                '{"choices":[{"delta":{"role":"assistant","content":null,"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"getWeather","arguments":""}}]},"finish_reason":null}]}'
                '{"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"{\"city\":\"Oslo\"}"}}]},"finish_reason":null}]}'
                '{"choices":[{"delta":{"tool_calls":[{"index":1,"id":"call_2","type":"function","function":{"name":"getWeather","arguments":""}}]},"finish_reason":null}]}'
                '{"choices":[{"delta":{"tool_calls":[{"index":1,"function":{"arguments":"{\"city\":\"London\"}"}}]},"finish_reason":null}]}'
                '{"choices":[{"delta":{},"finish_reason":"tool_calls"}]}'
                '{"choices":[],"usage":{"prompt_tokens":7,"completion_tokens":11,"total_tokens":18}}'
                };
            for k = 1:numel(events)
                streamer.doPutData(testCase.formatStreamEvent(events{k}), false);
            end

            data = streamer.mergeResponseData("");
            toolCalls = data.choices.message.tool_calls;

            testCase.verifyClass(toolCalls, "cell");
            testCase.verifySize(toolCalls, [2 1]);
            testCase.verifyNumElements(toolCalls, 2);
            testCase.verifyEqual(toolCalls{1}.id, 'call_1');
            testCase.verifyEqual(toolCalls{1}.function.arguments, '{"city":"Oslo"}');
            testCase.verifyEqual(toolCalls{2}.id, 'call_2');
            testCase.verifyEqual(toolCalls{2}.function.arguments, '{"city":"London"}');
            testCase.verifyEqual(data.choices.finish_reason, 'tool_calls');
            testCase.verifyEqual(data.usage.total_tokens, 18);
        end

        function heterogeneousToolCallsInOneEvent_areProcessed(testCase)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);
            event = ['{"choices":[{"delta":{"tool_calls":[' ...
                '{"index":0,"id":"call_1","type":"function",' ...
                '"function":{"name":"first","arguments":""}},' ...
                '{"index":1,"function":{"arguments":"{\"x\":1}"}}' ...
                ']}}]}'];

            streamer.doPutData(testCase.formatStreamEvent(event), false);

            toolCalls = streamer.mergeResponseData("").choices.message.tool_calls;
            testCase.verifyClass(toolCalls, "cell");
            testCase.verifySize(toolCalls, [2 1]);
            testCase.verifyNumElements(toolCalls, 2);
            testCase.verifyEqual(toolCalls{1}.id, 'call_1');
            testCase.verifyEqual(toolCalls{2}.function.arguments, '{"x":1}');
        end

        function textAndToolCallsInSameDelta_areBothPreserved(testCase)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);
            event = ['{"choices":[{"delta":{' ...
                '"role":"assistant",' ...
                '"content":"Let me check.",' ...
                '"tool_calls":[{"index":0,"id":"call_1","type":"function",' ...
                '"function":{"name":"getWeather","arguments":"{\"city\":\"Oslo\"}"}}]' ...
                '},"finish_reason":"tool_calls"}]}'];

            streamer.doPutData(testCase.formatStreamEvent(event), false);

            data = streamer.mergeResponseData("");
            testCase.verifyEqual(data.choices.message.content, 'Let me check.');
            testCase.verifyNumElements(data.choices.message.tool_calls, 1);
            testCase.verifyEqual( ...
                data.choices.message.tool_calls{1}.function.name, ...
                'getWeather');
        end

        function crlfLineEndings_parsesEventsAndRecognisesDone(testCase)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);
            crlf = [char(13) newline];
            chunk = hResponseStreamerUtils.streamBytes([ ...
                'data: {"choices":[{"delta":{"content":"Hel"}}]}' crlf crlf ...
                'data: {"choices":[{"delta":{"content":"lo"}}]}' crlf crlf ...
                'data: [DONE]' crlf crlf]);

            stop = streamer.doPutData(chunk, false);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(streamer.ResponseText, 'Hello');
        end

        function commentLineBeforePartialLine_keepsPartialLine(testCase)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);
            first = hResponseStreamerUtils.streamBytes([ ...
                'data: {"choices":[{"delta":{"content":"Hel"}}]}' newline ...
                ': some comment' newline ...
                'data: {"choices":[{"delta":{"content":"lo']);
            rest = hResponseStreamerUtils.streamBytes(['"}}]}' newline]);

            streamer.doPutData(first, false);
            streamer.doPutData(rest, false);

            testCase.verifyEqual(streamer.ResponseText, 'Hello');
        end
    end
end
