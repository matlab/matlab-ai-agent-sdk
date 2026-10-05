classdef (Abstract) hconstructorCommon < matlab.mock.TestCase
% Common constructor tests for LLM client classes.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        DefaultProperty = struct( ...
            "Temperature",    struct("prop", "Temperature",    "expected", "auto"), ...
            "TopP",           struct("prop", "TopP",           "expected", "auto"), ...
            "StopSequences",  struct("prop", "StopSequences",  "expected", []), ...
            "MaxNumTokens",   struct("prop", "MaxNumTokens",   "expected", inf), ...
            "ResponseFormat", struct("prop", "ResponseFormat", "expected", "text"), ...
            "TimeOut",        struct("prop", "TimeOut",        "expected", 120), ...
            "StreamFcn",      struct("prop", "StreamFcn",      "expected", []));

        CustomProperty = struct( ...
            "Temperature",    struct("prop", "Temperature",    "value", 0.5), ...
            "TopP",           struct("prop", "TopP",           "value", 0.9), ...
            "StopSequences",  struct("prop", "StopSequences",  "value", ["stop1","stop2"]), ...
            "MaxNumTokens",   struct("prop", "MaxNumTokens",   "value", 200), ...
            "ResponseFormat", struct("prop", "ResponseFormat", "value", "json"), ...
            "TimeOut",        struct("prop", "TimeOut",        "value", 30));
    end

    methods (Abstract)
        client = createClient(testCase, modelName, nvp)
    end

    methods (Test, TestTags = {'Unit'})
        function setsModelName(testCase)
            client = testCase.createClient("test-model");
            testCase.verifyEqual(client.ModelName, "test-model");
        end

        function errorWhenModelNameOmitted(testCase)
            testCase.verifyError(@() testCase.createClient(), "MATLAB:minrhs");
        end

        function customStreamFcn(testCase)
            f = @(x) disp(x);
            client = testCase.createClient("test-model", StreamFcn=f);
            testCase.verifyEqual(client.StreamFcn, f);
        end
    end

    methods (Test, TestTags = {'Unit'}, ParameterCombination="sequential")
        function hasCorrectDefault(testCase, DefaultProperty)
            client = testCase.createClient("test-model");
            testCase.verifyEqual(client.(DefaultProperty.prop), DefaultProperty.expected);
        end

        function respectsCustomValue(testCase, CustomProperty)
            client = testCase.createClient("test-model", CustomProperty.prop, CustomProperty.value);
            testCase.verifyEqual(client.(CustomProperty.prop), CustomProperty.value);
        end
    end

end
