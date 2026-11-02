classdef tCallChatCompletionsAPI < matlab.unittest.TestCase
%tCallChatCompletionsAPI Tests for parameter building in callChatCompletionsAPI.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function toolCallWithoutContent_returnsEmptyTextAndToolCalls(testCase)
            toolCall = struct("id", "call_1", "type", "function", ...
                "function", struct("name", "lookup", "arguments", "{}"));
            apiMessage = struct("role", "assistant", "tool_calls", {{toolCall}});
            [~, text, message] = callAPIAndCaptureRequest(APIMessage=apiMessage);
            testCase.verifyEqual(text, "");
            testCase.verifyFalse(isfield(message, "content"));
            testCase.verifyEqual(message.tool_calls{1}.id, "call_1");
        end

        function nonStreamingToolCalls_areNormalizedToColumnCell(testCase)
            toolCalls = struct( ...
                "id", {"call_1", "call_2"}, ...
                "type", {"function", "function"}, ...
                "function", { ...
                    struct("name", "first", "arguments", "{}"), ...
                    struct("name", "second", "arguments", "{}")});
            apiMessage = struct( ...
                "role", "assistant", ...
                "content", "", ...
                "tool_calls", toolCalls);

            [~, ~, message] = callAPIAndCaptureRequest(APIMessage=apiMessage);

            testCase.verifyClass(message.tool_calls, "cell");
            testCase.verifySize(message.tool_calls, [2 1]);
            testCase.verifyEqual(message.tool_calls{2}.id, "call_2");
        end
        %% Basic parameter structure
        function buildParams_includesModelAndMessages(testCase)
            params = callAPIAndCaptureRequest();
            testCase.verifyEqual(params.model, "gpt-4o");
            testCase.verifyEqual(params.messages{1}.role, "user");
        end

        function buildParams_streamTrue_whenStreamFcnSet(testCase)
            params = callAPIAndCaptureRequest(StreamFcn=@(x) disp(x));
            testCase.verifyTrue(params.stream);
        end

        function buildParams_streamFalse_whenNoStreamFcn(testCase)
            params = callAPIAndCaptureRequest();
            testCase.verifyFalse(params.stream);
        end

        function request_usesChatCompletionsStreamerFactory(testCase)
            [~, ~, ~, streamerFactory] = callAPIAndCaptureRequest();
            testCase.verifyEqual( ...
                streamerFactory, ...
                @aisdk.client.internal.ChatCompletionsResponseStreamer);
        end

        function request_withStreamFcn_acceptsEventStream(testCase)
            captured = {};
            messages = {struct("role", "user", "content", "Hello")};

            aisdk.client.internal.callChatCompletionsAPI(messages, [], ...
                ModelName="gpt-4o", ToolChoice=[], ...
                Temperature="auto", TopP="auto", ...
                StopSequences=strings(1,0), MaxNumTokens=inf, ...
                PresencePenalty="auto", FrequencyPenalty="auto", ...
                NumCompletions=1, Seed=[], ResponseFormat="text", ...
                ReasoningEffort="auto", Verbosity="auto", ...
                APIKey="fake-key", TimeOut=10, StreamFcn=@(~) [], ...
                sendRequestFcn=@(varargin) aisdk.client.internal.sendRequest( ...
                    varargin{:}, @fakeSend), ...
                Endpoint="https://example.invalid/v1");

            request = captured{1};
            accept = request.Header([request.Header.Name] == "Accept");
            testCase.assertNumElements(accept, 1);
            testCase.verifyEqual(accept.Value, "text/event-stream");

            function response = fakeSend(request, ~, ~, ~)
                captured{1} = request;
                response = struct("StatusCode", "OK", "Body", struct("Data", ""));
            end
        end

        function buildParams_toolsAdded_whenNonEmpty(testCase)
            tools = {struct("type","function","function",struct("name","myTool","parameters",struct()))};
            params = callAPIAndCaptureRequest(Tools=tools);
            testCase.verifyTrue(isfield(params, "tools"));
            testCase.verifyEqual(params.tools{1}.("function").name, "myTool");
        end

        function buildParams_toolChoiceAdded_whenNonEmpty(testCase)
            params = callAPIAndCaptureRequest(ToolChoice="required");
            testCase.verifyEqual(params.tool_choice, "required");
        end

        function buildParams_seedAdded_whenNonEmpty(testCase)
            params = callAPIAndCaptureRequest(Seed=42);
            testCase.verifyEqual(params.seed, 42);
        end

        function buildParams_maxTokensOmitted_whenInf(testCase)
            params = callAPIAndCaptureRequest(MaxNumTokens=inf);
            testCase.verifyFalse(isfield(params, "max_completion_tokens"));
        end

        function buildParams_maxTokensIncluded_whenFinite(testCase)
            params = callAPIAndCaptureRequest(MaxNumTokens=100);
            testCase.verifyEqual(params.max_completion_tokens, 100);
        end

        %% ReasoningEffort and Verbosity
        function buildParams_autoReasoningEffort_omitted(testCase)
            params = callAPIAndCaptureRequest(ReasoningEffort="auto");
            testCase.verifyFalse(isfield(params, "reasoning_effort"));
        end

        function buildParams_autoVerbosity_omitted(testCase)
            params = callAPIAndCaptureRequest(Verbosity="auto");
            testCase.verifyFalse(isfield(params, "verbosity"));
        end

        function buildParams_reasoningEffort_serialized(testCase)
            params = callAPIAndCaptureRequest(ReasoningEffort="high");
            testCase.verifyEqual(params.reasoning_effort, "high");
        end

        function buildParams_verbosity_serialized(testCase)
            params = callAPIAndCaptureRequest(Verbosity="low");
            testCase.verifyEqual(params.verbosity, "low");
        end

        %% ResponseFormat
        function buildParams_responseFormatJson_setsJsonObject(testCase)
            params = callAPIAndCaptureRequest(ResponseFormat="json");
            testCase.verifyEqual(params.response_format.type, 'json_object');
        end

        function buildParams_responseFormatStruct_setsJsonSchema(testCase)
            proto = struct("name", "", "score", 0.0);
            params = callAPIAndCaptureRequest(ResponseFormat=proto);
            testCase.verifyEqual(params.response_format.type, 'json_schema');
            testCase.verifyEqual(params.response_format.json_schema.strict, true);
        end

        function buildParams_responseFormatText_omitsField(testCase)
            params = callAPIAndCaptureRequest(ResponseFormat="text");
            testCase.verifyFalse(isfield(params, "response_format"));
        end

        function buildParams_responseFormatJsonSchema_usesVerbatimJSON(testCase)
            rawSchema = '{"type":"object","properties":{"x":{"type":"number"}},"required":["x"],"additionalProperties":false}';
            params = callAPIAndCaptureRequest(ResponseFormat=rawSchema);
            testCase.verifyEqual(params.response_format.type, 'json_schema');
            testCase.verifyEqual(params.response_format.json_schema.name, 'providedInCall');
            encoded = jsonencode(params.response_format.json_schema.schema);
            testCase.verifyEqual(encoded, string(rawSchema));
        end
    end

