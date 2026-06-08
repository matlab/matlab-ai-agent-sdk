classdef tmustBeVerbosity < matlab.unittest.TestCase
% Tests for aisdk.llms.internal.mustBeVerbosity.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        validValue = {"auto", "low", "medium", "high"}
    end

    methods (Test)
        function acceptsValidValue(testCase, validValue)
            testCase.verifyWarningFree( ...
                @() aisdk.llms.internal.mustBeVerbosity(validValue));
        end

        function acceptsCharValue(testCase)
            testCase.verifyWarningFree( ...
                @() aisdk.llms.internal.mustBeVerbosity('low'));
        end

        function rejectsInvalidString(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeVerbosity("invalid"), ...
                "MATLAB:validators:mustBeMember");
        end

        function rejectsNumericInput(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeVerbosity(1), ...
                "MATLAB:validators:mustBeMember");
        end
    end
end
