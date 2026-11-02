classdef tOllamaClient < hconstructorCommon
% Tests for aisdk.client.OllamaClient constructor.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        OllamaDefault = struct( ...
            "StopSequences",     struct("prop", "StopSequences",     "expected", []), ...
            "MinP",              struct("prop", "MinP",              "expected", "auto"), ...
            "TopK",              struct("prop", "TopK",              "expected", "auto"), ...
            "TailFreeSamplingZ", struct("prop", "TailFreeSamplingZ", "expected", "auto"));

        OllamaCustom = struct( ...
            "StopSequences",     struct("prop", "StopSequences",     "value", ["stop1","stop2"]), ...
            "MinP",              struct("prop", "MinP",              "value", 0.1), ...
            "TopK",              struct("prop", "TopK",              "value", 50), ...
            "TailFreeSamplingZ", struct("prop", "TailFreeSamplingZ", "value", 0.95));
    end

    methods
        function client = createClient(~, varargin)
            client = aisdk.client.OllamaClient(varargin{:});
        end
    end

    methods (Test, TestTags = {'Unit'})
        function customBaseURL(testCase)
            client = testCase.createClient("qwen3:0.6b", BaseURL="http://myserver:11434");
            testCase.verifyEqual(client.BaseURL, "http://myserver:11434/api/chat");
        end

        function defaultBaseURL(testCase)
            client = testCase.createClient("qwen3:0.6b");
            testCase.verifyEqual(client.BaseURL, "http://127.0.0.1:11434/api/chat");
        end
        function generate_topLevelID_preferredOverIndex(testCase)
            toolCall = struct("id", "call_abc123", "function", struct( ...
                "name", "myTool", ...
                "index", 0, ...
                "arguments", struct("a", 1)));
            message = struct("role", "assistant", "content", "", ...
                "tool_calls", {{toolCall}});
            resp = struct("StatusCode", "OK", ...
                "Body", struct("Data", struct("message", message)));

            [mock, behaviour] = createMock(testCase, AddedMethods="sendRequest");
            testCase.assignOutputsWhen( ...
                withAnyInputs(behaviour.sendRequest), resp, "");

            client = testCase.createClient("qwen3:0.6b");
            client.sendRequestFcn = @(varargin) mock.sendRequest(varargin{:});
            [~, msgs] = generate(client, "Call the tool.");
            testCase.verifyEqual(msgs(1).ToolCallID, "call_abc123");
        end

        function generate_missingID_fallsBackToIndex(testCase)
            toolCall = struct("function", struct( ...
                "name", "myTool", ...
                "index", 0, ...
                "arguments", struct("a", 1)));
            message = struct("role", "assistant", "content", "", ...
                "tool_calls", {{toolCall}});
            resp = struct("StatusCode", "OK", ...
                "Body", struct("Data", struct("message", message)));

            [mock, behaviour] = createMock(testCase, AddedMethods="sendRequest");
            testCase.assignOutputsWhen( ...
                withAnyInputs(behaviour.sendRequest), resp, "");

            client = testCase.createClient("qwen3:0.6b");
            client.sendRequestFcn = @(varargin) mock.sendRequest(varargin{:});
            [~, msgs] = generate(client, "Call the tool.");
            testCase.verifyEqual(msgs(1).ToolCallID, "0");
        end

        function generate_missingIDAndIndex_returnsEmptyString(testCase)
            toolCall = struct("function", struct( ...
                "name", "myTool", ...
                "arguments", struct("a", 1)));
            message = struct("role", "assistant", "content", "", ...
                "tool_calls", {{toolCall}});
            resp = struct("StatusCode", "OK", ...
                "Body", struct("Data", struct("message", message)));

            [mock, behaviour] = createMock(testCase, AddedMethods="sendRequest");
            testCase.assignOutputsWhen( ...
                withAnyInputs(behaviour.sendRequest), resp, "");

            client = testCase.createClient("qwen3:0.6b");
            client.sendRequestFcn = @(varargin) mock.sendRequest(varargin{:});
            [~, msgs] = generate(client, "Call the tool.");
            testCase.verifyEqual(msgs(1).ToolCallID, "");
        end

        %% generate — text response
        function generate_textResponse_returnsTextAndMessage(testCase)
            client = makeOllamaClientWithFakeHTTP(testCase, makeOllamaTextResponse("Hello"));
            [text, messages] = generate(client, "Hi");
            testCase.verifyEqual(text, "Hello");
            testCase.verifyClass(messages, "aisdk.LLMTextMessage");
            testCase.verifyNumElements(messages, 1);
            testCase.verifyEqual(messages.Text, "Hello");
        end

        function generate_textResponse_unwrapsCellBodyData(testCase)
            responseData = struct("message", struct("role", "assistant", "content", "wrapped"));
            response = struct("StatusCode", "OK", "Body", struct("Data", {{responseData}}));
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            [text, ~] = generate(client, "Hi");
            testCase.verifyEqual(text, "wrapped");
        end

        function generate_errorResponse_throws(testCase)
            client = makeOllamaClientWithFakeHTTP(testCase, ...
                makeOllamaErrorResponse(matlab.net.http.StatusCode.NotFound, "model 'qwen3' not found"));
            testCase.verifyError(@() generate(client, "Hi"), "aisdk:apiReturnedError");
        end

        %% generate — tool call response
        function generate_toolCallResponse_decodesStringArgs(testCase)
            toolCall = struct("function", struct( ...
                "name", "myTool", "index", 0, ...
                "arguments", '{"a":1}'));
            message = struct("role", "assistant", "content", "", ...
                "tool_calls", {{toolCall}});
            response = struct("StatusCode", "OK", ...
                "Body", struct("Data", struct("message", message)));
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            [~, messages] = generate(client, "Call tool");
            testCase.verifyEqual(messages.Arguments.a, 1);
        end

        function generate_toolCallResponse_passesStructArgs(testCase)
            toolCall = struct("function", struct( ...
                "name", "myTool", "index", 1, ...
                "arguments", struct("x", 42)));
            message = struct("role", "assistant", "content", "", ...
                "tool_calls", {{toolCall}});
            response = struct("StatusCode", "OK", ...
                "Body", struct("Data", struct("message", message)));
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            [~, messages] = generate(client, "Call tool");
            testCase.verifyEqual(messages.Arguments.x, 42);
        end

        function generate_toolCallArgsNotStruct_errors(testCase)
            toolCall = struct("function", struct( ...
                "name", "myTool", "index", 0, ...
                "arguments", '"hello"'));
            message = struct("role", "assistant", "content", "", ...
                "tool_calls", {{toolCall}});
            response = struct("StatusCode", "OK", ...
                "Body", struct("Data", struct("message", message)));
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            testCase.verifyError(@() generate(client, "Call tool"), "aisdk:invalidToolCallArguments");
        end

        %% generate — convertMessages (Ollama-specific fields)
        function generate_toolResultMessage_usesToolName(testCase)
            messages = [
                aisdk.LLMTextMessage("hi"), ...
                aisdk.LLMToolCallMessage("myTool", struct("a",1), ToolCallID="0"), ...
                aisdk.LLMToolResultMessage("result", ToolCallID="0", Name="myTool")];
            params = captureOllamaParams(testCase, messages);
            toolMsg = params.messages{3};
            testCase.verifyEqual(toolMsg.role, "tool");
            testCase.verifyEqual(toolMsg.tool_name, "myTool");
        end

        function generate_emptyToolCallID_serializesAsEmptyString(testCase)
            messages = [
                aisdk.LLMTextMessage("hi"), ...
                aisdk.LLMToolCallMessage("myTool", struct("a",1))];
            params = captureOllamaParams(testCase, messages);
            assistantMsg = params.messages{2};
            testCase.verifyEqual(assistantMsg.tool_calls{1}.id, "");
        end

        function generate_imageMessage_usesImagesField(testCase)
            imgData = uint8(zeros(2, 2, 3));
            messages = [
                aisdk.LLMTextMessage("hi"), ...
                aisdk.LLMImageMessage(imgData)];
            params = captureOllamaParams(testCase, messages);
            imgMsg = params.messages{2};
            testCase.verifyEqual(imgMsg.content, "");
            testCase.verifyTrue(isfield(imgMsg, "images"));
            testCase.verifyNotEmpty(imgMsg.images{1});
        end

        %% generate — usage parsing
        function generate_usageCounts_parsesTokens(testCase)
            responseData = struct("message", struct("role", "assistant", "content", "ok"), ...
                "prompt_eval_count", 8, "eval_count", 12);
            response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            [~, ~, info] = generate(client, "Hi");
            testCase.verifyEqual(info.Tokens.NumInputTokens, 8);
            testCase.verifyEqual(info.Tokens.NumOutputTokens, 12);
            testCase.verifyEqual(info.Tokens.NumTotalTokens, 20);
        end

        function generate_streamedUsage_matchesNonStreamedUsage(testCase)
            streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);
            event = ['{"message":{"role":"assistant","content":""},' ...
                '"done":true,"prompt_eval_count":8,"eval_count":12}'];
            streamedData = hClientTestUtils.streamEventsAndMergeResponse( ...
                streamer, event, "ndjson");

            streamedClient = testCase.createClient( ...
                "qwen3:0.6b", StreamFcn=@(~) []);
            streamedClient.sendRequestFcn = @streamedResponse;
            [~, ~, streamedInfo] = generate(streamedClient, "Hi");

            responseData = struct( ...
                "message", struct("role", "assistant", "content", "ok"), ...
                "prompt_eval_count", 8, ...
                "eval_count", 12);
            nonStreamedClient = makeOllamaClientWithFakeHTTP(testCase, ...
                struct("StatusCode", "OK", "Body", struct("Data", responseData)));
            [~, ~, nonStreamedInfo] = generate(nonStreamedClient, "Hi");

            testCase.verifyEqual(streamedInfo.Tokens, nonStreamedInfo.Tokens);

            function response = streamedResponse(~, ~, ~, ~, ~, ~)
                body = struct();
                body.Data = streamedData;
                response = struct( ...
                    "StatusCode", "OK", ...
                    "Body", body);
            end
        end

        function generate_streamedToolCall_returnsToolCallMessage(testCase)
            streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);
            event = ['{"message":{"role":"assistant","content":"",' ...
                '"tool_calls":[{"function":{"name":"getWeather",' ...
                '"arguments":{"city":"London"}}}]},"done":true}'];
            streamedData = hClientTestUtils.streamEventsAndMergeResponse( ...
                streamer, event, "ndjson");

            client = testCase.createClient( ...
                "qwen3:0.6b", StreamFcn=@(~) []);
            client.sendRequestFcn = @streamedResponse;

            [~, messages] = generate(client, "What's the weather?");

            testCase.verifyClass(messages, "aisdk.LLMToolCallMessage");
            testCase.verifyEqual(messages.Name, "getWeather");
            testCase.verifyEqual(messages.Arguments, struct("city", 'London'));

            function response = streamedResponse(~, ~, ~, ~, ~, ~)
                body = struct();
                body.Data = streamedData;
                response = struct("StatusCode", "OK", "Body", body);
            end
        end

        function generate_streamedParallelToolCalls_returnsAllMessages(testCase)
            client = testCase.createClient( ...
                "qwen3:0.6b", StreamFcn=@(~) []);
            responseData = ollamaParallelToolCallResponse();

            hClientTestUtils.verifyStreamedParallelToolCalls(testCase, client, responseData);
        end

        function generate_streamedTextOnly_returnsTextMessage(testCase)
            client = testCase.createClient( ...
                "qwen3:0.6b", StreamFcn=@(~) []);

            txt1 = "Hello ";
            txt2 = "world";
            responseData = ollamaSplitTextOnlyStream(txt1, txt2);

            hClientTestUtils.verifyStreamedTextOnly( ...
                testCase, client, responseData, txt1 + txt2);
        end

        function generate_streamedJSONLookingText_returnsTextMessage(testCase)
            client = testCase.createClient( ...
                "qwen3:0.6b", StreamFcn=@(~) []);

            txt1 = "Arguments: ";
            txt2 = "{""a"":1}";
            responseData = ollamaSplitTextOnlyStream(txt1, txt2);

            hClientTestUtils.verifyStreamedTextOnly( ...
                testCase, client, responseData, txt1 + txt2);
        end

        function generate_streamedStructuredText_returnsDecodedStruct(testCase)
            client = testCase.createClient( ...
                "qwen3:0.6b", StreamFcn=@(~) []);
            responseData = ollamaSplitTextOnlyStream("{""answer"":", "42}");

            prototype = struct("answer", 0);
            expected = struct("answer", 42);
            hClientTestUtils.verifyStreamedStructuredOutput( ...
                testCase, client, responseData, prototype, expected);
        end

        function generate_streamedToolCallsNoTextWithPrototypeFormat_returnsEmptyText(testCase)
            client = testCase.createClient( ...
                "qwen3:0.6b", StreamFcn=@(~) []);
            response = hClientTestUtils.okResponse(ollamaToolCallStream());
            client.sendRequestFcn = @(~,~,~,~,~,~) response;

            hClientTestUtils.verifyToolCallsNoText(testCase, client, ...
                ResponseFormat=struct("answer", 0));
        end

        function generate_missingUsage_defaultsZero(testCase)
            responseData = struct("message", struct("role", "assistant", "content", "ok"));
            response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            [~, ~, info] = generate(client, "Hi");
            testCase.verifyEqual(info.Tokens.NumInputTokens, 0);
            testCase.verifyEqual(info.Tokens.NumOutputTokens, 0);
        end

        %% generate — tool calls with text
        % The API may return both content (text) and tool calls. We should return text independently of
        % tool calls, including for structured output.
        function generate_toolCallsNoText_returnsEmptyText(testCase)
            response = makeOllamaToolCallResponse("");
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            hClientTestUtils.verifyToolCallsNoText(testCase, client);
        end

        function generate_toolCallsNoTextWithPrototypeFormat_returnsEmptyText(testCase)
            response = makeOllamaToolCallResponse("");
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            hClientTestUtils.verifyToolCallsNoText(testCase, client, ...
                ResponseFormat=struct("answer", 0));
        end

        function generate_toolCallsNoTextWithJSONSchemaFormat_returnsEmptyText(testCase)
            response = makeOllamaToolCallResponse("");
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            hClientTestUtils.verifyToolCallsNoText(testCase, client, ...
                ResponseFormat='{"type":"object","properties":{"answer":{"type":"number"}}}');
        end

        function generate_toolCallsNullContent_returnsEmptyText(testCase)
            response = makeOllamaToolCallResponse(jsondecode('null'));
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            [text, ~] = generate(client, "Call a tool");
            testCase.verifyEqual(text, "");
        end

        function generate_toolCallsWithText_returnsTextAndToolCalls(testCase)
            response = makeOllamaToolCallResponse("Let me calculate that");
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            [text, messages] = generate(client, "Call a tool");
            testCase.verifyEqual(text, "Let me calculate that");
            toolCalls = messages(arrayfun(@(m) isa(m, "aisdk.LLMToolCallMessage"), messages));
            testCase.assertNumElements(toolCalls, 1);
            testCase.verifyEqual(toolCalls.Name, "getWeather");
        end

        function generate_toolCallsWithText_returnsTextMessageBeforeToolCalls(testCase)
            response = makeOllamaToolCallResponse("Let me calculate that");
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            [~, messages] = generate(client, "Call a tool");
            testCase.assertNumElements(messages, 2, ...
                "Expected one assistant text message and one tool call message.");
            testCase.verifyClass(messages(1), "aisdk.LLMTextMessage");
            testCase.verifyEqual(messages(1).Role, "assistant");
            testCase.verifyEqual(messages(1).Text, "Let me calculate that");
            testCase.verifyClass(messages(2), "aisdk.LLMToolCallMessage");
        end

        function generate_toolCallsWithTextReplayed_sendsAssistantText(testCase)
            response = makeOllamaToolCallResponse("Let me calculate that");
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            [~, messages] = generate(client, "Call a tool");
            params = captureOllamaParams(testCase, [
                aisdk.LLMTextMessage("Call a tool"), ...
                messages, ...
                aisdk.LLMToolResultMessage("sunny", ToolCallID="0", Name="getWeather")]);
            testCase.assertNumElements(params.messages, 3, ...
                "Expected the user message, one assistant message and the tool result.");
            assistantMsg = params.messages{2};
            testCase.verifyEqual(assistantMsg.role, "assistant");
            testCase.verifyEqual(assistantMsg.content, "Let me calculate that");
            testCase.verifyNumElements(assistantMsg.tool_calls, 1);
        end

        function generate_toolCallsWithStructuredText_returnsDecodedStruct(testCase)
            response = makeOllamaToolCallResponse('{"name":"Alice","score":9.5}');
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            proto = struct("name", "", "score", 0.0);
            [text, messages] = generate(client, "Call a tool", ResponseFormat=proto);
            testCase.verifyEqual(text.name, "Alice");
            testCase.verifyEqual(text.score, 9.5);
            testCase.assertNumElements(messages, 2, ...
                "Expected one assistant text message and one tool call message.");
            testCase.verifyEqual(messages(1).Text, "{""name"":""Alice"",""score"":9.5}");
            testCase.verifyClass(messages(2), "aisdk.LLMToolCallMessage");
        end

        %% generate — structured output with nothing to report
        % A model that has nothing to list answers with an empty list. The result
        % must still be a struct of the requested form, not an empty double.
        function generate_structuredOutputEmptyList_returnsEmptyStruct(testCase)
            import matlab.unittest.constraints.IsSameSetAs
            response = makeOllamaTextResponse('{"result":[]}');
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            proto = struct("plantName", {"appletree","pear"}, "fruit", {"apple","pear"});
            text = generate(client, "What is harvested in August?", ResponseFormat=proto);
            testCase.verifyClass(text, "struct");
            testCase.verifyEmpty(text);
            testCase.verifyThat(fieldnames(text), IsSameSetAs(fieldnames(proto)));
        end

        function generate_emptyTextWithoutToolCallsWithPrototypeFormat_throwsModelReturnedNoOutput(testCase)
            client = makeOllamaClientWithFakeHTTP(testCase, makeOllamaTextResponse(""));
            testCase.verifyError( ...
                @() generate(client, "Hi", ResponseFormat=struct("answer", 0)), ...
                "aisdk:modelReturnedNoOutput");
        end
    end

    methods (Test, TestTags = {'Unit'})
        function ollamaProperty_notSet_hasDefaultValue(testCase, OllamaDefault)
            client = testCase.createClient("qwen3:0.6b");
            testCase.verifyEqual(client.(OllamaDefault.prop), OllamaDefault.expected);
        end

        function ollamaProperty_setAtConstruction_keepsValue(testCase, OllamaCustom)
            client = testCase.createClient("qwen3:0.6b", OllamaCustom.prop, OllamaCustom.value);
            testCase.verifyEqual(client.(OllamaCustom.prop), OllamaCustom.value);
        end
    end

