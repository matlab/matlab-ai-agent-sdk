classdef tOllamaResponseStreamer < hResponseStreamerCommon
% Tests for ResponseStreamer with Ollama NDJSON streams.

%   Copyright 2026 The MathWorks, Inc.

    properties (Constant, Access=protected)
        StreamerFactory = @aisdk.client.internal.OllamaResponseStreamer
    end

    properties (TestParameter)
        TrailingLine = struct( ...
            "partialJSON", '{', ...
            "completeJSON", '{"message":{"content":"ignored"},"done":false}');
    end

    methods (Access = protected)
        function payload = textEvent(~, text)
            event = struct("message", struct("content", text), "done", false);
            payload = string(jsonencode(event));
        end

        function data = formatStreamEvent(~, event)
            data = hResponseStreamerUtils.ndjsonChunk(event);
        end

    end

    methods (Test, TestTags = {'Unit'})
        function doneTrue_returnsStop(testCase)
            streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);

            stop = streamer.doPutData(testCase.formatStreamEvent( ...
                '{"message":{"content":"done"},"done":true}'), false);

            testCase.verifyTrue(stop);
        end

        function doneTrue_discardsTrailingLine(testCase, TrailingLine)
            streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);
            chunk = [
                testCase.textChunk("Hello")
                testCase.formatStreamEvent('{"message":{"content":""},"done":true}')
                hResponseStreamerUtils.streamBytes(TrailingLine)
                ];

            stop = streamer.doPutData(chunk, false);
            testCase.verifyTrue(stop);
            % Flush the buffered tail as the HTTP consumer does at the end.
            streamer.doPutData(uint8.empty(0,1), false);

            testCase.verifyEqual(streamer.ResponseText, 'Hello');
            testCase.verifyEmpty(streamer.StreamError);
        end

        function errorEventAfterText_stopsStreamAndRecordsMessage(testCase)
            streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);
            streamer.doPutData(testCase.formatStreamEvent( ...
                '{"message":{"content":"Partial response"},"done":false}'), false);

            stop = streamer.doPutData(testCase.formatStreamEvent( ...
                '{"error":"backend failed"}'), false);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(streamer.ResponseText, 'Partial response');
            testCase.verifyEqual(streamer.StreamError, "backend failed");
        end

        function errorEvent_discardsTrailingLineAndPreservesError(testCase, TrailingLine)
            streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);
            chunk = [
                testCase.textChunk("Partial response")
                testCase.formatStreamEvent('{"error":"backend failed"}')
                hResponseStreamerUtils.streamBytes(TrailingLine)
                ];

            stop = streamer.doPutData(chunk, false);
            testCase.verifyTrue(stop);
            streamer.doPutData(uint8.empty(0,1), false);

            testCase.verifyEqual(streamer.ResponseText, 'Partial response');
            testCase.verifyEqual(streamer.StreamError, "backend failed");
        end

        function usageChunk_capturesUsage(testCase)
            streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);

            streamer.doPutData(testCase.formatStreamEvent( ...
                '{"message":{"content":""},"done":true,"prompt_eval_count":5,"eval_count":9}'), false);

            testCase.verifyEqual(streamer.Usage.prompt_eval_count, 5);
            testCase.verifyEqual(streamer.Usage.eval_count, 9);
        end

        function usageChunk_doesNotInvokeStreamFcn(testCase)
            calls = 0;
            streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) iBump());

            streamer.doPutData(testCase.formatStreamEvent( ...
                '{"message":{"content":""},"done":true,"prompt_eval_count":5,"eval_count":9}'), false);

            testCase.verifyEqual(calls, 0);

            function iBump()
                calls = calls + 1;
            end
        end

        function partialUsage_capturesAvailableFields(testCase)
            streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);

            streamer.doPutData(testCase.formatStreamEvent( ...
                '{"message":{"content":""},"done":true,"prompt_eval_count":42}'), false);

            testCase.verifyEqual(streamer.Usage.prompt_eval_count, 42);
            testCase.verifyFalse(isfield(streamer.Usage, "eval_count"));
        end

        function chunkWithoutUsageFields_leavesUsageUnset(testCase)
            streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);

            streamer.doPutData( ...
                testCase.formatStreamEvent('{"message":{"content":"hi"},"done":false}'), false);

            testCase.verifyEmpty(streamer.Usage);
        end

        function toolCallsMessage_isReconstructedInResponseData(testCase)
            streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);

            streamer.doPutData(testCase.formatStreamEvent( ...
                '{"message":{"content":"","tool_calls":[{"function":{"name":"add","arguments":{"a":1,"b":2}}}]},"done":true}'), false);

            data = streamer.mergeResponseData("");
            testCase.verifyClass(data.message.tool_calls, "cell");
            testCase.verifySize(data.message.tool_calls, [1 1]);
            testCase.verifyEqual(data.message.tool_calls{1}.function.name, 'add');
            testCase.verifyEqual(data.message.tool_calls{1}.function.arguments.a, 1);
        end

        function toolCalls_acrossChunks_areAccumulated(testCase)
            streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);
            first = struct("message", struct( ...
                "content", "", ...
                "tool_calls", {{ ...
                    toolCall("first"), ...
                    toolCall("second")}}), ...
                "done", false);
            second = struct("message", struct( ...
                "content", "", ...
                "tool_calls", {{toolCall("third")}}), ...
                "done", true);

            streamer.doPutData( ...
                testCase.formatStreamEvent(jsonencode(first)), false);
            streamer.doPutData( ...
                testCase.formatStreamEvent(jsonencode(second)), false);

            data = streamer.mergeResponseData("");
            testCase.verifyClass(data.message.tool_calls, "cell");
            testCase.verifySize(data.message.tool_calls, [3 1]);
            names = cellfun( ...
                @(call) string(call.function.name), ...
                data.message.tool_calls);
            testCase.verifyEqual(names, ["first"; "second"; "third"]);
        end

        function heterogeneousToolCalls_remainColumnCell(testCase)
            streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);
            event = ['{"message":{"content":"","tool_calls":[' ...
                '{"id":"call_1","function":{"name":"first","arguments":{}}},' ...
                '{"function":{"name":"second","arguments":{}}}' ...
                ']},"done":true}'];

            streamer.doPutData(testCase.formatStreamEvent(event), false);

            toolCalls = streamer.mergeResponseData("").message.tool_calls;
            testCase.verifyClass(toolCalls, "cell");
            testCase.verifySize(toolCalls, [2 1]);
            testCase.verifyEqual(toolCalls{1}.id, 'call_1');
            testCase.verifyEqual(toolCalls{2}.function.name, 'second');
        end

        function mergeResponseData_rebuildsMessageAndUsage(testCase)
            streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);
            toolCall = struct("function", struct( ...
                "name", "getWeather", ...
                "arguments", struct("city", "London")));
            events = {
                struct( ...
                    "message", struct("role", "assistant", "content", "Hello "), ...
                    "done", false)
                struct( ...
                    "message", struct( ...
                        "role", "assistant", ...
                        "content", "world", ...
                        "tool_calls", {{toolCall}}), ...
                    "done", true, ...
                    "prompt_eval_count", 5, ...
                    "eval_count", 9)
                };
            for k = 1:numel(events)
                streamer.doPutData( ...
                    testCase.formatStreamEvent(jsonencode(events{k})), false);
            end

            data = streamer.mergeResponseData("");

            testCase.verifyEqual(data.message.role, 'assistant');
            testCase.verifyEqual(data.message.content, 'Hello world');
            testCase.verifyClass(data.message.tool_calls, "cell");
            testCase.verifySize(data.message.tool_calls, [1 1]);
            testCase.verifyEqual(data.message.tool_calls{1}.function.name, 'getWeather');
            testCase.verifyTrue(data.done);
            testCase.verifyEqual(data.prompt_eval_count, 5);
            testCase.verifyEqual(data.eval_count, 9);
        end
    end
end

function call = toolCall(name)
call = struct("function", struct("name", name, "arguments", struct()));
end
