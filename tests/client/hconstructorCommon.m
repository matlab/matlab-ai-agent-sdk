classdef (Abstract) hconstructorCommon < matlab.mock.TestCase
% Common constructor tests for LLM client classes.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        DefaultProperty = struct( ...
            "Temperature",    struct("prop", "Temperature",    "expected", "auto"), ...
            "TopP",           struct("prop", "TopP",           "expected", "auto"), ...
            "MaxNumTokens",   struct("prop", "MaxNumTokens",   "expected", inf), ...
            "ResponseFormat", struct("prop", "ResponseFormat", "expected", "text"), ...
            "TimeOut",        struct("prop", "TimeOut",        "expected", 120), ...
            "StreamFcn",      struct("prop", "StreamFcn",      "expected", []));

        NonDefaultProperty = struct( ...
            "Temperature",    struct("prop", "Temperature",    "value", 0.5), ...
            "TopP",           struct("prop", "TopP",           "value", 0.9), ...
            "MaxNumTokens",   struct("prop", "MaxNumTokens",   "value", 200), ...
            "ResponseFormat", struct("prop", "ResponseFormat", "value", "json"), ...
            "TimeOut",        struct("prop", "TimeOut",        "value", 30));

        InvalidProperty = struct( ...
            "MaxNumTokensNonInteger", struct("prop", "MaxNumTokens", "value", 10.5, "errID", "MATLAB:validators:mustBeInteger"), ...
            "MaxNumTokensZero",       struct("prop", "MaxNumTokens", "value", 0,    "errID", "MATLAB:validators:mustBePositive"), ...
            "TimeOutZero",            struct("prop", "TimeOut",      "value", 0,    "errID", "MATLAB:validators:mustBePositive"));
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

    methods (Test, TestTags = {'Unit'})
        function sharedProperty_notSet_hasDefaultValue(testCase, DefaultProperty)
            client = testCase.createClient("test-model");
            testCase.verifyEqual(client.(DefaultProperty.prop), DefaultProperty.expected);
        end

        function sharedProperty_setAtConstruction_keepsValue(testCase, NonDefaultProperty)
            client = testCase.createClient("test-model", NonDefaultProperty.prop, NonDefaultProperty.value);
            testCase.verifyEqual(client.(NonDefaultProperty.prop), NonDefaultProperty.value);
        end

        function sharedProperty_invalidAtConstruction_errors(testCase, InvalidProperty)
            testCase.verifyError( ...
                @() testCase.createClient("test-model", InvalidProperty.prop, InvalidProperty.value), ...
                InvalidProperty.errID);
        end
    end

end