end

function client = makeOllamaClientWithFakeHTTP(~, mockResponse)
    client = aisdk.client.OllamaClient("qwen3:0.6b");
    client.sendRequestFcn = @(~,~,~,~,~,~) mockResponse;
end

function response = makeOllamaErrorResponse(statusCode, errorText)
    response = struct("StatusCode", statusCode, ...
        "Body", struct("Data", struct("error", errorText)));
end

function response = makeOllamaTextResponse(text)
    responseData = struct("message", struct("role", "assistant", "content", text));
    response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
end

function response = makeOllamaToolCallResponse(content)
    toolCall = struct("function", struct( ...
        "name", "getWeather", "index", 0, ...
        "arguments", struct("city", "London")));
    message = struct("role", "assistant", "content", content, ...
        "tool_calls", {{toolCall}});
    responseData = struct("message", message);
    response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
end

function data = ollamaParallelToolCallResponse()
    streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);
    event = ['{"message":{"role":"assistant","content":"","tool_calls":[' ...
        '{"id":"call_1","function":{"name":"toolA","arguments":{"x":1}}},' ...
        '{"id":"call_2","function":{"name":"toolB","arguments":{"y":2}}}' ...
        ']},"done":true}'];
    data = hClientTestUtils.streamEventsAndMergeResponse( ...
        streamer, event, "ndjson");
