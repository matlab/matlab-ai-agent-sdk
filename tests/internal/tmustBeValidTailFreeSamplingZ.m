classdef tmustBeValidTailFreeSamplingZ < matlab.unittest.TestCase
% Tests for aisdk.internal.mustBeValidTailFreeSamplingZ.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        validInput = struct( ...
            'autoString', {"auto"}, ...
            'autoChar', {'auto'}, ...
            'negativeValue', {-5}, ...
            'positiveValue', {100})
    end

    methods (Test, TestTags = {'Unit'})
        function acceptsValidInput(testCase, validInput)
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeValidTailFreeSamplingZ(validInput));
        end

        function rejectsNonScalar(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeValidTailFreeSamplingZ([1 2]), ...
                "MATLAB:expectedScalar");
        end

        function rejectsComplex(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeValidTailFreeSamplingZ(1+2i), ...
                "MATLAB:expectedReal");
        end

        function rejectsSparse(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeValidTailFreeSamplingZ(sparse(5)), ...
                "MATLAB:expectedNonsparse");
        end
    end
end
