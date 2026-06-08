classdef tmustBeReasoningEffort < matlab.unittest.TestCase
% Tests for aisdk.llms.internal.mustBeReasoningEffort.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        validValue = {"auto", "none", "minimal", "low", "medium", "high", "xhigh"}
    end

    methods (Test)
        function acceptsValidValue(testCase, validValue)
            testCase.verifyWarningFree( ...
                @() aisdk.llms.internal.mustBeReasoningEffort(validValue));
        end

        function acceptsCharValue(testCase)
            testCase.verifyWarningFree( ...
                @() aisdk.llms.internal.mustBeReasoningEffort('medium'));
        end

        function rejectsInvalidString(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeReasoningEffort("invalid"), ...
                "MATLAB:validators:mustBeMember");
        end

        function rejectsNumericInput(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeReasoningEffort(1), ...
                "MATLAB:validators:mustBeMember");
        end
    end
end
