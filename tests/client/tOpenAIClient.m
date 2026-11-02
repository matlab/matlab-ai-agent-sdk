classdef tOpenAIClient < hOpenAIClientCommon
% Tests for aisdk.client.OpenAIClient, the Chat Completions client.

%   Copyright 2026 The MathWorks, Inc.

    properties (Constant)
        ClientClass = "aisdk.client.OpenAIClient"
        EndpointPath = "chat/completions"
        MaxNumTokensField = "max_completion_tokens"
    end

    properties (TestParameter)
        ChatCompletionsDefault = struct( ...
            "StopSequences",    struct("prop", "StopSequences",    "expected", []), ...
            "PresencePenalty",  struct("prop", "PresencePenalty",  "expected", "auto"), ...
            "FrequencyPenalty", struct("prop", "FrequencyPenalty", "expected", "auto"));

        ChatCompletionsCustom = struct( ...
            "StopSequences",    struct("prop", "StopSequences",    "value", ["stop1","stop2"]), ...
            "PresencePenalty",  struct("prop", "PresencePenalty",  "value", 0.5), ...
            "FrequencyPenalty", struct("prop", "FrequencyPenalty", "value", 0.4));
    end

    methods
        function client = createClient(~, varargin)
            client = aisdk.client.OpenAIClient(varargin{:});
        end
    end

    methods (Test, TestTags = {'Unit'})
        function chatCompletionsProperty_notSet_hasDefaultValue(testCase, ChatCompletionsDefault)
            client = testCase.createClient("gpt-4o");
            testCase.verifyEqual(client.(ChatCompletionsDefault.prop), ChatCompletionsDefault.expected);
        end

        function chatCompletionsProperty_setAtConstruction_keepsValue(testCase, ChatCompletionsCustom)
            client = testCase.createClient("gpt-4o", ChatCompletionsCustom.prop, ChatCompletionsCustom.value);
            testCase.verifyEqual(client.(ChatCompletionsCustom.prop), ChatCompletionsCustom.value);
        end
    end

    methods (Test, TestTags = {'Unit'})
        function generate_toolCallsNullContent_returnsEmptyText(testCase)
            client = testCase.clientWithFakeHTTP(testCase.toolCallResponse( ...
                {struct("id", "call_123", "name", "getWeather", "arguments", '{"city":"London"}')}, ...
                jsondecode('null')));
            [text, ~] = generate(client, "Call a tool");
            testCase.verifyEqual(text, "");
        end

        function generate_streamedUsage_matchesNonStreamedUsage(testCase)
            streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);
            event = ['{"choices":[],"usage":{"prompt_tokens":10,' ...
                '"completion_tokens":5,"total_tokens":15,' ...
                '"prompt_tokens_details":{"cached_tokens":3}}}'];
            streamedData = hClientTestUtils.streamEventsAndMergeResponse( ...
                streamer, event, "sse");

            streamedClient = testCase.createClient( ...
                "gpt-4o", APIKey="fake-key", StreamFcn=@(~) []);
            streamedClient.sendRequestFcn = @streamedResponse;
            [~, ~, streamedInfo] = generate(streamedClient, "Hi");

            nonStreamedClient = testCase.clientWithFakeHTTP( ...
                testCase.textResponse("ok"));
            [~, ~, nonStreamedInfo] = generate(nonStreamedClient, "Hi");

            testCase.verifyEqual(streamedInfo.Tokens, nonStreamedInfo.Tokens);

            function response = streamedResponse(~, ~, ~, ~, ~, ~)
                response = struct( ...
                    "StatusCode", "OK", ...
                    "Body", struct("Data", streamedData));
            end
        end

        function generate_streamedParallelToolCalls_returnsAllMessages(testCase)
            client = testCase.createClient( ...
                "gpt-4o", APIKey="fake-key", StreamFcn=@(~) []);
            responseData = chatCompletionsParallelToolCallResponse();

            hClientTestUtils.verifyStreamedParallelToolCalls(testCase, client, responseData);
        end

        function generate_streamedTextOnly_returnsTextMessage(testCase)
            client = testCase.createClient( ...
                "gpt-4o", APIKey="fake-key", StreamFcn=@(~) []);

            txt1 = "Hello ";
            txt2 = "world";
            responseData = chatCompletionsSplitTextOnlyStream(txt1, txt2);

            hClientTestUtils.verifyStreamedTextOnly( ...
                testCase, client, responseData, txt1 + txt2);
        end

        function generate_streamedJSONLookingText_returnsTextMessage(testCase)
            client = testCase.createClient( ...
                "gpt-4o", APIKey="fake-key", StreamFcn=@(~) []);

            txt1 = "Arguments: ";
            txt2 = "{""a"":1}";
            responseData = chatCompletionsSplitTextOnlyStream(txt1, txt2);

            hClientTestUtils.verifyStreamedTextOnly( ...
                testCase, client, responseData, txt1 + txt2);
        end
    end

    methods (Access=protected)
        function response = textResponse(~, text)
            responseData = struct( ...
                "choices", struct("message", struct("role", "assistant", "content", text)), ...
                "usage", struct("prompt_tokens", 10, "completion_tokens", 5, ...
                    "total_tokens", 15, ...
                    "prompt_tokens_details", struct("cached_tokens", 3)));
            response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
        end

        function response = toolCallResponse(~, toolCalls, text)
            wireCalls = cellfun(@toWireToolCall, toolCalls, UniformOutput=false);
            response = toolCallReply(wireCalls, text);
        end

        function response = toolCallWithoutIDResponse(~, name, arguments)
            response = toolCallReply({wireToolCallWithoutID(name, arguments)}, "");
        end

        function messages = sentMessages(~, params)
            messages = params.messages;
        end

        function verifyToolCallAndResultSent(testCase, params)
            assistantMsg = params.messages{2};
            testCase.verifyEqual(assistantMsg.role, "assistant");
            testCase.verifyEqual(assistantMsg.tool_calls{1}.id, "call_1");
            testCase.verifyEqual(assistantMsg.tool_calls{1}.function.name, "myTool");
            toolMsg = params.messages{3};
            testCase.verifyEqual(toolMsg.role, "tool");
            testCase.verifyEqual(toolMsg.tool_call_id, "call_1");
            testCase.verifyEqual(toolMsg.name, "myTool");
            testCase.verifyEqual(toolMsg.content, "result text");
        end

        function verifyTwoToolCallsSent(testCase, params)
            % Consecutive tool calls merge into one assistant message.
            testCase.verifyNumElements(params.messages, 2);
            assistantMsg = params.messages{2};
            testCase.verifyEqual(assistantMsg.role, "assistant");
            testCase.verifyNumElements(assistantMsg.tool_calls, 2);
        end

        function verifyToolCallWithoutIDSentWithEmptyID(testCase, params)
            import matlab.unittest.constraints.HasField
            testCase.assertNumElements(params.messages, 2, ...
                "Expected the user message and one assistant message.");
            assistantMsg = params.messages{2};
            testCase.assertThat(assistantMsg, HasField("tool_calls"));
            testCase.assertNumElements(assistantMsg.tool_calls, 1);
            testCase.verifyEqual(assistantMsg.tool_calls{1}.function.name, "myTool");
            testCase.verifyEqual(assistantMsg.tool_calls{1}.id, "");
        end

        function verifyImageSent(testCase, params)
            testCase.assertNumElements(params.messages, 1, ...
                "Expected one image message.");
            imgMsg = params.messages{1};
            testCase.verifyEqual(imgMsg.role, "user");
            testCase.assertNumElements(imgMsg.content, 1, ...
                "Expected one content part carrying the image.");
            content = imgMsg.content{1};
            testCase.verifyEqual(content.type, "image_url");
            testCase.verifyTrue(startsWith(content.image_url.url, "data:image/png;base64,"));
            testCase.verifyEqual(content.image_url.detail, "low");
        end

        function verifyToolDefinitionSent(testCase, params)
            toolDef = params.tools{1};
            testCase.verifyEqual(toolDef.type, "function");
            testCase.verifyEqual(toolDef.function.name, "myTool");
        end

        function verifyNamedToolChoiceSent(testCase, params)
            testCase.verifyEqual(params.tool_choice, ...
                struct("type", "function", "function", struct("name", "myTool")));
        end

        function verifyReasoningEffortAndVerbositySent(testCase, params)
            testCase.verifyEqual(params.reasoning_effort, "high");
            testCase.verifyEqual(params.verbosity, "low");
        end

        function verifyStructuredOutputSent(testCase, params)
            testCase.verifyEqual(params.response_format.type, 'json_schema');
        end

        function verifyAssistantTextAndToolCallSent(testCase, params, text, toolCallID)
            % The text and the tool call merge into one assistant message.
            testCase.assertNumElements(params.messages, 3, ...
                "Expected the user message, one assistant message and the tool result.");
            assistantMsg = params.messages{2};
            testCase.verifyEqual(assistantMsg.role, "assistant");
            testCase.verifyEqual(assistantMsg.content, text);
            testCase.assertNumElements(assistantMsg.tool_calls, 1);
            testCase.verifyEqual(assistantMsg.tool_calls{1}.id, toolCallID);
        end
    end

