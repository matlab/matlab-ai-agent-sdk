classdef tmustBeValidTemperature < matlab.unittest.TestCase
% Tests for aisdk.llms.internal.mustBeValidTemperature.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        validInput = struct( ...
            'autoString', {"auto"}, ...
            'autoChar', {'auto'}, ...
            'zero', {0}, ...
            'upperBound', {2})
    end

    methods (Test)
        function acceptsValidInput(testCase, validInput)
            testCase.verifyWarningFree( ...
                @() aisdk.llms.internal.mustBeValidTemperature(validInput));
        end

        function rejectsNegative(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidTemperature(-0.1), ...
                "MATLAB:expectedNonnegative");
        end

        function rejectsAboveUpperBound(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidTemperature(2.1), ...
                "MATLAB:notLessEqual");
        end

        function rejectsNonScalar(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidTemperature([0 1]), ...
                "MATLAB:expectedScalar");
        end

        function rejectsSparse(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidTemperature(sparse(1)), ...
                "MATLAB:expectedNonsparse");
        end

        function rejectsComplex(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidTemperature(1+0.5i), ...
                "MATLAB:expectedReal");
        end
    end
end
