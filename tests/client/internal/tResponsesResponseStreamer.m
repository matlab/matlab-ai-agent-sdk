classdef tResponsesResponseStreamer < hSSEStreamerTests
% Tests for ResponseStreamer with OpenAI Responses API SSE streams.

%   Copyright 2026 The MathWorks, Inc.

    properties (Constant, Access=protected)
        StreamerFactory = @aisdk.client.internal.ResponsesResponseStreamer
    end

    properties (TestParameter)
        TrailingLine = struct( ...
            "partialJSON", 'data: {', ...
            "completeJSON", 'data: {"type":"response.output_text.delta","item_id":"msg_1","delta":"ignored"}');

        ErrorEvent = struct( ...
            "error", '{"type":"error","message":"backend failed"}', ...
            "responseFailed", '{"type":"response.failed","response":{"error":{"message":"backend failed"}}}');
    end

    methods (Access = protected)
        function payload = textEvent(~, text)
            event = struct("type", "response.output_text.delta", ...
                "item_id", "msg_1", "delta", text);
            payload = string(jsonencode(event));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function chatCompletionsEvent_stopsStreamAndRejectsResponse(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            endpoint = "https://example.invalid/v1/responses";
            streamer.URI = matlab.net.URI(endpoint);
            chunk = [
                testCase.formatStreamEvent('{"choices":[{"delta":{"content":"Hello"}}]}')
                testCase.textChunk("This must not be processed")
                hResponseStreamerUtils.streamBytes('data: {')
                ];

            stop = streamer.doPutData(chunk, false);
            % HTTP consumers receive a final empty chunk after requesting a stop.
            streamer.doPutData(uint8.empty(0,1), false);

            testCase.verifyTrue(stop);
            testCase.verifyEmpty(streamer.ResponseText);
            testCase.verifyEmpty(streamer.StreamedOutputItems);
            testCase.verifyError(@() streamer.mergeResponseData(""), ...
                "aisdk:unreadableResponse");
        end

        function unknownTypedEvent_doesNotStopStream(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            chunk = [
                testCase.formatStreamEvent('{"type":"response.future_event"}')
                testCase.textChunk("Hello")
                ];

            stop = streamer.doPutData(chunk, false);
            data = streamer.mergeResponseData("");

            testCase.verifyFalse(stop);
            testCase.verifyEqual(data.output{1}.content{1}.text, "Hello");
        end

        function completed_capturesUsage(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);

            streamer.doPutData(testCase.formatStreamEvent( ...
                '{"type":"response.completed","response":{"usage":{"input_tokens":3,"output_tokens":4,"total_tokens":7}}}'), false);

            testCase.verifyEqual(streamer.Usage.usage.input_tokens, 3);
            testCase.verifyEqual(streamer.Usage.usage.output_tokens, 4);
        end

        function completedUsage_doesNotInvokeStreamFcn(testCase)
            calls = 0;
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) iBump());

            streamer.doPutData(testCase.formatStreamEvent( ...
                '{"type":"response.completed","response":{"usage":{"input_tokens":3,"output_tokens":4,"total_tokens":7}}}'), false);

            testCase.verifyEqual(calls, 0);

            function iBump()
                calls = calls + 1;
            end
        end

        function errorEvent_stopsStream(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            chunk = hResponseStreamerUtils.streamBytes([ ...
                'event: error' newline ...
                'data: {"type":"error","code":"server_error","message":"The server had an error.","param":null}' newline]);

            stop = streamer.doPutData(chunk, false);

            testCase.verifyTrue(stop);
        end

        function errorEvent_recordsErrorMessage(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            chunk = hResponseStreamerUtils.streamBytes([ ...
                'event: error' newline ...
                'data: {"type":"error","code":"server_error","message":"The server had an error.","param":null}' newline]);

            streamer.doPutData(chunk, false);

            testCase.verifyEqual(streamer.StreamError, "The server had an error.");
        end

        function errorEventAfterText_stopsStreamAndRecordsMessage(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            streamer.doPutData(testCase.formatStreamEvent( ...
                '{"type":"response.output_text.delta","item_id":"msg_1","delta":"Partial response"}'), false);

            stop = streamer.doPutData(testCase.formatStreamEvent( ...
                '{"type":"error","code":"server_error","message":"backend failed"}'), false);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(streamer.ResponseText, 'Partial response');
            testCase.verifyEqual(streamer.StreamError, "backend failed");
        end

        function errorEvent_discardsTrailingLineAndPreservesError(testCase, ErrorEvent, TrailingLine)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            chunk = [
                testCase.textChunk("Partial response")
                testCase.formatStreamEvent(ErrorEvent)
                hResponseStreamerUtils.streamBytes(TrailingLine)
                ];

            stop = streamer.doPutData(chunk, false);
            testCase.verifyTrue(stop);
            % Flush the buffered tail as the HTTP consumer does at the end.
            streamer.doPutData(uint8.empty(0,1), false);

            testCase.verifyEqual(streamer.ResponseText, 'Partial response');
            testCase.verifyEqual(streamer.StreamError, "backend failed");
        end

        function failedEvent_stopsStreamAndRecordsErrorMessage(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            chunk = hResponseStreamerUtils.streamBytes([ ...
                'event: response.failed' newline ...
                'data: {"type":"response.failed","response":{"id":"resp_1",' ...
                '"status":"failed","error":{"code":"server_error",' ...
                '"message":"The model failed to respond."}}}' newline]);

            stop = streamer.doPutData(chunk, false);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(streamer.StreamError, "The model failed to respond.");
        end

        function errorEventWithoutMessage_recordsEventJSON(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            chunk = hResponseStreamerUtils.streamBytes([ ...
                'event: error' newline ...
                'data: {"type":"error","code":"server_error","param":null}' newline]);

            stop = streamer.doPutData(chunk, false);

            testCase.verifyTrue(stop);
            testCase.verifySubstring(streamer.StreamError, "server_error");
        end

        function failedEventWithoutErrorMessage_recordsEventJSON(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            chunk = hResponseStreamerUtils.streamBytes([ ...
                'event: response.failed' newline ...
                'data: {"type":"response.failed","response":{"id":"resp_1",' ...
                '"status":"failed","error":null}}' newline]);

            stop = streamer.doPutData(chunk, false);

            testCase.verifyTrue(stop);
            testCase.verifySubstring(streamer.StreamError, "resp_1");
        end

        function splitInsideEventLine_reassembles(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            first = hResponseStreamerUtils.streamBytes([ ...
                'event: response.output_text.delta' newline ...
                'data: {"type":"response.output_text.delta","delta":"Hi"}' newline ...
                'event: response.comp']);
            rest = hResponseStreamerUtils.streamBytes([ ...
                'leted' newline ...
                'data: {"type":"response.completed","response":' ...
                '{"usage":{"input_tokens":3,"output_tokens":4,"total_tokens":7}}}' newline]);

            streamer.doPutData(first, false);
            streamer.doPutData(rest, false);

            testCase.verifyEqual(streamer.ResponseText, 'Hi');
            testCase.verifyEqual(streamer.Usage.usage.input_tokens, 3);
            testCase.verifyEqual(streamer.Usage.usage.output_tokens, 4);
        end

        function splitInsideDataLine_reassembles(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            first = hResponseStreamerUtils.streamBytes([ ...
                'data: {"type":"response.completed","response":' ...
                '{"usage":{"input_tokens":11,']);
            rest = hResponseStreamerUtils.streamBytes(['"output_tokens":22,"total_tokens":33}}}' newline]);

            streamer.doPutData(first, false);
            streamer.doPutData(rest, false);

            testCase.verifyEqual(streamer.Usage.usage.input_tokens, 11);
            testCase.verifyEqual(streamer.Usage.usage.output_tokens, 22);
        end

        function textDeltas_goToResponseTextAndOneMessageItem(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            payload = hResponseStreamerUtils.streamBytes([ ...
                'data: {"type":"response.output_text.delta","item_id":"msg_1","delta":"Hi"}' newline ...
                'data: {"type":"response.output_text.delta","item_id":"msg_1","delta":" there"}' newline]);

            streamer.doPutData(payload, false);

            testCase.verifyEqual(streamer.ResponseText, 'Hi there');
            testCase.assertNumElements(streamer.StreamedOutputItems, 1);
            item = streamer.StreamedOutputItems{1};
            testCase.verifyEqual(item.type, "message");
            testCase.verifyEqual(item.content{1}.text, "Hi there");
        end

        function textAroundFunctionCall_keepsItemOrder(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            payload = hResponseStreamerUtils.streamBytes([ ...
                'data: {"type":"response.output_item.added","output_index":0,"item":' ...
                '{"id":"msg_1","type":"message","role":"assistant","content":[]}}' newline ...
                'data: {"type":"response.output_text.delta","item_id":"msg_1","delta":"Let me check."}' newline ...
                'data: {"type":"response.output_item.added","output_index":1,"item":' ...
                '{"id":"fc_1","type":"function_call","call_id":"call_1","name":"getWeather","arguments":""}}' newline ...
                'data: {"type":"response.function_call_arguments.done","item_id":"fc_1",' ...
                '"arguments":' jsonencode('{"city":"Paris"}') '}' newline ...
                'data: {"type":"response.output_item.added","output_index":2,"item":' ...
                '{"id":"msg_2","type":"message","role":"assistant","content":[]}}' newline ...
                'data: {"type":"response.output_text.delta","item_id":"msg_2","delta":"Done."}' newline]);

            streamer.doPutData(payload, false);

            items = streamer.StreamedOutputItems;
            testCase.assertNumElements(items, 3);
            testCase.verifyEqual(items{1}.content{1}.text, "Let me check.");
            testCase.verifyEqual(items{2}.call_id, "call_1");
            testCase.verifyEqual(items{2}.arguments, "{""city"":""Paris""}");
            testCase.verifyEqual(items{3}.content{1}.text, "Done.");
        end

        function functionCall_assembledFromArgumentDeltas(testCase)
            received = {};
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(txt) iCapture(txt));
            payload = hResponseStreamerUtils.streamBytes([ ...
                'data: {"type":"response.output_item.added","output_index":0,"item":' ...
                '{"id":"fc_1","type":"function_call","call_id":"call_1","name":"getWeather","arguments":""}}' newline ...
                'data: {"type":"response.function_call_arguments.delta","item_id":"fc_1","delta":' ...
                jsonencode('{"city":') '}' newline ...
                'data: {"type":"response.function_call_arguments.delta","item_id":"fc_1","delta":' ...
                jsonencode('"Paris"}') '}' newline]);

            streamer.doPutData(payload, false);

            testCase.verifyNumElements(streamer.StreamedOutputItems, 1);
            item = streamer.StreamedOutputItems{1};
            testCase.verifyEqual(item.type, "function_call");
            testCase.verifyEqual(item.call_id, "call_1");
            testCase.verifyEqual(item.name, "getWeather");
            testCase.verifyEqual(item.arguments, "{""city"":""Paris""}");
            testCase.verifyEmpty(received);
            testCase.verifyEmpty(streamer.ResponseText);

            function iCapture(txt)
                received{end+1} = txt;
            end
        end

        function functionCallArguments_preserveDataPrefix(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            payload = hResponseStreamerUtils.streamBytes([ ...
                'data: {"type":"response.output_item.added","output_index":0,"item":' ...
                '{"id":"fc_1","type":"function_call","call_id":"call_1","name":"search","arguments":""}}' newline ...
                'data: {"type":"response.function_call_arguments.delta","item_id":"fc_1",' ...
                '"delta":' jsonencode('{"query":"literal data: value"}') '}' newline]);

            streamer.doPutData(payload, false);

            testCase.verifyNumElements(streamer.StreamedOutputItems, 1);
            testCase.verifyEqual( ...
                streamer.StreamedOutputItems{1}.arguments, ...
                "{""query"":""literal data: value""}");
        end

        function functionCallArgumentsDone_replacesDeltas(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            payload = hResponseStreamerUtils.streamBytes([ ...
                'data: {"type":"response.output_item.added","output_index":0,"item":' ...
                '{"id":"fc_1","type":"function_call","call_id":"call_1","name":"getWeather","arguments":""}}' newline ...
                'data: {"type":"response.function_call_arguments.delta","item_id":"fc_1","delta":' ...
                jsonencode('{"city":') '}' newline ...
                'data: {"type":"response.function_call_arguments.done","item_id":"fc_1",' ...
                '"arguments":' jsonencode('{"city":"Paris"}') '}' newline]);

            streamer.doPutData(payload, false);

            testCase.verifyNumElements(streamer.StreamedOutputItems, 1);
            testCase.verifyEqual(streamer.StreamedOutputItems{1}.arguments, "{""city"":""Paris""}");
        end

        function outputItemDone_capturesCompleteFunctionCall(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);

            streamer.doPutData(testCase.formatStreamEvent([ ...
                '{"type":"response.output_item.done","output_index":0,"item":' ...
                '{"id":"fc_9","type":"function_call","call_id":"call_9","name":"toolA",' ...
                '"arguments":"{\"x\":1}"}}']), false);

            testCase.verifyNumElements(streamer.StreamedOutputItems, 1);
            testCase.verifyEqual(streamer.StreamedOutputItems{1}.call_id, "call_9");
            testCase.verifyEqual(streamer.StreamedOutputItems{1}.name, "toolA");
            testCase.verifyEqual(streamer.StreamedOutputItems{1}.arguments, "{""x"":1}");
        end

        function parallelFunctionCalls_assembledInArrivalOrder(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            payload = hResponseStreamerUtils.streamBytes([ ...
                'data: {"type":"response.output_item.added","output_index":0,"item":' ...
                '{"id":"fc_1","type":"function_call","call_id":"call_1","name":"toolA","arguments":""}}' newline ...
                'data: {"type":"response.output_item.added","output_index":1,"item":' ...
                '{"id":"fc_2","type":"function_call","call_id":"call_2","name":"toolB","arguments":""}}' newline ...
                'data: {"type":"response.function_call_arguments.delta","item_id":"fc_2","delta":' ...
                jsonencode('{"y":2}') '}' newline ...
                'data: {"type":"response.function_call_arguments.delta","item_id":"fc_1","delta":' ...
                jsonencode('{"x":1}') '}' newline]);

            streamer.doPutData(payload, false);

            testCase.verifyNumElements(streamer.StreamedOutputItems, 2);
            testCase.verifyEqual(streamer.StreamedOutputItems{1}.name, "toolA");
            testCase.verifyEqual(streamer.StreamedOutputItems{1}.arguments, "{""x"":1}");
            testCase.verifyEqual(streamer.StreamedOutputItems{2}.name, "toolB");
            testCase.verifyEqual(streamer.StreamedOutputItems{2}.arguments, "{""y"":2}");
        end

        function functionCallSplitAcrossChunks_reassembles(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            first = hResponseStreamerUtils.streamBytes([ ...
                'data: {"type":"response.output_item.added","output_index":0,"item":' ...
                '{"id":"fc_1","type":"function_call","call_id":"call_1","name":"toolA","arguments":""}}' newline ...
                'data: {"type":"response.function_call_arguments.delta","item_id":"fc_1",']);
            rest = hResponseStreamerUtils.streamBytes(['"delta":' jsonencode('{"x":1}') '}' newline]);

            streamer.doPutData(first, false);
            streamer.doPutData(rest, false);

            testCase.verifyNumElements(streamer.StreamedOutputItems, 1);
            testCase.verifyEqual(streamer.StreamedOutputItems{1}.arguments, "{""x"":1}");
        end
    end
end