end

function [params, text, message, streamerFactory] = callAPIAndCaptureRequest(nvp)
    arguments
        nvp.ReasoningEffort (1,1) string = "auto"
        nvp.Verbosity       (1,1) string = "auto"
        nvp.ResponseFormat               = "text"
        nvp.StreamFcn                    = []
        nvp.Tools                        = []
        nvp.ToolChoice                   = []
        nvp.Seed                         = []
        nvp.MaxNumTokens    (1,1)        = inf
        nvp.APIMessage                   = struct("role", "assistant", "content", "fake")
    end
    captured = {};
    messages = {struct("role", "user", "content", "Hello")};
    [text, message] = aisdk.client.internal.callChatCompletionsAPI(messages, nvp.Tools, ...
        ModelName="gpt-4o", ToolChoice=nvp.ToolChoice, ...
        Temperature="auto", TopP="auto", ...
        StopSequences=strings(1,0), MaxNumTokens=nvp.MaxNumTokens, ...
        PresencePenalty="auto", FrequencyPenalty="auto", ...
        NumCompletions=1, Seed=nvp.Seed, ResponseFormat=nvp.ResponseFormat, ...
        ReasoningEffort=nvp.ReasoningEffort, Verbosity=nvp.Verbosity, ...
        APIKey="fake-key", TimeOut=10, StreamFcn=nvp.StreamFcn, ...
        sendRequestFcn=@fakeSendRequest, Endpoint="https://fake");

    params = captured{1};

    function response = fakeSendRequest(parameters, ~, ~, ~, ~, factory)
        captured{1} = parameters;
        streamerFactory = factory;
        responseData = struct( ...
            "choices", struct( ...
                "message", nvp.APIMessage), ...
            "usage", struct( ...
                "prompt_tokens", 0, "completion_tokens", 0, "total_tokens", 0));
        response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
    end
end
