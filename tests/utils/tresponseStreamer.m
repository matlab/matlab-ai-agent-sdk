classdef tresponseStreamer < matlab.unittest.TestCase
% Tests for aisdk.utils.ResponseStreamer.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        % SSE lines other than "data:" lines.
        NonDataLine = struct( ...
            "comment", ": some comment", ...
            "event",   "event: response.output_text.delta", ...
            "id",      "id: 42", ...
            "retry",   "retry: 3000");
    end

    methods (Test, TestTags = {'Unit'})
        function nonDataLine_isIgnored(testCase, NonDataLine)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeRawChunk(['data: {"choices":[{"delta":{"content":"Hel"}}]}\n' ...
                char(NonDataLine) '\n' ...
                'data: {"choices":[{"delta":{"content":"lo"}}]}\n']);
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(streamer.ResponseText, 'Hello');
        end
    end

    methods (Test, TestTags = {'Unit'})
        function textDelta_appendsToResponseText(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"choices":[{"delta":{"content":"Hello"}}]}');
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(streamer.ResponseText, 'Hello');
        end

        function textDelta_callsStreamFcn(testCase)
            received = {};
            streamer = aisdk.utils.ResponseStreamer(@(txt) iCapture(txt));
            chunk = iMakeChunk('{"choices":[{"delta":{"content":"Hi"}}]}');
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(received{end}, 'Hi');

            function iCapture(txt)
                received{end+1} = txt;
            end
        end

        function doneMessage_returnsStopTrue(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('[DONE]');
            stop = streamer.doPutData(chunk, false);
            testCase.verifyTrue(stop);
        end

        function finishReasonStop_doesNotTerminateStream(testCase)
            % finish_reason no longer terminates the stream; the trailing
            % usage chunk (with include_usage=true) arrives after it, and
            % [DONE] is the real terminator.
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"choices":[{"finish_reason":"stop","delta":{"content":""}}]}');
            stop = streamer.doPutData(chunk, false);
            testCase.verifyFalse(stop);
        end

        function usageChunk_capturesUsage(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"choices":[],"usage":{"prompt_tokens":7,"completion_tokens":11,"total_tokens":18}}');
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(streamer.Usage.usage.prompt_tokens, 7);
            testCase.verifyEqual(streamer.Usage.usage.completion_tokens, 11);
        end

        function ollamaDoneChunk_capturesUsage(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"message":{"content":""},"done":true,"prompt_eval_count":5,"eval_count":9}');
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(streamer.Usage.prompt_eval_count, 5);
            testCase.verifyEqual(streamer.Usage.eval_count, 9);
        end

        function toolCallDelta_buildsToolCallJSON(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"choices":[{"delta":{"tool_calls":{"id":"call_1","type":"function","function":{"name":"add","arguments":""}}}}]}');
            streamer.doPutData(chunk, false);
            result = jsondecode(streamer.ResponseText);
            testCase.verifyEqual(result.id, 'call_1');
            testCase.verifyEqual(result.function.name, 'add');
        end

        function toolCallArgDelta_appendsArguments(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            firstChunk = iMakeChunk('{"choices":[{"delta":{"tool_calls":{"id":"call_1","type":"function","function":{"name":"add","arguments":"{"}}}}]}');
            streamer.doPutData(firstChunk, false);
            argChunk = iMakeChunk('{"choices":[{"delta":{"tool_calls":{"function":{"arguments":"\"a\":1}"}}}}]}');
            streamer.doPutData(argChunk, false);
            result = jsondecode(streamer.ResponseText);
            testCase.verifyEqual(result.function.arguments, '{"a":1}');
        end

        function incompleteJSON_buffersForNextCall(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            partial = iMakeRawChunk('data: {"choices":[{"delta":{"content":"par');
            streamer.doPutData(partial, false);
            testCase.verifyEqual(native2unicode(streamer.Incomplete', 'UTF-8'), ...
                'data: {"choices":[{"delta":{"content":"par');
        end

        function invalidJSON_midStream_throwsError(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk(sprintf('not-json\n{"choices":[{"delta":{"content":"ok"}}]}'));
            testCase.verifyError( ...
                @() streamer.doPutData(chunk, false), ...
                "aisdk:stream:responseStreamer:InvalidInput");
        end

        function ollamaFormat_extractsMessageContent(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"message":{"content":"Hello from Ollama"},"done":false}');
            streamer.doPutData(chunk, false);
            testCase.verifySubstring(streamer.ResponseText, "Hello from Ollama");
        end

        function ollamaFormat_doneTrue_returnsStop(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"message":{"content":"done"},"done":true}');
            stop = streamer.doPutData(chunk, false);
            testCase.verifyTrue(stop);
        end

        function finishReasonToolCalls_doesNotTerminateStream(testCase)
            % Parallel to finishReasonStop_doesNotTerminateStream: the tool_calls
            % variant of finish_reason must not terminate the stream either
            % — the trailing usage chunk still needs to be consumed.
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"choices":[{"finish_reason":"tool_calls","delta":{"content":""}}]}');
            stop = streamer.doPutData(chunk, false);
            testCase.verifyFalse(stop);
        end

        function emptyUsageObject_leavesUsageUnset(testCase)
            % A "usage":{} object should not populate Usage — the guard
            % requires fieldnames(json.usage) to be non-empty.
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"choices":[],"usage":{}}');
            streamer.doPutData(chunk, false);
            testCase.verifyEmpty(streamer.Usage);
        end

        function usageChunk_doesNotInvokeStreamFcn(testCase)
            % A usage-only chunk (empty choices) must not fire the stream
            % callback — that would emit a spurious empty token to the UI.
            calls = 0;
            streamer = aisdk.utils.ResponseStreamer(@(~) iBump());
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
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"message":{"content":""},"done":true,"prompt_eval_count":42}');
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(streamer.Usage.prompt_eval_count, 42);
            testCase.verifyFalse(isfield(streamer.Usage, "eval_count"));
        end

        function ollamaChunkWithoutUsageFields_leavesUsageUnset(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"message":{"content":"hi"},"done":false}');
            streamer.doPutData(chunk, false);
            testCase.verifyEmpty(streamer.Usage);
        end

        function ollamaToolCallsMessage_writesJSONToResponseText(testCase)
            % Ollama returns tool calls under message.tool_calls; the
            % streamer serialises them into ResponseText for the client.
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk('{"message":{"content":"","tool_calls":[{"function":{"name":"add","arguments":{"a":1,"b":2}}}]},"done":true}');
            streamer.doPutData(chunk, false);
            decoded = jsondecode(streamer.ResponseText);
            testCase.verifyEqual(decoded.function.name, 'add');
            testCase.verifyEqual(decoded.function.arguments.a, 1);
        end

        function multipleSSELines_processedInOneCall(testCase)
            % One putData call can deliver more than one SSE event; each
            % "data: ..." line must be parsed independently.
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            payload = sprintf(['data: {"choices":[{"delta":{"content":"Hel"}}]}\n' ...
                'data: {"choices":[{"delta":{"content":"lo"}}]}\n']);
            chunk = unicode2native(payload, 'UTF-8')';
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(streamer.ResponseText, 'Hello');
        end

        function crlfLineEndings_parsesEventsAndRecognisesDone(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeRawChunk(['data: {"choices":[{"delta":{"content":"Hel"}}]}\r\n\r\n' ...
                'data: {"choices":[{"delta":{"content":"lo"}}]}\r\n\r\n' ...
                'data: [DONE]\r\n\r\n']);
            stop = streamer.doPutData(chunk, false);
            testCase.verifyTrue(stop);
            testCase.verifyEqual(streamer.ResponseText, 'Hello');
        end

        function incompleteThenRest_completesResponseText(testCase)
            % A chunk split mid-JSON must be buffered, then combined with
            % the remainder on the next call to produce a valid delta.
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            partial = iMakeRawChunk('data: {"choices":[{"delta":{"content":"par');
            streamer.doPutData(partial, false);
            rest = iMakeRawChunk('t"}}]}\n');
            streamer.doPutData(rest, false);
            testCase.verifyEqual(streamer.ResponseText, 'part');
            testCase.verifyEmpty(streamer.Incomplete);
        end

        function finalLineWithoutNewline_isProcessedAtEndOfStream(testCase)
            % An empty putData call marks the end of the stream.
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            streamer.doPutData(iMakeRawChunk('data: {"choices":[{"delta":{"content":"Hi"}}]}'), false);
            streamer.doPutData(uint8.empty(0,1), false);
            testCase.verifyEqual(streamer.ResponseText, 'Hi');
        end

        function multiByteCharacterSplitAcrossChunks_reassembles(testCase)
            % The chunk boundary falls between the two UTF-8 bytes of an
            % a-umlaut.
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            sseLine = ['data: {"choices":[{"delta":{"content":"' char(228) '"}}]}' newline];
            bytes = unicode2native(sseLine, 'UTF-8')';
            splitAt = find(bytes == 0xC3, 1);
            streamer.doPutData(bytes(1:splitAt), false);
            streamer.doPutData(bytes(splitAt+1:end), false);
            testCase.verifyEqual(streamer.ResponseText, char(228));
        end

        function commentLineBeforePartialLine_keepsPartialLine(testCase)
            % An SSE comment line is followed by a data line that the chunk
            % boundary splits. Lines starting with ":" are SSE comments, which
            % clients ignore. Some OpenAI-compatible endpoints send them as
            % heartbeats, for example OpenRouter's ": OPENROUTER PROCESSING".
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            first = iMakeRawChunk(['data: {"choices":[{"delta":{"content":"Hel"}}]}\n' ...
                ': some comment\n' ...
                'data: {"choices":[{"delta":{"content":"lo']);
            rest = iMakeRawChunk('"}}]}\n');
            streamer.doPutData(first, false);
            streamer.doPutData(rest, false);
            testCase.verifyEqual(streamer.ResponseText, 'Hello');
        end

        function textDelta_appendsAcrossMultipleCalls(testCase)
            % ResponseText must accumulate across successive putData calls,
            % not be reset each time.
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            streamer.doPutData(iMakeChunk('{"choices":[{"delta":{"content":"A"}}]}'), false);
            streamer.doPutData(iMakeChunk('{"choices":[{"delta":{"content":"B"}}]}'), false);
            streamer.doPutData(iMakeChunk('{"choices":[{"delta":{"content":"C"}}]}'), false);
            testCase.verifyEqual(streamer.ResponseText, 'ABC');
        end

        function textDelta_callsStreamFcnOncePerDelta(testCase)
            received = {};
            streamer = aisdk.utils.ResponseStreamer(@(txt) iCapture(txt));
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

        %% Responses API streaming
        function responsesTextDelta_appendsAndCallsStreamFcn(testCase)
            received = {};
            streamer = aisdk.utils.ResponseStreamer(@(txt) iCapture(txt));
            chunk = iMakeChunk('{"type":"response.output_text.delta","delta":"Hi"}');
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(streamer.ResponseText, 'Hi');
            testCase.verifyEqual(received{end}, 'Hi');

            function iCapture(txt)
                received{end+1} = txt;
            end
        end

        function responsesCompleted_capturesUsage(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk(['{"type":"response.completed","response":' ...
                '{"usage":{"input_tokens":3,"output_tokens":4,"total_tokens":7}}}']);
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(streamer.Usage.usage.input_tokens, 3);
            testCase.verifyEqual(streamer.Usage.usage.output_tokens, 4);
        end

        function responsesErrorEvent_stopsStream(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeRawChunk(['event: error\n' ...
                'data: {"type":"error","code":"server_error",' ...
                '"message":"The server had an error.","param":null}\n']);
            stop = streamer.doPutData(chunk, false);
            testCase.verifyTrue(stop);
        end

        function responsesErrorEvent_recordsErrorMessage(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeRawChunk(['event: error\n' ...
                'data: {"type":"error","code":"server_error",' ...
                '"message":"The server had an error.","param":null}\n']);
            streamer.doPutData(chunk, false);
            testCase.verifyEqual(streamer.StreamError, "The server had an error.");
        end

        function responsesFailedEvent_stopsStreamAndRecordsErrorMessage(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeRawChunk(['event: response.failed\n' ...
                'data: {"type":"response.failed","response":{"id":"resp_1",' ...
                '"status":"failed","error":{"code":"server_error",' ...
                '"message":"The model failed to respond."}}}\n']);
            stop = streamer.doPutData(chunk, false);
            testCase.verifyTrue(stop);
            testCase.verifyEqual(streamer.StreamError, "The model failed to respond.");
        end

        function responsesErrorEventWithoutMessage_recordsEventJSON(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeRawChunk(['event: error\n' ...
                'data: {"type":"error","code":"server_error","param":null}\n']);
            stop = streamer.doPutData(chunk, false);
            testCase.verifyTrue(stop);
            testCase.verifySubstring(streamer.StreamError, "server_error");
        end

        function responsesFailedEventWithoutErrorMessage_recordsEventJSON(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeRawChunk(['event: response.failed\n' ...
                'data: {"type":"response.failed","response":{"id":"resp_1",' ...
                '"status":"failed","error":null}}\n']);
            stop = streamer.doPutData(chunk, false);
            testCase.verifyTrue(stop);
            testCase.verifySubstring(streamer.StreamError, "resp_1");
        end

        function responsesSplitInsideEventLine_reassembles(testCase)
            % A network chunk boundary can land inside an "event:" line.
            % The partial line must be buffered (not dropped by the event
            % filter) so its continuation, and the "response.completed"
            % event carrying token usage, are not lost.
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            first = iMakeRawChunk(['event: response.output_text.delta\n' ...
                'data: {"type":"response.output_text.delta","delta":"Hi"}\n' ...
                'event: response.comp']);
            rest = iMakeRawChunk(['leted\n' ...
                'data: {"type":"response.completed","response":' ...
                '{"usage":{"input_tokens":3,"output_tokens":4,"total_tokens":7}}}\n']);
            streamer.doPutData(first, false);
            streamer.doPutData(rest, false);
            testCase.verifyEqual(streamer.ResponseText, 'Hi');
            testCase.verifyEqual(streamer.Usage.usage.input_tokens, 3);
            testCase.verifyEqual(streamer.Usage.usage.output_tokens, 4);
        end

        function responsesSplitInsideDataLine_reassembles(testCase)
            % A chunk boundary inside the "response.completed" data payload
            % must be buffered and reassembled so usage is still captured.
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            first = iMakeRawChunk(['data: {"type":"response.completed","response":' ...
                '{"usage":{"input_tokens":11,']);
            rest = iMakeRawChunk('"output_tokens":22,"total_tokens":33}}}\n');
            streamer.doPutData(first, false);
            streamer.doPutData(rest, false);
            testCase.verifyEqual(streamer.Usage.usage.input_tokens, 11);
            testCase.verifyEqual(streamer.Usage.usage.output_tokens, 22);
        end

        function responsesTextDeltas_goToResponseTextAndOneMessageItem(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            payload = sprintf([ ...
                'data: {"type":"response.output_text.delta","item_id":"msg_1","delta":"Hi"}\n' ...
                'data: {"type":"response.output_text.delta","item_id":"msg_1","delta":" there"}\n']);
            streamer.doPutData(unicode2native(payload, 'UTF-8')', false);
            testCase.verifyEqual(streamer.ResponseText, 'Hi there');
            testCase.assertNumElements(streamer.StreamedOutputItems, 1);
            item = streamer.StreamedOutputItems{1};
            testCase.verifyEqual(item.type, "message");
            testCase.verifyEqual(item.content{1}.text, "Hi there");
        end

        function responsesTextAroundFunctionCall_keepsItemOrder(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            payload = sprintf([ ...
                'data: {"type":"response.output_item.added","output_index":0,"item":' ...
                '{"id":"msg_1","type":"message","role":"assistant","content":[]}}\n' ...
                'data: {"type":"response.output_text.delta","item_id":"msg_1","delta":"Let me check."}\n' ...
                'data: {"type":"response.output_item.added","output_index":1,"item":' ...
                '{"id":"fc_1","type":"function_call","call_id":"call_1","name":"getWeather","arguments":""}}\n' ...
                'data: {"type":"response.function_call_arguments.done","item_id":"fc_1",' ...
                '"arguments":"{\\"city\\":\\"Paris\\"}"}\n' ...
                'data: {"type":"response.output_item.added","output_index":2,"item":' ...
                '{"id":"msg_2","type":"message","role":"assistant","content":[]}}\n' ...
                'data: {"type":"response.output_text.delta","item_id":"msg_2","delta":"Done."}\n']);
            streamer.doPutData(unicode2native(payload, 'UTF-8')', false);

            items = streamer.StreamedOutputItems;
            testCase.assertNumElements(items, 3);
            testCase.verifyEqual(items{1}.content{1}.text, "Let me check.");
            testCase.verifyEqual(items{2}.call_id, "call_1");
            testCase.verifyEqual(items{2}.arguments, "{""city"":""Paris""}");
            testCase.verifyEqual(items{3}.content{1}.text, "Done.");
        end

        function responsesFunctionCall_assembledFromArgumentDeltas(testCase)
            received = {};
            streamer = aisdk.utils.ResponseStreamer(@(txt) iCapture(txt));
            payload = sprintf([ ...
                'data: {"type":"response.output_item.added","output_index":0,"item":' ...
                '{"id":"fc_1","type":"function_call","call_id":"call_1","name":"getWeather","arguments":""}}\n' ...
                'data: {"type":"response.function_call_arguments.delta","item_id":"fc_1","delta":"{\\"city\\":"}\n' ...
                'data: {"type":"response.function_call_arguments.delta","item_id":"fc_1","delta":"\\"Paris\\"}"}\n']);
            chunk = unicode2native(payload, 'UTF-8')';
            streamer.doPutData(chunk, false);

            testCase.verifyNumElements(streamer.StreamedOutputItems, 1);
            item = streamer.StreamedOutputItems{1};
            testCase.verifyEqual(item.type, "function_call");
            testCase.verifyEqual(item.call_id, "call_1");
            testCase.verifyEqual(item.name, "getWeather");
            testCase.verifyEqual(item.arguments, "{""city"":""Paris""}");
            % Function-call events carry no assistant text.
            testCase.verifyEmpty(received);
            testCase.verifyEmpty(streamer.ResponseText);

            function iCapture(txt)
                received{end+1} = txt;
            end
        end

        function responsesFunctionCallArgumentsDone_replacesDeltas(testCase)
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            payload = sprintf([ ...
                'data: {"type":"response.output_item.added","output_index":0,"item":' ...
                '{"id":"fc_1","type":"function_call","call_id":"call_1","name":"getWeather","arguments":""}}\n' ...
                'data: {"type":"response.function_call_arguments.delta","item_id":"fc_1","delta":"{\\"city\\":"}\n' ...
                'data: {"type":"response.function_call_arguments.done","item_id":"fc_1",' ...
                '"arguments":"{\\"city\\":\\"Paris\\"}"}\n']);
            chunk = unicode2native(payload, 'UTF-8')';
            streamer.doPutData(chunk, false);

            testCase.verifyNumElements(streamer.StreamedOutputItems, 1);
            testCase.verifyEqual(streamer.StreamedOutputItems{1}.arguments, "{""city"":""Paris""}");
        end

        function responsesOutputItemDone_capturesCompleteFunctionCall(testCase)
            % A provider may report the finished item without emitting
            % incremental argument deltas.
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            chunk = iMakeChunk(['{"type":"response.output_item.done","output_index":0,"item":' ...
                '{"id":"fc_9","type":"function_call","call_id":"call_9","name":"toolA",' ...
                '"arguments":"{\"x\":1}"}}']);
            streamer.doPutData(chunk, false);

            testCase.verifyNumElements(streamer.StreamedOutputItems, 1);
            testCase.verifyEqual(streamer.StreamedOutputItems{1}.call_id, "call_9");
            testCase.verifyEqual(streamer.StreamedOutputItems{1}.name, "toolA");
            testCase.verifyEqual(streamer.StreamedOutputItems{1}.arguments, "{""x"":1}");
        end

        function responsesParallelFunctionCalls_assembledInArrivalOrder(testCase)
            % Argument deltas for several calls interleave; each must land on
            % the item its item_id names.
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            payload = sprintf([ ...
                'data: {"type":"response.output_item.added","output_index":0,"item":' ...
                '{"id":"fc_1","type":"function_call","call_id":"call_1","name":"toolA","arguments":""}}\n' ...
                'data: {"type":"response.output_item.added","output_index":1,"item":' ...
                '{"id":"fc_2","type":"function_call","call_id":"call_2","name":"toolB","arguments":""}}\n' ...
                'data: {"type":"response.function_call_arguments.delta","item_id":"fc_2","delta":"{\\"y\\":2}"}\n' ...
                'data: {"type":"response.function_call_arguments.delta","item_id":"fc_1","delta":"{\\"x\\":1}"}\n']);
            chunk = unicode2native(payload, 'UTF-8')';
            streamer.doPutData(chunk, false);

            testCase.verifyNumElements(streamer.StreamedOutputItems, 2);
            testCase.verifyEqual(streamer.StreamedOutputItems{1}.name, "toolA");
            testCase.verifyEqual(streamer.StreamedOutputItems{1}.arguments, "{""x"":1}");
            testCase.verifyEqual(streamer.StreamedOutputItems{2}.name, "toolB");
            testCase.verifyEqual(streamer.StreamedOutputItems{2}.arguments, "{""y"":2}");
        end

        function responsesFunctionCallSplitAcrossChunks_reassembles(testCase)
            % An argument delta event split at a network chunk boundary must
            % still land on the right item.
            streamer = aisdk.utils.ResponseStreamer(@(~) []);
            first = iMakeRawChunk([ ...
                'data: {"type":"response.output_item.added","output_index":0,"item":' ...
                '{"id":"fc_1","type":"function_call","call_id":"call_1","name":"toolA","arguments":""}}\n' ...
                'data: {"type":"response.function_call_arguments.delta","item_id":"fc_1",']);
            rest = iMakeRawChunk('"delta":"{\\"x\\":1}"}\n');
            streamer.doPutData(first, false);
            streamer.doPutData(rest, false);

            testCase.verifyNumElements(streamer.StreamedOutputItems, 1);
            testCase.verifyEqual(streamer.StreamedOutputItems{1}.arguments, "{""x"":1}");
        end
    end
end

function data = iMakeRawChunk(text)
    % Byte chunk delivered verbatim (no trailing newline appended), to
    % simulate a network split at an arbitrary offset within the SSE stream.
    data = unicode2native(sprintf(text), 'UTF-8')';
end

function data = iMakeChunk(text)
    line = "data: " + text;
    data = unicode2native(char(line + newline), 'UTF-8')';
end
