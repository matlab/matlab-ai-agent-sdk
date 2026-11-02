classdef (Abstract) hOpenAIClientCommon < hconstructorCommon
% Tests shared by the OpenAI clients. Subclasses supply the wire format of
% their API through the abstract methods: canned responses, where the
% request carries the conversation, and how each request scenario below is
% encoded.

%   Copyright 2026 The MathWorks, Inc.

    properties (Abstract, Constant)
        %ClientClass   Class name of the client under test.
        ClientClass

        %EndpointPath   Path the client appends to its base URL.
        EndpointPath

        %MaxNumTokensField   Request field that carries MaxNumTokens.
        MaxNumTokensField
    end

    properties (TestParameter)
        OpenAIDefault = struct( ...
            "ReasoningEffort",  struct("prop", "ReasoningEffort",  "expected", "auto"), ...
            "Verbosity",        struct("prop", "Verbosity",        "expected", "auto"));

        OpenAICustom = struct( ...
            "ReasoningEffort",  struct("prop", "ReasoningEffort",  "value", "high"), ...
            "Verbosity",        struct("prop", "Verbosity",        "value", "low"));

        InvalidReasoningEffort = struct( ...
            "bad_string", "invalid", ...
            "empty",      "");

        InvalidVerbosity = struct( ...
            "bad_string", "invalid", ...
            "empty",      "");

        ValidReasoningEffort = {"none","minimal","low","medium","high","xhigh"};

        ValidVerbosity = struct( ...
            "low",    "low", ...
            "medium", "medium", ...
            "high",   "high");
    end

    methods (Abstract, Access=protected)
        %textResponse   Successful response with TEXT and usage 10/5/15, 3 cached.
        response = textResponse(testCase, text)

        %toolCallResponse   Successful response with TOOLCALLS and TEXT.
        %   TOOLCALLS is a cell array of structs with fields id, name and
        %   arguments.
        response = toolCallResponse(testCase, toolCalls, text)

        %toolCallWithoutIDResponse   Successful response with one tool call
        %   that has no ID.
        response = toolCallWithoutIDResponse(testCase, name, arguments)

        %sentMessages   The conversation items of a captured request.
        messages = sentMessages(testCase, params)

        verifyToolCallAndResultSent(testCase, params)
        verifyTwoToolCallsSent(testCase, params)
        verifyToolCallWithoutIDSentWithEmptyID(testCase, params)
        verifyImageSent(testCase, params)
        verifyToolDefinitionSent(testCase, params)
        verifyNamedToolChoiceSent(testCase, params)
        verifyReasoningEffortAndVerbositySent(testCase, params)
        verifyStructuredOutputSent(testCase, params)
        verifyAssistantTextAndToolCallSent(testCase, params, text, toolCallID)
    end

    methods (Test, TestTags = {'Unit'})
        %% Construction
        function customBaseURL(testCase)
            client = testCase.createClient("gpt-4o", BaseURL="https://custom.example.com");
            testCase.verifyEqual(client.BaseURL, "https://custom.example.com/" + testCase.EndpointPath);
        end

        function defaultBaseURL(testCase)
            client = testCase.createClient("gpt-4o");
            testCase.verifyEqual(client.BaseURL, "https://api.openai.com/v1/" + testCase.EndpointPath);
        end

        function baseURL_environmentEndpointSet_usesEnvironmentEndpoint(testCase)
            % OPENAI_API_ENDPOINT supplies the base URL when BaseURL is not given
            import matlab.unittest.fixtures.EnvironmentVariableFixture
            testCase.applyFixture(EnvironmentVariableFixture("OPENAI_API_ENDPOINT", "https://proxy.example.com/v1"));
            client = testCase.createClient("gpt-4o");
            testCase.verifyEqual(client.BaseURL, "https://proxy.example.com/v1/" + testCase.EndpointPath);
        end

        function constructionWithoutAPIKey_succeeds(testCase)
            % Construction without API key defers error to generate time
            import matlab.unittest.fixtures.EnvironmentVariableFixture
            testCase.applyFixture(EnvironmentVariableFixture("OPENAI_API_KEY", ""));
            client = testCase.createClient("gpt-4o");
            testCase.verifyClass(client, testCase.ClientClass);
        end

        function acceptedByAIAgent(testCase)
            client = testCase.createClient("gpt-4o", APIKey="fake-key");
            agent = aisdk.AIAgent(client);
            testCase.verifyClass(agent.Client, testCase.ClientClass);
        end
    end

    methods (Test, TestTags = {'Unit'})
        function openAIProperty_notSet_hasDefaultValue(testCase, OpenAIDefault)
            client = testCase.createClient("gpt-4o");
            testCase.verifyEqual(client.(OpenAIDefault.prop), OpenAIDefault.expected);
        end

        function openAIProperty_setAtConstruction_keepsValue(testCase, OpenAICustom)
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

    methods (Test, TestTags = {'Unit'})
        %% generate — text response
        function generate_textResponse_returnsTextAndMessage(testCase)
            client = testCase.clientWithFakeHTTP(testCase.textResponse("Hello world"));
            [text, messages] = generate(client, "Hi");
            testCase.verifyEqual(text, "Hello world");
            testCase.verifyClass(messages, "aisdk.LLMTextMessage");
            testCase.verifyNumElements(messages, 1);
            testCase.verifyEqual(messages.Text, "Hello world");
            testCase.verifyEqual(messages.Role, "assistant");
        end

        function generate_textResponse_parsesUsageTokens(testCase)
            client = testCase.clientWithFakeHTTP(testCase.textResponse("ok"));
            [~, ~, info] = generate(client, "Hi");
            testCase.verifyEqual(info.Tokens.NumInputTokens, 10);
            testCase.verifyEqual(info.Tokens.NumOutputTokens, 5);
            testCase.verifyEqual(info.Tokens.NumTotalTokens, 15);
            testCase.verifyEqual(info.Tokens.NumCachedInputTokens, 3);
        end

        %% generate — error responses
        function generate_errorResponse_throwsApiReturnedError(testCase)
            client = testCase.clientWithFakeHTTP( ...
                errorResponse(matlab.net.http.StatusCode.BadRequest, "bad input"));
            testCase.verifyError(@() generate(client, "Hi"), "aisdk:apiReturnedError");
        end

        function generate_unauthorizedResponseWithoutAPIKey_throwsMissingAPIKey(testCase)
            import matlab.unittest.fixtures.EnvironmentVariableFixture
            testCase.applyFixture(EnvironmentVariableFixture("OPENAI_API_KEY", ""));
            client = testCase.createClient("gpt-4o");
            unauthorized = errorResponse(matlab.net.http.StatusCode.Unauthorized, "Invalid API key");
            client.sendRequestFcn = @(~,~,~,~,~,~) unauthorized;
            testCase.verifyError(@() client.generate("hello"), "aisdk:client:missingAPIKey");
        end

        function generate_unauthorizedResponseWithAPIKey_throwsApiReturnedError(testCase)
            client = testCase.createClient("gpt-4o", APIKey="wrong-key");
            unauthorized = errorResponse(matlab.net.http.StatusCode.Unauthorized, "Invalid API key");
            client.sendRequestFcn = @(~,~,~,~,~,~) unauthorized;
            testCase.verifyError(@() client.generate("hello"), "aisdk:apiReturnedError");
        end

        %% generate — tool call response
        function generate_toolCallResponse_returnsToolCallMessages(testCase)
            client = testCase.clientWithFakeHTTP(testCase.toolCallResponse( ...
                {toolCallFixture()}, ""));
            [~, messages] = generate(client, "What's the weather?");
            testCase.verifyClass(messages, "aisdk.LLMToolCallMessage");
            testCase.verifyEqual(messages.Name, "getWeather");
            testCase.verifyEqual(messages.Arguments, struct("city", 'London'));
            testCase.verifyEqual(messages.ToolCallID, "call_123");
        end

        function generate_toolCallResponse_multipleToolCalls(testCase)
            client = testCase.clientWithFakeHTTP(testCase.toolCallResponse({ ...
                struct("id", "call_1", "name", "toolA", "arguments", '{"x":1}'), ...
                struct("id", "call_2", "name", "toolB", "arguments", '{"y":2}')}, ""));
            [~, messages] = generate(client, "Call both");
            testCase.verifyNumElements(messages, 2);
            testCase.verifyEqual(messages(1).Name, "toolA");
            testCase.verifyEqual(messages(2).Name, "toolB");
        end

        function generate_toolCallMissingID_returnsEmptyString(testCase)
            client = testCase.clientWithFakeHTTP( ...
                testCase.toolCallWithoutIDResponse("myTool", '{"a":1}'));
            [~, messages] = generate(client, "Call tool");
            testCase.verifyEqual(messages.ToolCallID, "");
        end

        function generate_toolCallArgsNotStruct_errors(testCase)
            client = testCase.clientWithFakeHTTP(testCase.toolCallResponse({ ...
                struct("id", "call_x", "name", "myTool", "arguments", '"just a string"')}, ""));
            testCase.verifyError(@() generate(client, "Call tool"), ...
                "aisdk:invalidToolCallArguments");
        end

        %% generate — tool calls with text
        % The API may return both content (text) and tool calls. We should return text independently of
        % tool calls, including for structured output.
        function generate_toolCallsNoText_returnsEmptyText(testCase)
            client = testCase.clientWithFakeHTTP(testCase.toolCallResponse( ...
                {toolCallFixture()}, ""));
            hClientTestUtils.verifyToolCallsNoText(testCase, client);
        end

        function generate_toolCallsWithText_returnsTextAndToolCalls(testCase)
            client = testCase.clientWithFakeHTTP(testCase.toolCallResponse( ...
                {toolCallFixture()}, "Let me calculate that"));
            [text, messages] = generate(client, "Call a tool");
            testCase.verifyEqual(text, "Let me calculate that");
            toolCalls = messages(arrayfun(@(m) isa(m, "aisdk.LLMToolCallMessage"), messages));
            testCase.assertNumElements(toolCalls, 1);
            testCase.verifyEqual(toolCalls.Name, "getWeather");
        end

        function generate_toolCallsWithText_returnsTextMessageBeforeToolCalls(testCase)
            client = testCase.clientWithFakeHTTP(testCase.toolCallResponse( ...
                {toolCallFixture()}, "Let me calculate that"));
            [~, messages] = generate(client, "Call a tool");
            testCase.assertNumElements(messages, 2, ...
                "Expected one assistant text message and one tool call message.");
            testCase.verifyClass(messages(1), "aisdk.LLMTextMessage");
            testCase.verifyEqual(messages(1).Role, "assistant");
            testCase.verifyEqual(messages(1).Text, "Let me calculate that");
            testCase.verifyClass(messages(2), "aisdk.LLMToolCallMessage");
            testCase.verifyEqual(messages(2).ToolCallID, "call_123");
        end

        function generate_toolCallsWithTextReplayed_sendsAssistantText(testCase)
            toolCall = toolCallFixture();
            text = "Let me calculate that";
            client = testCase.clientWithFakeHTTP(testCase.toolCallResponse({toolCall}, text));
            [~, messages] = generate(client, "Call a tool");
            params = testCase.generateAndCaptureRequest([
                aisdk.LLMTextMessage("Call a tool"), ...
                messages, ...
                aisdk.LLMToolResultMessage("sunny", ToolCallID=toolCall.id, Name=toolCall.name)]);
            testCase.verifyAssistantTextAndToolCallSent(params, text, toolCall.id);
        end

        function generate_toolCallsWithStructuredText_returnsDecodedStruct(testCase)
            client = testCase.clientWithFakeHTTP(testCase.toolCallResponse( ...
                {toolCallFixture()}, '{"name":"Alice","score":9.5}'));
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
            client = testCase.clientWithFakeHTTP(testCase.textResponse('{"result":[]}'));
            proto = struct("plantName", {"appletree","pear"}, "fruit", {"apple","pear"});
            text = generate(client, "What is harvested in August?", ResponseFormat=proto);
            testCase.verifyClass(text, "struct");
            testCase.verifyEmpty(text);
            testCase.verifyThat(fieldnames(text), IsSameSetAs(fieldnames(proto)));
        end

        %% generate — request contents common to both APIs
        function generate_textMessage_producesRoleContent(testCase)
            params = testCase.generateAndCaptureRequest(aisdk.LLMTextMessage("hello"));
            sent = testCase.sentMessages(params);
            testCase.verifyEqual(sent{1}.role, "user");
            testCase.verifyEqual(sent{1}.content, "hello");
        end

        function generate_systemMessage_mapsToDeveloperRole(testCase)
            params = testCase.generateAndCaptureRequest([
                aisdk.LLMTextMessage("Be concise.", Role="system"), ...
                aisdk.LLMTextMessage("hello")]);
            sent = testCase.sentMessages(params);
            testCase.verifyEqual(sent{1}.role, "developer");
            testCase.verifyEqual(sent{1}.content, "Be concise.");
            testCase.verifyEqual(sent{2}.role, "user");
        end

        %% generate — request contents in each API's wire format
        function generate_toolCallAndResultInHistory_sendsThemInWireFormat(testCase)
            params = testCase.generateAndCaptureRequest([
                aisdk.LLMTextMessage("hi"), ...
                aisdk.LLMToolCallMessage("myTool", struct("a",1), ToolCallID="call_1"), ...
                aisdk.LLMToolResultMessage("result text", ToolCallID="call_1", Name="myTool")]);
            testCase.verifyToolCallAndResultSent(params);
        end

        function generate_twoToolCallsInHistory_sendsThemInWireFormat(testCase)
            params = testCase.generateAndCaptureRequest([
                aisdk.LLMTextMessage("hi"), ...
                aisdk.LLMToolCallMessage("toolA", struct("x",1), ToolCallID="call_1"), ...
                aisdk.LLMToolCallMessage("toolB", struct("y",2), ToolCallID="call_2")]);
            testCase.verifyTwoToolCallsSent(params);
        end

        function generate_toolCallWithoutIDInHistory_sendsEmptyID(testCase)
            params = testCase.generateAndCaptureRequest([
                aisdk.LLMTextMessage("hi"), ...
                aisdk.LLMToolCallMessage("myTool", struct("a",1))]);
            testCase.verifyToolCallWithoutIDSentWithEmptyID(params);
        end

        function generate_imageMessage_sendsImageInWireFormat(testCase)
            params = testCase.generateAndCaptureRequest( ...
                aisdk.LLMImageMessage(uint8(zeros(2, 2, 3)), Detail="low"));
            testCase.verifyImageSent(params);
        end

        function generate_withTool_sendsToolDefinitionInWireFormat(testCase)
            params = testCase.generateAndCaptureRequest(aisdk.LLMTextMessage("hi"), Tools=toolFixture());
            testCase.verifyToolDefinitionSent(params);
        end

        function generate_namedToolChoice_sendsToolChoiceInWireFormat(testCase)
            params = testCase.generateAndCaptureRequest(aisdk.LLMTextMessage("hi"), ...
                Tools=toolFixture(), ToolChoice="myTool");
            testCase.verifyNamedToolChoiceSent(params);
        end

        function generate_reasoningEffortAndVerbosity_sendsThemInWireFormat(testCase)
            params = testCase.generateAndCaptureRequest(aisdk.LLMTextMessage("hi"), ...
                ReasoningEffort="high", Verbosity="low");
            testCase.verifyReasoningEffortAndVerbositySent(params);
        end

        function generate_structuredOutput_sendsSchemaInWireFormat(testCase)
            params = testCase.generateAndCaptureRequestWithReply( ...
                '{"name":"Alice","score":9.5}', aisdk.LLMTextMessage("hi"), ...
                ResponseFormat=struct("name", "", "score", 0.0));
            testCase.verifyStructuredOutputSent(params);
        end

        function generate_maxNumTokens_sendsLimitInWireFormat(testCase)
            params = testCase.generateAndCaptureRequest(aisdk.LLMTextMessage("hi"), MaxNumTokens=100);
            testCase.verifyEqual(params.(testCase.MaxNumTokensField), 100);
        end

        %% generate — connection problems
        function generate_httpsProxyIsHonored(testCase)
            import matlab.unittest.fixtures.EnvironmentVariableFixture
            testCase.applyFixture(EnvironmentVariableFixture("HTTPS_PROXY", "http://nosuchhost.example.com:1234"));
            client = testCase.createClient("gpt-4o", APIKey="fake-key");
            testCase.verifyError(@() generate(client, "Hello"), ...
                "MATLAB:webservices:UnknownHost");
        end

        function generate_connectionError_isReportedFromGenerate(testCase)
            % A connection problem is reported from generate, so the user
            % sees the call they made rather than either the caller of
            % generate or the web services internals.
            import matlab.unittest.fixtures.EnvironmentVariableFixture
            testCase.applyFixture(EnvironmentVariableFixture("HTTPS_PROXY", "http://nosuchhost.example.com:1234"));
            client = testCase.createClient("gpt-4o", APIKey="fake-key");
            err = MException.empty;
            try
                generate(client, "Hello");
            catch err
            end
            testCase.assertNotEmpty(err, "Expected a connection error.");
            testCase.verifyEqual(string(err.stack(1).name), ...
                extractAfter(testCase.ClientClass, "aisdk.client.") + ".generate");
            testCase.verifyEmpty(err.cause, ...
                "The web services cause chain should not be forwarded.");
        end
    end

    methods (Access=protected)
        function client = clientWithFakeHTTP(testCase, mockResponse)
            client = testCase.createClient("gpt-4o", APIKey="fake-key");
            client.sendRequestFcn = @(~,~,~,~,~,~) mockResponse;
        end

        function params = generateAndCaptureRequest(testCase, messages, varargin)
            params = testCase.generateAndCaptureRequestWithReply("fake", messages, varargin{:});
        end

        function params = generateAndCaptureRequestWithReply(testCase, replyText, messages, varargin)
            captured = {};
            client = testCase.createClient("gpt-4o", APIKey="fake-key");
            client.sendRequestFcn = @fakeSendRequest;
            generate(client, messages, varargin{:});
            params = captured{1};

            function response = fakeSendRequest(parameters, ~, ~, ~, ~, ~)
                captured{1} = parameters;
                response = testCase.textResponse(replyText);
            end
        end
    end

end

function response = errorResponse(statusCode, errorText)
    response = struct("StatusCode", statusCode, ...
        "Body", struct("Data", struct("error", struct("message", errorText))));
end

function tc = toolCallFixture()
    tc = struct("id", "call_123", "name", "getWeather", "arguments", '{"city":"London"}');
end

function tool = toolFixture()
    tool = aisdk.LLMTool(@(x) x, Name="myTool", Description="A tool", ...
        InputArguments=aisdk.LLMToolArgument("x", DataType="number"), ...
        OutputArguments=aisdk.LLMToolArgument("result"));
end
