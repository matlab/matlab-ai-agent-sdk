classdef tmustBeValidTailFreeSamplingZ < matlab.unittest.TestCase
% Tests for aisdk.llms.internal.mustBeValidTailFreeSamplingZ.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        validInput = struct( ...
            'autoString', {"auto"}, ...
            'autoChar', {'auto'}, ...
            'negativeValue', {-5}, ...
            'positiveValue', {100})
    end

    methods (Test)
        function acceptsValidInput(testCase, validInput)
            testCase.verifyWarningFree( ...
                @() aisdk.llms.internal.mustBeValidTailFreeSamplingZ(validInput));
        end

        function rejectsNonScalar(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidTailFreeSamplingZ([1 2]), ...
                "MATLAB:expectedScalar");
        end

        function rejectsComplex(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidTailFreeSamplingZ(1+2i), ...
                "MATLAB:expectedReal");
        end

        function rejectsSparse(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidTailFreeSamplingZ(sparse(5)), ...
                "MATLAB:expectedNonsparse");
        end
    end
end
