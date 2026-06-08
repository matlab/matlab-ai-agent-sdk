classdef tmustBeValidProbability < matlab.unittest.TestCase
% Tests for aisdk.llms.internal.mustBeValidProbability.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        validInput = struct( ...
            'autoString', {"auto"}, ...
            'autoChar', {'auto'}, ...
            'zero', {0}, ...
            'one', {1})
    end

    methods (Test)
        function acceptsValidInput(testCase, validInput)
            testCase.verifyWarningFree( ...
                @() aisdk.llms.internal.mustBeValidProbability(validInput));
        end

        function rejectsNegative(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidProbability(-0.1), ...
                "MATLAB:expectedNonnegative");
        end

        function rejectsAboveOne(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidProbability(1.1), ...
                "MATLAB:notLessEqual");
        end

        function rejectsNonScalar(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidProbability([0 0.5]), ...
                "MATLAB:expectedScalar");
        end

        function rejectsSparse(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidProbability(sparse(0.5)), ...
                "MATLAB:expectedNonsparse");
        end

        function rejectsComplex(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidProbability(0.5+0.1i), ...
                "MATLAB:expectedReal");
        end
    end
end