end

function response = toolCallReply(wireCalls, text)
    message = struct("role", "assistant", "content", text, "tool_calls", {wireCalls});
    responseData = struct("choices", struct("message", message), ...
        "usage", struct("prompt_tokens", 5, "completion_tokens", 5, "total_tokens", 10));
    response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
end

function data = chatCompletionsParallelToolCallResponse()
    streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);
    events = {
        '{"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"toolA","arguments":"{\"x\":1}"}}]}}]}'
        '{"choices":[{"delta":{"tool_calls":[{"index":1,"id":"call_2","type":"function","function":{"name":"toolB","arguments":"{\"y\":2}"}}]}}]}'
        };
    data = hClientTestUtils.streamEventsAndMergeResponse( ...
        streamer, events, "sse");
end

function data = chatCompletionsSplitTextOnlyStream(txt1, txt2)
    streamer = aisdk.client.internal.ChatCompletionsResponseStreamer(@(~) []);
    txt1 = hClientTestUtils.escapeJSONText(txt1);
    txt2 = hClientTestUtils.escapeJSONText(txt2);
    events = [
        "{""choices"":[{""delta"":{""role"":""assistant"",""content"":""" + txt1 + """}}]}"
        "{""choices"":[{""delta"":{""content"":""" + txt2 + """},""finish_reason"":""stop""}]}"
        ];
    data = hClientTestUtils.streamEventsAndMergeResponse( ...
        streamer, events, "sse");
end

function wireCall = toWireToolCall(toolCall)
    wireCall = wireToolCallWithoutID(toolCall.name, toolCall.arguments);
    wireCall.id = toolCall.id;
end

function wireCall = wireToolCallWithoutID(name, arguments)
    wireCall = struct("type", "function", ...
        "function", struct("name", name, "arguments", arguments));
end
