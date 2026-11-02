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

        ChatCompletionsOnlyOption = struct( ...
            "StopSequences",    struct("prop", "StopSequences",    "value", "STOP"), ...
            "PresencePenalty",  struct("prop", "PresencePenalty",  "value", 0.1), ...
            "FrequencyPenalty", struct("prop", "FrequencyPenalty", "value", 0.1));

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

        function properties_chatCompletionsOnly_absentFromResponsesClient(testCase, ChatCompletionsOnlyOption)
            % The documentation tells users to branch on isprop, so the
            % property must be absent here and still present on the other client.
            responsesClient = testCase.createClient("gpt-4o", APIKey="fake-key");
            chatCompletionsClient = aisdk.client.OpenAIClient("gpt-4o", APIKey="fake-key");
            testCase.verifyFalse(isprop(responsesClient, ChatCompletionsOnlyOption.prop), ...
                ChatCompletionsOnlyOption.prop + " should not be a property of the Responses client.");
            testCase.verifyTrue(isprop(chatCompletionsClient, ChatCompletionsOnlyOption.prop), ...
                ChatCompletionsOnlyOption.prop + " should remain a property of the Chat Completions client.");
            testCase.verifyError(@() setfield(responsesClient, ChatCompletionsOnlyOption.prop, ChatCompletionsOnlyOption.value), ...
                "MATLAB:noPublicFieldForClass");
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
        function generate_streamedTextOnly_returnsTextMessage(testCase)
            client = testCase.createClient( ...
                "gpt-4o", APIKey="fake-key", StreamFcn=@(~) []);

            txt1 = "Hello ";
            txt2 = "world";
            responseData = responsesSplitTextOnlyStream(txt1, txt2);

            hClientTestUtils.verifyStreamedTextOnly( ...
                testCase, client, responseData, txt1 + txt2);
        end

        function generate_streamedJSONLookingText_returnsTextMessage(testCase)
            client = testCase.createClient( ...
                "gpt-4o", APIKey="fake-key", StreamFcn=@(~) []);

            txt1 = "Arguments: ";
            txt2 = "{""a"":1}";
            responseData = responsesSplitTextOnlyStream(txt1, txt2);

            hClientTestUtils.verifyStreamedTextOnly( ...
                testCase, client, responseData, txt1 + txt2);
        end

        function generate_streamedStructuredText_returnsDecodedStruct(testCase)
            client = testCase.createClient( ...
                "gpt-4o", APIKey="fake-key", StreamFcn=@(~) []);
            responseData = responsesSplitTextOnlyStream("{""answer"":", "42}");

            prototype = struct("answer", 0);
            expected = struct("answer", 42);
            hClientTestUtils.verifyStreamedStructuredOutput( ...
                testCase, client, responseData, prototype, expected);
        end

        function generate_streamedToolCallsNoTextWithPrototypeFormat_returnsEmptyText(testCase)
            client = testCase.createClient( ...
                "gpt-4o", APIKey="fake-key", StreamFcn=@(~) []);
            response = hClientTestUtils.okResponse(responsesToolCallStream());
            client.sendRequestFcn = @(~,~,~,~,~,~) response;

            hClientTestUtils.verifyToolCallsNoText(testCase, client, ...
                ResponseFormat=struct("answer", 0));
        end

        function generate_streamedUsage_matchesNonStreamedUsage(testCase)
            streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
            event = ['{"type":"response.completed","response":{"usage":{' ...
                '"input_tokens":10,"output_tokens":5,"total_tokens":15,' ...
                '"input_tokens_details":{"cached_tokens":3}}}}'];
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

        function generate_streamedToolCall_returnsToolCallMessage(testCase)
            fcItem = struct("type", "function_call", "call_id", "call_s1", ...
                "name", "getWeather", "arguments", '{"city":"Oslo"}');
            responseData = struct("output", {{fcItem}}, ...
                "usage", struct("input_tokens", 4, "output_tokens", 6, "total_tokens", 10));
            client = streamingClient(responseData);
            [~, messages] = generate(client, "What's the weather?");
            testCase.verifyClass(messages, "aisdk.LLMToolCallMessage");
            testCase.verifyEqual(messages.Name, "getWeather");
            testCase.verifyEqual(messages.Arguments, struct("city", 'Oslo'));
            testCase.verifyEqual(messages.ToolCallID, "call_s1");
        end

        function generate_streamedParallelToolCalls_returnsAllMessages(testCase)
            client = testCase.createClient( ...
                "gpt-4o", APIKey="fake-key", StreamFcn=@(~) []);
            responseData = responsesParallelToolCallResponse();

            hClientTestUtils.verifyStreamedParallelToolCalls(testCase, client, responseData);
        end

        function generate_streamedTextAndToolCall_returnsTextMessageAndToolCall(testCase)
            fcItem = struct("type", "function_call", "call_id", "call_s1", ...
                "name", "getWeather", "arguments", '{"city":"Oslo"}');
            responseData = struct("output", {{messageItem("Checking."), fcItem}}, ...
                "usage", struct("input_tokens", 4, "output_tokens", 6, "total_tokens", 10));
            client = streamingClient(responseData);
            [~, messages] = generate(client, "What's the weather?");
            testCase.assertNumElements(messages, 2);
            testCase.verifyEqual(messages(1).Text, "Checking.");
            testCase.verifyEqual(messages(2).ToolCallID, "call_s1");
        end

        function generate_streamedTextAroundToolCall_keepsItemOrder(testCase)
            responseData = struct("output", {interleavedOutput()}, ...
                "usage", struct("input_tokens", 4, "output_tokens", 6, "total_tokens", 10));
            client = streamingClient(responseData);
            [text, messages] = generate(client, "What's the weather?");
            testCase.verifyEqual(text, "Let me check.Done.");
            verifyInterleavedMessages(testCase, messages);
        end

        function generate_streamedTextWithoutMessageItem_throwsUnreadableResponse(testCase)
            client = testCase.createClient( ...
                "gpt-4o", APIKey="fake-key", StreamFcn=@(~) [], ...
                BaseURL="https://example.invalid/v1");

            % The Responses endpoint sends Chat Completions text instead.
            streamData = ['data: {"choices":[{"index":0,"delta":{"role":"assistant",' ...
                '"content":"Hello world"},"finish_reason":"stop"}]}' newline newline];
            client.sendRequestFcn = @(varargin) ...
                hSendRequestWithStreamData(streamData, varargin{:});

            testCase.verifyError(@() generate(client, "Hi"), "aisdk:unreadableResponse");
        end

        function generate_streamedToolCallWithoutItems_throwsUnreadableResponse(testCase)
            client = testCase.createClient( ...
                "gpt-4o", APIKey="fake-key", StreamFcn=@(~) [], ...
                BaseURL="https://example.invalid/v1");

            % The Responses endpoint sends a Chat Completions tool call instead.
            streamData = ['data: {"choices":[{"index":0,"delta":{"tool_calls":[' ...
                '{"index":0,"id":"call_1","type":"function",' ...
                '"function":{"name":"getWeather","arguments":"{}"}}' ...
                ']},"finish_reason":"tool_calls"}]}' newline newline];
            client.sendRequestFcn = @(varargin) ...
                hSendRequestWithStreamData(streamData, varargin{:});

            testCase.verifyError(@() generate(client, "What's the weather?"), ...
                "aisdk:unreadableResponse");
        end

        function generate_streamedEmptyCompletion_returnsEmptyText(testCase)
            client = testCase.createClient( ...
                "gpt-4o", APIKey="fake-key", StreamFcn=@(~) [], ...
                BaseURL="https://example.invalid/v1");

            streamData = ['data: {"type":"response.completed","response":{' ...
                '"id":"resp_1","object":"response","status":"completed","output":[],' ...
                '"usage":{"input_tokens":4,"output_tokens":0,"total_tokens":4}}}' ...
                newline newline];
            client.sendRequestFcn = @(varargin) ...
                hSendRequestWithStreamData(streamData, varargin{:});

            [text, messages, info] = generate(client, "Hi");

            testCase.verifyEqual(text, "");
            testCase.verifyNumElements(messages, 1);
            testCase.verifyClass(messages, "aisdk.LLMTextMessage");
            testCase.verifyEqual(messages.Role, "assistant");
            testCase.verifyEqual(messages.Text, "");
            testCase.verifyEqual(info.Tokens.NumInputTokens, 4);
            testCase.verifyEqual(info.Tokens.NumOutputTokens, 0);
            testCase.verifyEqual(info.Tokens.NumTotalTokens, 4);
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

    methods (Test, TestTags = {'Integration'})
        %% Agent loop over the Responses client
        % A real aisdk.AIAgent, a real aisdk.LLMTool and the client run two
        % turns behind a fake sendRequestFcn, so the request the agent builds
        % out of items it produced itself is asserted without a network call.
        function run_withToolCall_sendsCallAndOutputItemsOnSecondTurn(testCase)
            toolCall = struct("id", "call_1", "name", "squareNumber", "arguments", '{"x":5}');
            firstTurnText = "Let me compute that.";
            [answer, agent, captured] = testCase.runAgentOverTwoTurns( ...
                squareNumberTool(), "What is 5 squared?", ...
                testCase.toolCallResponse({toolCall}, firstTurnText), ...
                testCase.textResponse("Five squared is 25."));

            % Both turns carried text, so the answer holds each of them in turn order.
            testCase.verifyEqual(answer, firstTurnText + newline + "Five squared is 25.");

            % The loop selected the tool, ran it, and kept its computed value.
            toolResults = agent.Messages([agent.Messages.Role] == "tool");
            testCase.assertNumElements(toolResults, 1);
            testCase.verifyEqual(toolResults.Result, "{""result"":25}");

            input = captured{2}.input;
            testCase.assertNumElements(input, 4);
            testCase.verifyEqual(input{1}.role, "user");
            testCase.verifyEqual(input{1}.content, "What is 5 squared?");
            testCase.verifyEqual(input{2}.role, "assistant");
            testCase.verifyEqual(input{2}.content, firstTurnText);
            testCase.verifyEqual(input{3}.type, "function_call");
            testCase.verifyEqual(input{3}.call_id, "call_1");
            testCase.verifyEqual(input{3}.name, "squareNumber");
            testCase.verifyEqual(input{4}.type, "function_call_output");
            testCase.verifyEqual(input{4}.call_id, "call_1");
            testCase.verifyEqual(input{4}.output, "{""result"":25}");
        end

        function run_withParallelToolCalls_pairsEachOutputWithItsCallID(testCase)
            toolCalls = { ...
                struct("id", "call_sq", "name", "squareNumber", "arguments", '{"x":3}'), ...
                struct("id", "call_db", "name", "doubleNumber",  "arguments", '{"x":10}')};
            firstTurnText = "Squaring and doubling now.";
            [~, agent, captured] = testCase.runAgentOverTwoTurns( ...
                [squareNumberTool(), doubleNumberTool()], "Square 3 and double 10.", ...
                testCase.toolCallResponse(toolCalls, firstTurnText), ...
                testCase.textResponse("That is 9 and 20."));

            % Both tools ran, each on the arguments of its own call.
            toolResults = agent.Messages([agent.Messages.Role] == "tool");
            testCase.assertNumElements(toolResults, 2);
            testCase.verifyEqual(toolResults(1).Result, "{""result"":9}");
            testCase.verifyEqual(toolResults(2).Result, "{""result"":20}");

            % Every output names the call it answers, so the two results cannot
            % be swapped: the square belongs to call_sq and the double to call_db.
            % The text that arrived with the two calls is replayed ahead of them.
            input = captured{2}.input;
            testCase.assertNumElements(input, 6);
            testCase.verifyEqual(input{2}.role, "assistant");
            testCase.verifyEqual(input{2}.content, firstTurnText);
            testCase.verifyEqual(input{3}.type, "function_call");
            testCase.verifyEqual(input{3}.call_id, "call_sq");
            testCase.verifyEqual(input{4}.type, "function_call");
            testCase.verifyEqual(input{4}.call_id, "call_db");
            testCase.verifyEqual(input{5}.type, "function_call_output");
            testCase.verifyEqual(input{5}.call_id, "call_sq");
            testCase.verifyEqual(input{5}.output, "{""result"":9}");
            testCase.verifyEqual(input{6}.type, "function_call_output");
            testCase.verifyEqual(input{6}.call_id, "call_db");
            testCase.verifyEqual(input{6}.output, "{""result"":20}");
        end
    end

    methods (Access=private)
        function [answer, agent, captured] = runAgentOverTwoTurns(testCase, tools, prompt, firstResponse, secondResponse)
            % Run an agent whose client answers with FIRSTRESPONSE then
            % SECONDRESPONSE, capturing the parameter struct of each request.
            % The client is built before the agent because it is a value
            % class, so the agent holds a copy of the fake already installed.
            turn = 0;
            captured = {};
            responses = {firstResponse, secondResponse};
            client = testCase.createClient("gpt-4o", APIKey="fake-key");
            client.sendRequestFcn = @fakeSendRequest;
            agent = aisdk.AIAgent(client, Tools=tools, DisplayMode="off");
            answer = run(agent, prompt);
            testCase.assertNumElements(captured, 2, ...
                "The agent should have sent exactly two requests.");

            function httpResponse = fakeSendRequest(parameters, ~, ~, ~, ~, ~)
                turn = turn + 1;
                captured{turn} = parameters;
                % Indexing rather than branching: a third request would
                % fail here, which the assertion above reports.
                httpResponse = responses{turn};
            end
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

