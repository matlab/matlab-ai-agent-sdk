classdef tOpenAIResponsesClient < hOpenAIClientCommon
% Tests for aisdk.client.OpenAIResponsesClient, the Responses client.

%   Copyright 2026 The MathWorks, Inc.

    properties (Constant)
        ClientClass = "aisdk.client.OpenAIResponsesClient"
        EndpointPath = "responses"
        MaxNumTokensField = "max_output_tokens"
    end

    properties (TestParameter)
        ChatCompletionsOnlyGenerateOption = struct( ...
            "NumCompletions", struct("prop", "NumCompletions", "value", 2), ...
            "Seed",           struct("prop", "Seed",           "value", 42));

        UnreadableBody = struct( ...
            "noOutputField",   struct("id", "resp_1"), ...
            "html",            '<html><body>Hello</body></html>', ...
            "emptyBody",       [], ...
            "outputNotArray",  struct("output", "Hello"), ...
            "itemWithoutType", struct("output", {{struct("text", "Hello")}}));
    end

    methods
        function client = createClient(~, varargin)
            client = aisdk.client.OpenAIResponsesClient(varargin{:});
        end
    end

    methods (Test, TestTags = {'Unit'})
        function generate_rejectsChatCompletionsOnlyOption(testCase, ChatCompletionsOnlyGenerateOption)
            client = testCase.clientWithFakeHTTP(testCase.textResponse("hi"));
            testCase.verifyError( ...
                @() generate(client, "Hi", ...
                    ChatCompletionsOnlyGenerateOption.prop, ChatCompletionsOnlyGenerateOption.value), ...
                "MATLAB:TooManyInputs");
        end
    end

    methods (Test, TestTags = {'Unit'})
        function generate_sendsInputAndStatelessStore(testCase)
            import matlab.unittest.constraints.HasField
            params = testCase.generateAndCaptureRequest(aisdk.LLMTextMessage("hello"));
            testCase.verifyThat(params, HasField("input"));
            testCase.verifyThat(params, ~HasField("messages"));
            testCase.verifyEqual(params.store, false);
        end

        %% generate — unreadable reply
        function generate_okBodyWithoutReadableOutput_throwsUnreadableResponse(testCase, UnreadableBody)
            client = testCase.clientWithFakeHTTP( ...
                struct("StatusCode", "OK", "Body", struct("Data", UnreadableBody)));
            testCase.verifyError(@() generate(client, "Hi"), "aisdk:unreadableResponse");
        end

        function generate_okChatCompletionsBody_throwsResponseIsChatCompletions(testCase)
            body = struct("choices", {{struct("message", struct("content", "Hello"))}});
            client = testCase.clientWithFakeHTTP( ...
                struct("StatusCode", "OK", "Body", struct("Data", body)));
            testCase.verifyError(@() generate(client, "Hi"), "aisdk:responseIsChatCompletions");
        end

        function generate_okBodyWithFailedStatus_throwsApiReturnedError(testCase)
            body = struct("object", "response", "status", "failed", ...
                "error", struct("code", "server_error", "message", "backend boom"), "output", {{}});
            client = testCase.clientWithFakeHTTP( ...
                struct("StatusCode", "OK", "Body", struct("Data", body)));
            testCase.verifyError(@() generate(client, "Hi"), "aisdk:apiReturnedError");
        end

        function generate_emptyOutput_returnsEmptyText(testCase)
            body = struct("object", "response", "status", "completed", "output", {{}});
            client = testCase.clientWithFakeHTTP( ...
                struct("StatusCode", "OK", "Body", struct("Data", body)));
            [text, messages] = generate(client, "Hi");
            testCase.verifyEqual(text, "");
            testCase.verifyClass(messages, "aisdk.LLMTextMessage");
            testCase.verifyEqual(messages.Text, "");
        end

        function generate_unrecognizedOutputItemType_returnsEmptyText(testCase)
            % A reply whose output holds only reasoning summaries is currently
            % an example of such a response.
            item = struct("type", "future_item", "id", "x_1");
            body = struct("object", "response", "status", "completed", "output", {{item}});
            client = testCase.clientWithFakeHTTP( ...
                struct("StatusCode", "OK", "Body", struct("Data", body)));
            text = generate(client, "Hi");
            testCase.verifyEqual(text, "");
        end

        %% generate — streaming
        function generate_streamedText_returnsStreamedDeltas(testCase)
            responseData = struct("output", {{messageItem("Hello world")}}, "usage", ...
                struct("input_tokens", 4, "output_tokens", 6, "total_tokens", 10));
            client = streamingClient(responseData, "Hello world");
            [text, messages, info] = generate(client, "Hi");
            testCase.verifyEqual(text, "Hello world");
            testCase.verifyClass(messages, "aisdk.LLMTextMessage");
            testCase.verifyEqual(messages.Text, "Hello world");
            testCase.verifyEqual(info.Tokens.NumTotalTokens, 10);
        end

        function generate_streamedToolCall_returnsToolCallMessage(testCase)
            fcItem = struct("type", "function_call", "call_id", "call_s1", ...
                "name", "getWeather", "arguments", '{"city":"Oslo"}');
            responseData = struct("output", {{fcItem}}, ...
                "usage", struct("input_tokens", 4, "output_tokens", 6, "total_tokens", 10));
            client = streamingClient(responseData, "");
            [~, messages] = generate(client, "What's the weather?");
            testCase.verifyClass(messages, "aisdk.LLMToolCallMessage");
            testCase.verifyEqual(messages.Name, "getWeather");
            testCase.verifyEqual(messages.Arguments, struct("city", 'Oslo'));
            testCase.verifyEqual(messages.ToolCallID, "call_s1");
        end

        function generate_streamedParallelToolCalls_returnsAllMessages(testCase)
            fcItem1 = struct("type", "function_call", "call_id", "call_1", ...
                "name", "toolA", "arguments", '{"x":1}');
            fcItem2 = struct("type", "function_call", "call_id", "call_2", ...
                "name", "toolB", "arguments", '{"y":2}');
            responseData = struct("output", {{fcItem1, fcItem2}}, ...
                "usage", struct("input_tokens", 4, "output_tokens", 6, "total_tokens", 10));
            client = streamingClient(responseData, "");
            [~, messages] = generate(client, "Call both");
            testCase.verifyNumElements(messages, 2);
            testCase.verifyEqual(messages(1).Name, "toolA");
            testCase.verifyEqual(messages(1).ToolCallID, "call_1");
            testCase.verifyEqual(messages(2).Name, "toolB");
            testCase.verifyEqual(messages(2).ToolCallID, "call_2");
        end

        function generate_streamedTextAndToolCall_returnsTextMessageAndToolCall(testCase)
            fcItem = struct("type", "function_call", "call_id", "call_s1", ...
                "name", "getWeather", "arguments", '{"city":"Oslo"}');
            responseData = struct("output", {{messageItem("Checking."), fcItem}}, ...
                "usage", struct("input_tokens", 4, "output_tokens", 6, "total_tokens", 10));
            client = streamingClient(responseData, "Checking.");
            [~, messages] = generate(client, "What's the weather?");
            testCase.assertNumElements(messages, 2);
            testCase.verifyEqual(messages(1).Text, "Checking.");
            testCase.verifyEqual(messages(2).ToolCallID, "call_s1");
        end

        function generate_streamedTextAroundToolCall_keepsItemOrder(testCase)
            responseData = struct("output", {interleavedOutput()}, ...
                "usage", struct("input_tokens", 4, "output_tokens", 6, "total_tokens", 10));
            client = streamingClient(responseData, "Let me check.Done.");
            [text, messages] = generate(client, "What's the weather?");
            testCase.verifyEqual(text, "Let me check.Done.");
            verifyInterleavedMessages(testCase, messages);
        end

        function generate_streamedTextWithoutMessageItem_throwsUnreadableResponse(testCase)
            % A stream that is not Responses-shaped, such as Chat Completions
            % chunks, yields text but no output items.
            responseData = struct("usage", ...
                struct("input_tokens", 4, "output_tokens", 6, "total_tokens", 10));
            client = streamingClient(responseData, "Hello world");
            testCase.verifyError(@() generate(client, "Hi"), "aisdk:unreadableResponse");
        end

        function generate_streamedToolCallWithoutItems_throwsUnreadableResponse(testCase)
            % A Chat Completions stream leaves a tool call in the streamed
            % text as JSON, without output items.
            toolCallJSON = "{""id"":""call_1"",""type"":""function""," + ...
                """function"":{""name"":""getWeather"",""arguments"":""{}""}}";
            responseData = struct("usage", ...
                struct("input_tokens", 4, "output_tokens", 6, "total_tokens", 10));
            client = streamingClient(responseData, toolCallJSON);
            testCase.verifyError(@() generate(client, "What's the weather?"), "aisdk:unreadableResponse");
        end

        %% generate — output item order
        function generate_textAfterToolCall_keepsItemOrder(testCase)
            fcItem = struct("type", "function_call", "call_id", "call_1", ...
                "name", "myTool", "arguments", '{"x":7}');
            responseData = struct("output", {{fcItem, messageItem("After the call.")}});
            client = testCase.clientWithFakeHTTP( ...
                struct("StatusCode", "OK", "Body", struct("Data", responseData)));
            [~, messages] = generate(client, "Hi");
            testCase.assertNumElements(messages, 2);
            testCase.verifyClass(messages(1), "aisdk.LLMToolCallMessage");
            testCase.verifyEqual(messages(1).ToolCallID, "call_1");
            testCase.verifyClass(messages(2), "aisdk.LLMTextMessage");
            testCase.verifyEqual(messages(2).Text, "After the call.");
        end

        function generate_textAroundToolCall_keepsItemOrder(testCase)
            client = testCase.clientWithFakeHTTP(struct("StatusCode", "OK", ...
                "Body", struct("Data", struct("output", {interleavedOutput()}))));
            [text, messages] = generate(client, "What's the weather?");
            testCase.verifyEqual(text, "Let me check.Done.");
            verifyInterleavedMessages(testCase, messages);
        end

        function generate_consecutiveMessageItems_mergesIntoOneTextMessage(testCase)
            responseData = struct("output", {{messageItem("Hello "), messageItem("world")}});
            client = testCase.clientWithFakeHTTP( ...
                struct("StatusCode", "OK", "Body", struct("Data", responseData)));
            [~, messages] = generate(client, "Hi");
            testCase.verifyClass(messages, "aisdk.LLMTextMessage");
            testCase.verifyEqual(messages.Text, "Hello world");
        end

        function generate_functionCallWithoutArguments_returnsEmptyArguments(testCase)
            fcItem = struct("type", "function_call", "call_id", "call_0", "name", "ping");
            client = testCase.clientWithFakeHTTP(struct("StatusCode", "OK", ...
                "Body", struct("Data", struct("output", {{fcItem}}))));
            [~, messages] = generate(client, "Hi");
            testCase.verifyEqual(messages.Arguments, struct());
        end

        function generate_functionCallWithoutCallID_returnsEmptyToolCallID(testCase)
            fcItem = struct("type", "function_call", "id", "fc_1", ...
                "name", "ping", "arguments", '{}');
            client = testCase.clientWithFakeHTTP(struct("StatusCode", "OK", ...
                "Body", struct("Data", struct("output", {{fcItem}}))));
            [~, messages] = generate(client, "Hi");
            testCase.verifyEqual(messages.ToolCallID, "");
        end

        function generate_textAroundToolCall_replaysItemsInOrder(testCase)
            client = testCase.clientWithFakeHTTP(struct("StatusCode", "OK", ...
                "Body", struct("Data", struct("output", {interleavedOutput()}))));
            [~, messages] = generate(client, "What's the weather?");
            history = [aisdk.LLMTextMessage("What's the weather?"), messages, ...
                aisdk.LLMToolResultMessage("Sunny", ToolCallID="call_1", Name="getWeather")];

            params = testCase.generateAndCaptureRequest(history);

            input = params.input;
            testCase.assertNumElements(input, 5);
            testCase.verifyEqual(input{1}.role, "user");
            testCase.verifyEqual(input{2}.content, "Let me check.");
            testCase.verifyEqual(input{3}.type, "function_call");
            testCase.verifyEqual(input{4}.content, "Done.");
            testCase.verifyEqual(input{5}.type, "function_call_output");
        end
    end

    methods (Access=protected)
        function response = textResponse(~, text)
            responseData = struct("output", {{messageItem(text)}}, ...
                "usage", struct("input_tokens", 10, "output_tokens", 5, "total_tokens", 15, ...
                    "input_tokens_details", struct("cached_tokens", 3)));
            response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
        end

        function response = toolCallResponse(~, toolCalls, text)
            output = cellfun(@toFunctionCallItem, toolCalls, UniformOutput=false);
            if strlength(text) > 0
                output = [{messageItem(text)}, output];
            end
            response = toolCallReply(output);
        end

        function response = toolCallWithoutIDResponse(~, name, arguments)
            response = toolCallReply({functionCallItemWithoutID(name, arguments)});
        end

        function messages = sentMessages(~, params)
            messages = params.input;
        end

        function verifyToolCallAndResultSent(testCase, params)
            callItem = params.input{2};
            testCase.verifyEqual(callItem.type, "function_call");
            testCase.verifyEqual(callItem.call_id, "call_1");
            testCase.verifyEqual(callItem.name, "myTool");
            resultItem = params.input{3};
            testCase.verifyEqual(resultItem.type, "function_call_output");
            testCase.verifyEqual(resultItem.call_id, "call_1");
            testCase.verifyEqual(resultItem.output, "result text");
        end

        function verifyTwoToolCallsSent(testCase, params)
            % Each tool call is its own top-level item.
            testCase.verifyNumElements(params.input, 3);
            testCase.verifyEqual(params.input{2}.type, "function_call");
            testCase.verifyEqual(params.input{2}.call_id, "call_1");
            testCase.verifyEqual(params.input{3}.type, "function_call");
            testCase.verifyEqual(params.input{3}.call_id, "call_2");
        end

        function verifyToolCallWithoutIDSentWithEmptyID(testCase, params)
            testCase.assertNumElements(params.input, 2, ...
                "Expected the user message and one function_call item.");
            callItem = params.input{2};
            testCase.assertEqual(callItem.type, "function_call");
            testCase.verifyEqual(callItem.name, "myTool");
            testCase.verifyEqual(callItem.call_id, "");
        end

        function verifyImageSent(testCase, params)
            testCase.assertNumElements(params.input, 1, ...
                "Expected one image message.");
            imgMsg = params.input{1};
            testCase.verifyEqual(imgMsg.role, "user");
            testCase.assertNumElements(imgMsg.content, 1, ...
                "Expected one content part carrying the image.");
            content = imgMsg.content{1};
            testCase.verifyEqual(content.type, "input_image");
            testCase.verifyTrue(startsWith(content.image_url, "data:image/png;base64,"));
            testCase.verifyEqual(content.detail, "low");
        end

        function verifyToolDefinitionSent(testCase, params)
            import matlab.unittest.constraints.HasField
            toolDef = params.tools{1};
            testCase.verifyEqual(toolDef.type, "function");
            testCase.verifyEqual(toolDef.name, "myTool");
            testCase.verifyThat(toolDef, ~HasField("function"));
        end

        function verifyNamedToolChoiceSent(testCase, params)
            testCase.verifyEqual(params.tool_choice, struct("type", "function", "name", "myTool"));
        end

        function verifyReasoningEffortAndVerbositySent(testCase, params)
            testCase.verifyEqual(params.reasoning.effort, "high");
            testCase.verifyEqual(params.text.verbosity, "low");
        end

        function verifyStructuredOutputSent(testCase, params)
            testCase.verifyEqual(params.text.format.type, 'json_schema');
        end

        function verifyAssistantTextAndToolCallSent(testCase, params, text, toolCallID)
            testCase.assertNumElements(params.input, 4, ...
                "Expected the user message, the assistant message, the function_call and its output.");
            assistantMsg = params.input{2};
            testCase.verifyEqual(assistantMsg.role, "assistant");
            testCase.verifyEqual(assistantMsg.content, text);
            callItem = params.input{3};
            testCase.verifyEqual(callItem.type, "function_call");
            testCase.verifyEqual(callItem.call_id, toolCallID);
        end
    end

end

function client = streamingClient(responseData, streamedText)
    % Stands in for a streamed call: sendRequest returns the text collected
    % from the deltas plus a body carrying the reassembled output items.
    client = aisdk.client.OpenAIResponsesClient("gpt-4o", APIKey="fake-key", ...
        StreamFcn=@(~) []);
    mockResponse = struct("StatusCode", "OK", "Body", struct("Data", responseData));
    client.sendRequestFcn = @(~,~,~,~,~) deal(mockResponse, streamedText);
end

function output = interleavedOutput()
    fcItem = struct("type", "function_call", "call_id", "call_1", ...
        "name", "getWeather", "arguments", '{"city":"Paris"}');
    output = {messageItem("Let me check."), fcItem, messageItem("Done.")};
end

function verifyInterleavedMessages(testCase, messages)
    testCase.assertNumElements(messages, 3);
    testCase.verifyClass(messages(1), "aisdk.LLMTextMessage");
    testCase.verifyEqual(messages(1).Text, "Let me check.");
    testCase.verifyClass(messages(2), "aisdk.LLMToolCallMessage");
    testCase.verifyEqual(messages(2).ToolCallID, "call_1");
    testCase.verifyClass(messages(3), "aisdk.LLMTextMessage");
    testCase.verifyEqual(messages(3).Text, "Done.");
end

function item = messageItem(text)
    item = struct("type", "message", "role", "assistant", ...
        "content", {{struct("type", "output_text", "text", text)}});
end

function response = toolCallReply(output)
    responseData = struct("output", {output}, ...
        "usage", struct("input_tokens", 5, "output_tokens", 5, "total_tokens", 10));
    response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
end

function item = toFunctionCallItem(toolCall)
    item = functionCallItemWithoutID(toolCall.name, toolCall.arguments);
    item.call_id = toolCall.id;
end

function item = functionCallItemWithoutID(name, arguments)
    item = struct("type", "function_call", "name", name, "arguments", arguments);
end