end

function data = ollamaToolCallStream()
    streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);
    event = ['{"message":{"role":"assistant","content":"","tool_calls":[' ...
        '{"id":"call_1","function":{"name":"toolA","arguments":{"x":1}}}' ...
        ']},"done":true}'];
    data = hClientTestUtils.streamEventsAndMergeResponse( ...
        streamer, event, "ndjson");
end

function data = ollamaSplitTextOnlyStream(txt1, txt2)
    streamer = aisdk.client.internal.OllamaResponseStreamer(@(~) []);
    txt1 = hClientTestUtils.escapeJSONText(txt1);
    txt2 = hClientTestUtils.escapeJSONText(txt2);
    events = [
        "{""message"":{""role"":""assistant"",""content"":""" + txt1 + """},""done"":false}"
        "{""message"":{""role"":""assistant"",""content"":""" + txt2 + """},""done"":true}"
        ];
    data = hClientTestUtils.streamEventsAndMergeResponse( ...
        streamer, events, "ndjson");
end

function params = captureOllamaParams(~, messages)
    captured = {};
    client = aisdk.client.OllamaClient("qwen3:0.6b");
    client.sendRequestFcn = @fakeSendRequest;
    generate(client, messages);
    params = captured{1};

    function response = fakeSendRequest(parameters, ~, ~, ~, ~, ~)
        captured{1} = parameters;
        responseData = struct("message", struct("role", "assistant", "content", "fake"));
        response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
    end
end