function client = streamingClient(responseData)
    % Stands in for a streamed call with a reconstructed non-streamed body.
    client = aisdk.client.OpenAIResponsesClient("gpt-4o", APIKey="fake-key", ...
        StreamFcn=@(~) []);
    mockResponse = struct("StatusCode", "OK", "Body", struct("Data", responseData));
    client.sendRequestFcn = @(~,~,~,~,~,~) mockResponse;
end

function response = hSendRequestWithStreamData(streamData, varargin)
    % Exercise sendRequest and its selected streamer with a fake HTTP transport.
    response = aisdk.client.internal.sendRequest(varargin{:}, @fakeSend);

    function response = fakeSend(~, endpoint, ~, consumer)
        consumer.URI = matlab.net.URI(endpoint);
        bytes = unicode2native(char(streamData), "UTF-8")';
        consumer.doPutData(bytes, false);
        consumer.doPutData(uint8.empty(0,1), false);
        response = struct("StatusCode", "OK", "Body", struct("Data", ""));
    end
end

function output = interleavedOutput()
    fcItem = struct("type", "function_call", "call_id", "call_1", ...
        "name", "getWeather", "arguments", '{"city":"Paris"}');
    output = {messageItem("Let me check."), fcItem, messageItem("Done.")};
end

function data = responsesParallelToolCallResponse()
    streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
    events = {
        '{"type":"response.output_item.done","output_index":0,"item":{"id":"fc_1","type":"function_call","call_id":"call_1","name":"toolA","arguments":"{\"x\":1}"}}'
        '{"type":"response.output_item.done","output_index":1,"item":{"id":"fc_2","type":"function_call","call_id":"call_2","name":"toolB","arguments":"{\"y\":2}"}}'
        };
    data = hClientTestUtils.streamEventsAndMergeResponse( ...
        streamer, events, "sse");
