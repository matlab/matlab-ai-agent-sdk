classdef tCallOpenAIChatAPI < matlab.unittest.TestCase
%tCallOpenAIChatAPI Tests for parameter building in callOpenAIChatAPI.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        %% Basic parameter structure
        function buildParams_includesModelAndMessages(testCase)
            params = captureParams();
            testCase.verifyEqual(params.model, "gpt-4o");
            testCase.verifyEqual(params.messages{1}.role, "user");
        end

        function buildParams_streamTrue_whenStreamFcnSet(testCase)
            params = captureParams(StreamFcn=@(x) disp(x));
            testCase.verifyTrue(params.stream);
        end

        function buildParams_streamFalse_whenNoStreamFcn(testCase)
            params = captureParams();
            testCase.verifyFalse(params.stream);
        end

        function buildParams_toolsAdded_whenNonEmpty(testCase)
            tools = {struct("type","function","function",struct("name","myTool","parameters",struct()))};
            params = captureParams(Tools=tools);
            testCase.verifyTrue(isfield(params, "tools"));
            testCase.verifyEqual(params.tools{1}.("function").name, "myTool");
        end

        function buildParams_toolChoiceAdded_whenNonEmpty(testCase)
            params = captureParams(ToolChoice="required");
            testCase.verifyEqual(params.tool_choice, "required");
        end

        function buildParams_seedAdded_whenNonEmpty(testCase)
            params = captureParams(Seed=42);
            testCase.verifyEqual(params.seed, 42);
        end

        function buildParams_maxTokensOmitted_whenInf(testCase)
            params = captureParams(MaxNumTokens=inf);
            testCase.verifyFalse(isfield(params, "max_completion_tokens"));
        end

        function buildParams_maxTokensIncluded_whenFinite(testCase)
            params = captureParams(MaxNumTokens=100);
            testCase.verifyEqual(params.max_completion_tokens, 100);
        end

        %% ReasoningEffort and Verbosity
        function buildParams_autoReasoningEffort_omitted(testCase)
            params = captureParams(ReasoningEffort="auto");
            testCase.verifyFalse(isfield(params, "reasoning_effort"));
        end

        function buildParams_autoVerbosity_omitted(testCase)
            params = captureParams(Verbosity="auto");
            testCase.verifyFalse(isfield(params, "verbosity"));
        end

        function buildParams_reasoningEffort_serialized(testCase)
            params = captureParams(ReasoningEffort="high");
            testCase.verifyEqual(params.reasoning_effort, "high");
        end

        function buildParams_verbosity_serialized(testCase)
            params = captureParams(Verbosity="low");
            testCase.verifyEqual(params.verbosity, "low");
        end

        %% ResponseFormat
        function buildParams_responseFormatJson_setsJsonObject(testCase)
            params = captureParams(ResponseFormat="json");
            testCase.verifyEqual(params.response_format.type, 'json_object');
        end

        function buildParams_responseFormatStruct_setsJsonSchema(testCase)
            proto = struct("name", "", "score", 0.0);
            params = captureParams(ResponseFormat=proto);
            testCase.verifyEqual(params.response_format.type, 'json_schema');
            testCase.verifyEqual(params.response_format.json_schema.strict, true);
        end

        function buildParams_responseFormatText_omitsField(testCase)
            params = captureParams(ResponseFormat="text");
            testCase.verifyFalse(isfield(params, "response_format"));
        end

        function buildParams_responseFormatJsonSchema_usesVerbatimJSON(testCase)
            rawSchema = '{"type":"object","properties":{"x":{"type":"number"}},"required":["x"],"additionalProperties":false}';
            params = captureParams(ResponseFormat=rawSchema);
            testCase.verifyEqual(params.response_format.type, 'json_schema');
            testCase.verifyEqual(params.response_format.json_schema.name, 'providedInCall');
            encoded = jsonencode(params.response_format.json_schema.schema);
            testCase.verifyEqual(encoded, string(rawSchema));
        end
    end

end

function params = captureParams(nvp)
    arguments
        nvp.ReasoningEffort (1,1) string = "auto"
        nvp.Verbosity       (1,1) string = "auto"
        nvp.ResponseFormat               = "text"
        nvp.StreamFcn                    = []
        nvp.Tools                        = []
        nvp.ToolChoice                   = []
        nvp.Seed                         = []
        nvp.MaxNumTokens    (1,1)        = inf
    end
    captured = {};
    messages = {struct("role", "user", "content", "Hello")};
    aisdk.llms.client.internal.callOpenAIChatAPI(messages, nvp.Tools, ...
        ModelName="gpt-4o", ToolChoice=nvp.ToolChoice, ...
        Temperature="auto", TopP="auto", ...
        StopSequences=strings(1,0), MaxNumTokens=nvp.MaxNumTokens, ...
        PresencePenalty="auto", FrequencyPenalty="auto", ...
        NumCompletions=1, Seed=nvp.Seed, ResponseFormat=nvp.ResponseFormat, ...
        ReasoningEffort=nvp.ReasoningEffort, Verbosity=nvp.Verbosity, ...
        APIKey="fake-key", TimeOut=10, StreamFcn=nvp.StreamFcn, ...
        sendRequestFcn=@fakeSendRequest, Endpoint="https://fake");

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
