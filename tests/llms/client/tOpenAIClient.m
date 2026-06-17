classdef tOpenAIClient < hconstructorCommon
% Tests for aisdk.llms.client.OpenAIClient constructor.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        OpenAIDefault = struct( ...
            "PresencePenalty",  struct("prop", "PresencePenalty",  "expected", "auto"), ...
            "FrequencyPenalty", struct("prop", "FrequencyPenalty", "expected", "auto"), ...
            "ReasoningEffort",  struct("prop", "ReasoningEffort",  "expected", "auto"), ...
            "Verbosity",        struct("prop", "Verbosity",        "expected", "auto"));

        OpenAICustom = struct( ...
            "PresencePenalty",  struct("prop", "PresencePenalty",  "value", 0.5), ...
            "FrequencyPenalty", struct("prop", "FrequencyPenalty", "value", 0.4), ...
            "ReasoningEffort",  struct("prop", "ReasoningEffort",  "value", "high"), ...
            "Verbosity",        struct("prop", "Verbosity",        "value", "low"));

        InvalidReasoningEffort = struct( ...
            "bad_string", "invalid", ...
            "empty",      "");

        InvalidVerbosity = struct( ...
            "bad_string", "invalid", ...
            "empty",      "");

        ValidReasoningEffort = struct( ...
            "none",    "none", ...
            "minimal", "minimal", ...
            "low",     "low", ...
            "medium",  "medium", ...
            "high",    "high", ...
            "xhigh",   "xhigh");

        ValidVerbosity = struct( ...
            "low",    "low", ...
            "medium", "medium", ...
            "high",   "high");
    end

    methods
        function client = createClient(~, varargin)
            client = aisdk.llms.client.OpenAIClient(varargin{:});
        end
    end

    methods (Test)
        function customBaseURL(testCase)
            client = testCase.createClient("gpt-4o", BaseURL="https://custom.endpoint");
            testCase.verifyEqual(client.BaseURL, "https://custom.endpoint/chat/completions");
        end

        function defaultBaseURL(testCase)
            client = testCase.createClient("gpt-4o");
            testCase.verifyEqual(client.BaseURL, "https://api.openai.com/v1/chat/completions");
        end
    end

    methods (Test, ParameterCombination="sequential")
        function hasCorrectOpenAIDefault(testCase, OpenAIDefault)
            client = testCase.createClient("gpt-4o");
            testCase.verifyEqual(client.(OpenAIDefault.prop), OpenAIDefault.expected);
        end

        function respectsOpenAICustomValue(testCase, OpenAICustom)
            client = testCase.createClient("gpt-4o", OpenAICustom.prop, OpenAICustom.value);
            testCase.verifyEqual(client.(OpenAICustom.prop), OpenAICustom.value);
        end

        function rejectsInvalidReasoningEffort(testCase, InvalidReasoningEffort)
            testCase.verifyError( ...
                @() testCase.createClient("gpt-4o", ReasoningEffort=InvalidReasoningEffort), ...
                "MATLAB:validators:mustBeMember");
        end

        function rejectsInvalidVerbosity(testCase, InvalidVerbosity)
            testCase.verifyError( ...
                @() testCase.createClient("gpt-4o", Verbosity=InvalidVerbosity), ...
                "MATLAB:validators:mustBeMember");
        end

        function reasoningEffortAcceptsAllValid(testCase, ValidReasoningEffort)
            client = testCase.createClient("gpt-4o", ReasoningEffort=ValidReasoningEffort);
            testCase.verifyEqual(client.ReasoningEffort, ValidReasoningEffort);
        end

        function verbosityAcceptsAllValid(testCase, ValidVerbosity)
            client = testCase.createClient("gpt-4o", Verbosity=ValidVerbosity);
            testCase.verifyEqual(client.Verbosity, ValidVerbosity);
        end
    end

    methods (Test)
        %% generate — text response
        function generate_textResponse_returnsTextAndMessage(testCase)
            client = makeClientWithFakeHTTP(testCase, makeTextResponse("Hello world"));
            [text, messages] = generate(client, "Hi");
            testCase.verifyEqual(text, "Hello world");
            testCase.verifyClass(messages, "aisdk.llms.message.LLMTextMessage");
            testCase.verifyNumElements(messages, 1);
            testCase.verifyEqual(messages.Content, "Hello world");
            testCase.verifyEqual(messages.Role, "assistant");
        end

        function generate_textResponse_parsesUsageTokens(testCase)
            responseData = struct( ...
                "choices", struct("message", struct("role", "assistant", "content", "ok")), ...
                "usage", struct("prompt_tokens", 10, "completion_tokens", 5, ...
                    "total_tokens", 15, ...
                    "prompt_tokens_details", struct("cached_tokens", 3)));
            response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
            client = makeClientWithFakeHTTP(testCase, response);
            [~, ~, info] = generate(client, "Hi");
            testCase.verifyEqual(info.Tokens.NumInputTokens, 10);
            testCase.verifyEqual(info.Tokens.NumOutputTokens, 5);
            testCase.verifyEqual(info.Tokens.NumTotalTokens, 15);
            testCase.verifyEqual(info.Tokens.NumCachedInputTokens, 3);
        end

        function generate_errorResponse_throwsApiReturnedError(testCase)
            client = makeClientWithFakeHTTP(testCase, ...
                makeOpenAIErrorResponse(matlab.net.http.StatusCode.BadRequest, "bad input"));
            testCase.verifyError(@() generate(client, "Hi"), "llms:apiReturnedError");
        end

        function generate_errorResponse_includesErrorText(testCase)
            client = makeClientWithFakeHTTP(testCase, ...
                makeOpenAIErrorResponse(matlab.net.http.StatusCode.BadRequest, "invalid model name"));
            try
                generate(client, "Hi");
            catch ME
                testCase.verifySubstring(ME.message, "invalid model name");
                return
            end
            testCase.verifyFail("Expected an error to be thrown.");
        end

        function generate_errorResponse_fallbackToStatusCode(testCase)
            errorResp = struct("StatusCode", matlab.net.http.StatusCode.InternalServerError, ...
                "Body", struct("Data", struct("unexpected", "format")));
            client = makeClientWithFakeHTTP(testCase, errorResp);
            try
                generate(client, "Hi");
            catch ME
                testCase.verifySubstring(ME.message, "HTTP 500:");
                testCase.verifySubstring(ME.message, "unexpected");
                return
            end
            testCase.verifyFail("Expected an error to be thrown.");
        end

        function constructionWithoutAPIKey_succeeds(testCase)
            % Construction without API key defers error to generate time
            envVar = "OPENAI_API_KEY";
            orig = getenv(envVar);
            setenv(envVar, "");
            addTeardown(testCase, @() setenv(envVar, orig));
            client = aisdk.llms.client.OpenAIClient("gpt-4o");
            testCase.verifyClass(client, "aisdk.llms.client.OpenAIClient");
        end

        function generate_unauthorizedResponse_throwsApiReturnedError(testCase)
            envVar = "OPENAI_API_KEY";
            orig = getenv(envVar);
            setenv(envVar, "");
            addTeardown(testCase, @() setenv(envVar, orig));
            client = aisdk.llms.client.OpenAIClient("gpt-4o");
            client.sendRequestFcn = @fakeUnauthorized;
            testCase.verifyError( ...
                @() client.generate("hello"), ...
                "llms:apiReturnedError");

            function [response, streamedText] = fakeUnauthorized(~, ~, ~, ~, ~)
                response = makeOpenAIErrorResponse(matlab.net.http.StatusCode.Unauthorized, "Invalid API key");
                streamedText = "";
            end
        end

        %% generate — tool call response
        function generate_toolCallResponse_returnsToolCallMessages(testCase)
            toolCall = struct("id", "call_123", "type", "function", ...
                "function", struct("name", "getWeather", "arguments", '{"city":"London"}'));
            response = makeToolCallResponse({toolCall});
            client = makeClientWithFakeHTTP(testCase, response);
            [~, messages] = generate(client, "What's the weather?");
            testCase.verifyClass(messages, "aisdk.llms.message.LLMToolCallMessage");
            testCase.verifyEqual(messages.Name, "getWeather");
            testCase.verifyEqual(messages.Arguments, struct("city", 'London'));
            testCase.verifyEqual(messages.ToolCallID, "call_123");
        end

        function generate_toolCallResponse_multipleToolCalls(testCase)
            toolCall1 = struct("id", "call_1", "type", "function", ...
                "function", struct("name", "toolA", "arguments", '{"x":1}'));
            toolCall2 = struct("id", "call_2", "type", "function", ...
                "function", struct("name", "toolB", "arguments", '{"y":2}'));
            response = makeToolCallResponse({toolCall1, toolCall2});
            client = makeClientWithFakeHTTP(testCase, response);
            [~, messages] = generate(client, "Call both");
            testCase.verifyNumElements(messages, 2);
            testCase.verifyEqual(messages(1).Name, "toolA");
            testCase.verifyEqual(messages(2).Name, "toolB");
        end

        function generate_toolCallMissingID_returnsEmptyString(testCase)
            toolCall = struct("type", "function", ...
                "function", struct("name", "myTool", "arguments", '{"a":1}'));
            response = makeToolCallResponse({toolCall});
            client = makeClientWithFakeHTTP(testCase, response);
            [~, messages] = generate(client, "Call tool");
            testCase.verifyEqual(messages.ToolCallID, "");
        end

        function generate_toolCallArgsNotStruct_errors(testCase)
            toolCall = struct("id", "call_x", "type", "function", ...
                "function", struct("name", "myTool", "arguments", '"just a string"'));
            response = makeToolCallResponse({toolCall});
            client = makeClientWithFakeHTTP(testCase, response);
            testCase.verifyError(@() generate(client, "Call tool"), ...
                "llms:invalidToolCallArguments");
        end

        %% generate — convertMessages (captured via sendRequestFcn)
        function generate_textMessage_producesRoleContent(testCase)
            params = captureGenerateParams(testCase, ...
                aisdk.llms.message.LLMTextMessage("hello", "user"));
            testCase.verifyEqual(params.messages{1}.role, "user");
            testCase.verifyEqual(params.messages{1}.content, "hello");
        end

        function generate_systemMessage_mapsToDeveloperRole(testCase)
            messages = [
                aisdk.llms.message.LLMTextMessage("Be concise.", "system"), ...
                aisdk.llms.message.LLMTextMessage("hello", "user")];
            params = captureGenerateParams(testCase, messages);
            testCase.verifyEqual(params.messages{1}.role, "developer");
            testCase.verifyEqual(params.messages{1}.content, "Be concise.");
            testCase.verifyEqual(params.messages{2}.role, "user");
        end

        function generate_toolResultMessage_producesToolRole(testCase)
            messages = [
                aisdk.llms.message.LLMTextMessage("hi", "user"), ...
                aisdk.llms.message.LLMToolCallMessage("myTool", struct("a",1), "call_1"), ...
                aisdk.llms.message.LLMToolResultMessage("result text", "myTool", "call_1")];
            params = captureGenerateParams(testCase, messages);
            toolMsg = params.messages{3};
            testCase.verifyEqual(toolMsg.role, "tool");
            testCase.verifyEqual(toolMsg.tool_call_id, "call_1");
            testCase.verifyEqual(toolMsg.name, "myTool");
            testCase.verifyEqual(toolMsg.content, "result text");
        end

        function generate_toolCallMessages_mergeIntoAssistant(testCase)
            messages = [
                aisdk.llms.message.LLMTextMessage("hi", "user"), ...
                aisdk.llms.message.LLMToolCallMessage("toolA", struct("x",1), "call_1"), ...
                aisdk.llms.message.LLMToolCallMessage("toolB", struct("y",2), "call_2")];
            params = captureGenerateParams(testCase, messages);
            assistantMsg = params.messages{2};
            testCase.verifyEqual(assistantMsg.role, "assistant");
            testCase.verifyNumElements(assistantMsg.tool_calls, 2);
        end

        function generate_imageMessage_producesImageUrl(testCase)
            imgData = uint8(zeros(2, 2, 3));
            messages = [
                aisdk.llms.message.LLMTextMessage("hi", "user"), ...
                aisdk.llms.message.LLMImageMessage(imgData, "user", Detail="low")];
            params = captureGenerateParams(testCase, messages);
            imgMsg = params.messages{2};
            testCase.verifyEqual(imgMsg.role, "user");
            content = imgMsg.content{1};
            testCase.verifyEqual(content.type, "image_url");
            testCase.verifyTrue(startsWith(content.image_url.url, "data:image/png;base64,"));
            testCase.verifyEqual(content.image_url.detail, "low");
        end

        %% generate — tool calls with text
        % The API may return both content (text) and tool calls. We should return text independently of
        % tool calls, including for structured output.
        function generate_toolCallsNoText_returnsEmptyText(testCase)
            response = makeToolCallResponse({toolCallFixture()});
            client = makeClientWithFakeHTTP(testCase, response);
            [text, ~] = generate(client, "Call a tool");
            testCase.verifyEqual(text, "");
        end

        function generate_toolCallsNullContent_returnsEmptyText(testCase)
            response = makeToolCallResponseWithContent(jsondecode('null'), {toolCallFixture()});
            client = makeClientWithFakeHTTP(testCase, response);
            [text, ~] = generate(client, "Call a tool");
            testCase.verifyEqual(text, "");
        end

        function generate_toolCallsWithText_returnsTextAndToolCalls(testCase)
            response = makeToolCallResponseWithContent("Let me calculate that", {toolCallFixture()});
            client = makeClientWithFakeHTTP(testCase, response);
            [text, messages] = generate(client, "Call a tool");
            testCase.verifyEqual(text, "Let me calculate that");
            testCase.verifyClass(messages, "aisdk.llms.message.LLMToolCallMessage");
        end

        function generate_toolCallsWithStructuredText_returnsDecodedStruct(testCase)
            response = makeToolCallResponseWithContent('{"name":"Alice","score":9.5}', {toolCallFixture()});
            client = makeClientWithFakeHTTP(testCase, response);
            proto = struct("name", "", "score", 0.0);
            [text, messages] = generate(client, "Call a tool", ResponseFormat=proto);
            testCase.verifyEqual(text.name, "Alice");
            testCase.verifyEqual(text.score, 9.5);
            testCase.verifyClass(messages, "aisdk.llms.message.LLMToolCallMessage");
        end

    end