end

function data = responsesToolCallStream()
    streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
    events = {
        '{"type":"response.output_item.done","output_index":0,"item":{"id":"fc_1","type":"function_call","call_id":"call_1","name":"toolA","arguments":"{\"x\":1}"}}'
        };
    data = hClientTestUtils.streamEventsAndMergeResponse( ...
        streamer, events, "sse");
end

function data = responsesSplitTextOnlyStream(txt1, txt2)
    streamer = aisdk.client.internal.ResponsesResponseStreamer(@(~) []);
    txt1 = hClientTestUtils.escapeJSONText(txt1);
    txt2 = hClientTestUtils.escapeJSONText(txt2);
    events = [
        "{""type"":""response.output_text.delta"",""item_id"":""msg_1"",""delta"":""" + txt1 + """}"
        "{""type"":""response.output_text.delta"",""item_id"":""msg_1"",""delta"":""" + txt2 + """}"
        ];
    data = hClientTestUtils.streamEventsAndMergeResponse( ...
        streamer, events, "sse");
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

function tool = squareNumberTool()
    % An anonymous-function tool needs no file on the path.
    tool = aisdk.LLMTool(@(x) x^2, Name="squareNumber", ...
        Description="Square a number", ...
        InputArguments=struct(x=2), ...
        OutputArguments=struct(result=4), ...
        ApprovalRequest="never");
end

function tool = doubleNumberTool()
    tool = aisdk.LLMTool(@(x) 2*x, Name="doubleNumber", ...
        Description="Double a number", ...
        InputArguments=struct(x=2), ...
        OutputArguments=struct(result=4), ...
        ApprovalRequest="never");
end
