classdef tOllamaClient < hconstructorCommon
% Tests for aisdk.llms.client.OllamaClient constructor.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        OllamaDefault = struct( ...
            "MinP",              struct("prop", "MinP",              "expected", "auto"), ...
            "TopK",              struct("prop", "TopK",              "expected", "auto"), ...
            "TailFreeSamplingZ", struct("prop", "TailFreeSamplingZ", "expected", "auto"));

        OllamaCustom = struct( ...
            "MinP",              struct("prop", "MinP",              "value", 0.1), ...
            "TopK",              struct("prop", "TopK",              "value", 50), ...
            "TailFreeSamplingZ", struct("prop", "TailFreeSamplingZ", "value", 0.95));
    end

    methods
        function client = createClient(~, varargin)
            client = aisdk.llms.client.OllamaClient(varargin{:});
        end
    end

    methods (Test)
        function customBaseURL(testCase)
            client = testCase.createClient("qwen3:0.6b", BaseURL="http://myserver:11434");
            testCase.verifyEqual(client.BaseURL, "http://myserver:11434/api/chat");
        end

        function defaultBaseURL(testCase)
            client = testCase.createClient("qwen3:0.6b");
            testCase.verifyEqual(client.BaseURL, "http://127.0.0.1:11434/api/chat");
        end
    end

    methods (Test)
        function numericToolCallIndexConvertedToString(testCase)
            % Ollama returns tool_call index as a number; generate must
            % convert it to a string so that ToolCallID is always a string.
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
            testCase.verifyClass(msgs, 'aisdk.LLMToolCallMessage');
            testCase.verifyEqual(msgs(1).ToolCallID, "0");
        end

        function missingIndexGetsEmptyString(testCase)
            % When Ollama omits the index field, generate assigns "".
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
    end

    methods (Test)
        %% generate — text response
        function generate_textResponse_returnsTextAndMessage(testCase)
            client = makeOllamaClientWithFakeHTTP(testCase, makeOllamaTextResponse("Hello"));
            [text, messages] = generate(client, "Hi");
            testCase.verifyEqual(text, "Hello");
            testCase.verifyClass(messages, "aisdk.LLMTextMessage");
            testCase.verifyNumElements(messages, 1);
            testCase.verifyEqual(messages.Content, "Hello");
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
            testCase.verifyError(@() generate(client, "Hi"), "llms:apiReturnedError");
        end

        function generate_errorResponse_includesErrorText(testCase)
            client = makeOllamaClientWithFakeHTTP(testCase, ...
                makeOllamaErrorResponse(matlab.net.http.StatusCode.NotFound, "model 'qwen3' not found"));
            try
                generate(client, "Hi");
            catch ME
                testCase.verifySubstring(ME.message, "model 'qwen3' not found");
                return
            end
            testCase.verifyFail("Expected an error to be thrown.");
        end

        function generate_errorResponse_fallbackToStatusCode(testCase)
            errorResp = struct("StatusCode", matlab.net.http.StatusCode.InternalServerError, ...
                "Body", struct("Data", struct("unexpected", "format")));
            client = makeOllamaClientWithFakeHTTP(testCase, errorResp);
            try
                generate(client, "Hi");
            catch ME
                testCase.verifySubstring(ME.message, "HTTP 500:");
                testCase.verifySubstring(ME.message, "unexpected");
                return
            end
            testCase.verifyFail("Expected an error to be thrown.");
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
            testCase.verifyError(@() generate(client, "Call tool"), "llms:invalidToolCallArguments");
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
            [text, ~] = generate(client, "Call a tool");
            testCase.verifyEqual(text, "");
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
            testCase.verifyClass(messages, "aisdk.LLMToolCallMessage");
        end

        function generate_toolCallsWithStructuredText_returnsDecodedStruct(testCase)
            response = makeOllamaToolCallResponse('{"name":"Alice","score":9.5}');
            client = makeOllamaClientWithFakeHTTP(testCase, response);
            proto = struct("name", "", "score", 0.0);
            [text, messages] = generate(client, "Call a tool", ResponseFormat=proto);
            testCase.verifyEqual(text.name, "Alice");
            testCase.verifyEqual(text.score, 9.5);
            testCase.verifyClass(messages, "aisdk.LLMToolCallMessage");
        end
    end

    methods (Test, ParameterCombination="sequential")
        function hasCorrectOllamaDefault(testCase, OllamaDefault)
            client = testCase.createClient("qwen3:0.6b");
            testCase.verifyEqual(client.(OllamaDefault.prop), OllamaDefault.expected);
        end

        function respectsOllamaCustomValue(testCase, OllamaCustom)
            client = testCase.createClient("qwen3:0.6b", OllamaCustom.prop, OllamaCustom.value);
            testCase.verifyEqual(client.(OllamaCustom.prop), OllamaCustom.value);
        end
    end

end

function client = makeOllamaClientWithFakeHTTP(~, mockResponse)
    client = aisdk.llms.client.OllamaClient("qwen3:0.6b");
    client.sendRequestFcn = @(~,~,~,~,~) deal(mockResponse, "");
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

function params = captureOllamaParams(~, messages)
    captured = {};
    client = aisdk.llms.client.OllamaClient("qwen3:0.6b");
    client.sendRequestFcn = @fakeSendRequest;
    generate(client, messages);
    params = captured{1};

    function [response, streamedText] = fakeSendRequest(parameters, ~, ~, ~, ~)
        captured{1} = parameters;
        responseData = struct("message", struct("role", "assistant", "content", "fake"));
        response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
        streamedText = "";
    end
end
