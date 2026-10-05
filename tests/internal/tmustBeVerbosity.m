classdef tmustBeVerbosity < matlab.unittest.TestCase
% Tests for aisdk.internal.mustBeVerbosity.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        validValue = {"auto", "low", "medium", "high"}
    end

    methods (Test, TestTags = {'Unit'})
        function acceptsValidValue(testCase, validValue)
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeVerbosity(validValue));
        end

        function acceptsCharValue(testCase)
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeVerbosity('low'));
        end

        function rejectsInvalidString(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeVerbosity("invalid"), ...
                "MATLAB:validators:mustBeMember");
        end

        function rejectsNumericInput(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeVerbosity(1), ...
                "MATLAB:validators:mustBeMember");
        end
    end
end
