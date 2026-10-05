classdef tmustBeToolArguments < matlab.unittest.TestCase
% Tests for aisdk.internal.mustBeToolArguments.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function acceptsStruct(testCase)
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeToolArguments(struct("a", 1)));
        end

        function acceptsEmptyStruct(testCase)
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeToolArguments(struct()));
        end

        function acceptsLLMToolArgument(testCase)
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeToolArguments( ...
                    aisdk.LLMToolArgument("x", DataType="number")));
        end

        function acceptsLLMToolArgumentArray(testCase)
            args = [aisdk.LLMToolArgument("x", DataType="number"), ...
                    aisdk.LLMToolArgument("y", DataType="number")];
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeToolArguments(args));
        end

        function rejectsNumeric(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeToolArguments(42), ...
                "aisdk:invalidToolArguments");
        end

        function rejectsCellArray(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeToolArguments({1, 2}), ...
                "aisdk:invalidToolArguments");
        end

        function rejectsString(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeToolArguments("hello"), ...
                "aisdk:invalidToolArguments");
        end

        function rejectsStructArray(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeToolArguments( ...
                    [struct("a", 1), struct("a", 2)]), ...
                "aisdk:invalidToolArguments");
        end
    end
end