end

function response = makeOpenAIErrorResponse(statusCode, errorText)
    response = struct("StatusCode", statusCode, ...
        "Body", struct("Data", struct("error", struct("message", errorText))));
end

function client = makeClientWithFakeHTTP(~, mockResponse)
    client = aisdk.llms.client.OpenAIClient("gpt-4o", APIKey="fake-key");
    client.sendRequestFcn = @(~,~,~,~,~) deal(mockResponse, "");
end

function response = makeTextResponse(text)
    responseData = struct( ...
        "choices", struct("message", struct("role", "assistant", "content", text)), ...
        "usage", struct("prompt_tokens", 10, "completion_tokens", 5, "total_tokens", 15));
    response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
end

function response = makeToolCallResponse(toolCalls)
    response = makeToolCallResponseWithContent("", toolCalls);
end

function response = makeToolCallResponseWithContent(content, toolCalls)
    message = struct("role", "assistant", "content", content, "tool_calls", {toolCalls});
    responseData = struct("choices", struct("message", message), ...
        "usage", struct("prompt_tokens", 5, "completion_tokens", 5, "total_tokens", 10));
    response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
end

function tc = toolCallFixture()
    tc = struct("id", "call_123", "type", "function", ...
        "function", struct("name", "getWeather", "arguments", '{"city":"London"}'));
end

function params = captureGenerateParams(~, messages)
    captured = {};
    client = aisdk.llms.client.OpenAIClient("gpt-4o", APIKey="fake-key");
    client.sendRequestFcn = @fakeSendRequest;
    generate(client, messages);
    params = captured{1};

    function [response, streamedText] = fakeSendRequest(parameters, ~, ~, ~, ~)
        captured{1} = parameters;
        responseData = struct( ...
            "choices", struct( ...
                "message", struct("role", "assistant", "content", "fake")), ...
            "usage", struct( ...
                "prompt_tokens", 0, "completion_tokens", 0, "total_tokens", 0));
        response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
        streamedText = "";
    end
end

