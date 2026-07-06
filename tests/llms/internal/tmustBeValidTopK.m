classdef tmustBeValidTopK < matlab.unittest.TestCase
% Tests for aisdk.llms.internal.mustBeValidTopK.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        validInput = struct( ...
            'autoString', {"auto"}, ...
            'autoChar', {'auto'}, ...
            'positiveInteger', {10}, ...
            'positiveFraction', {0.5})
    end

    methods (Test, TestTags = {'Unit'})
        function acceptsValidInput(testCase, validInput)
            testCase.verifyWarningFree( ...
                @() aisdk.llms.internal.mustBeValidTopK(validInput));
        end

        function rejectsZero(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidTopK(0), ...
                "MATLAB:expectedPositive");
        end

        function rejectsNegative(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidTopK(-1), ...
                "MATLAB:expectedPositive");
        end

        function rejectsSparse(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidTopK(sparse(5)), ...
                "MATLAB:expectedNonsparse");
        end
    end
end
