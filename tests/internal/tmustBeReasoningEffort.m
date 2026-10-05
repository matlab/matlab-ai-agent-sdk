classdef tmustBeReasoningEffort < matlab.unittest.TestCase
% Tests for aisdk.internal.mustBeReasoningEffort.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        validValue = {"auto", "none", "minimal", "low", "medium", "high", "xhigh"}
    end

    methods (Test, TestTags = {'Unit'})
        function acceptsValidValue(testCase, validValue)
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeReasoningEffort(validValue));
        end

        function acceptsCharValue(testCase)
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeReasoningEffort('medium'));
        end

        function rejectsInvalidString(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeReasoningEffort("invalid"), ...
                "MATLAB:validators:mustBeMember");
        end

        function rejectsNumericInput(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeReasoningEffort(1), ...
                "MATLAB:validators:mustBeMember");
        end
    end
end
