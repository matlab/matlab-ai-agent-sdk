classdef tCallOllamaChatAPI < matlab.unittest.TestCase
%tCallOllamaChatAPI Tests for parameter building in callOllamaChatAPI.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        function buildParams_modelAndMessages_set(testCase)
            params = captureParams();
            testCase.verifyEqual(params.model, "qwen3:0.6b");
            testCase.verifyEqual(params.messages{1}.role, "user");
        end

        function buildParams_optionsContainsTemperature(testCase)
            params = captureParams(Temperature=0.7);
            testCase.verifyEqual(params.options.temperature, 0.7);
        end

        function buildParams_scalarStop_encodesAsArray(testCase)
            % Verify cell-wrapping produces a JSON array — no live test covers this path
            params = captureParams(StopSequences="end");
            encoded = jsonencode(params.options.stop);
            testCase.verifyEqual(encoded, '["end"]');
        end

        function buildParams_responseFormatJson_setsFormat(testCase)
            params = captureParams(ResponseFormat="json");
            testCase.verifyEqual(params.format, "json");
        end

        function buildParams_responseFormatStruct_setsSchema(testCase)
            proto = struct("name", "", "score", 0.0);
            params = captureParams(ResponseFormat=proto);
            testCase.verifyTrue(isstruct(params.format));
        end

        function buildParams_toolsAdded_whenNonEmpty(testCase)
            tools = {struct("type","function","function",struct("name","myTool","parameters",struct()))};
            params = captureParams(Tools=tools);
            testCase.verifyTrue(isfield(params, "tools"));
        end

        function buildParams_infValues_omitted(testCase)
            params = captureParams(TopK=Inf);
            testCase.verifyFalse(isfield(params.options, "top_k"));
        end
    end

end

function params = captureParams(nvp)
    arguments
        nvp.Temperature       = "auto"
        nvp.StopSequences     = strings(1,0)
        nvp.ResponseFormat    = "text"
        nvp.Tools             = []
        nvp.TopK              = "auto"
    end
    captured = {};
    messages = {struct("role", "user", "content", "Hello")};
    aisdk.llms.client.internal.callOllamaChatAPI("qwen3:0.6b", messages, nvp.Tools, ...
        ToolChoice=[], Temperature=nvp.Temperature, TopP="auto", ...
        MinP="auto", TopK=nvp.TopK, TailFreeSamplingZ="auto", ...
        StopSequences=nvp.StopSequences, MaxNumTokens=inf, ...
        ResponseFormat=nvp.ResponseFormat, Seed=[], ...
        TimeOut=10, StreamFcn=[], ...
        Endpoint="http://fake:11434/api/chat", sendRequestFcn=@fakeSendRequest);

    params = captured{1};

    function [response, streamedText] = fakeSendRequest(parameters, ~, ~, ~, ~)
        captured{1} = parameters;
        responseData = struct("message", struct("role", "assistant", "content", "fake"));
        response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
        streamedText = "";
    end
end
