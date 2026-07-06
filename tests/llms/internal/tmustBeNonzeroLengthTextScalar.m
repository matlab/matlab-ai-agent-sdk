classdef tmustBeNonzeroLengthTextScalar < matlab.unittest.TestCase
% Tests for aisdk.llms.internal.mustBeNonzeroLengthTextScalar.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        validInput = struct( ...
            'scalarString', {"hello"}, ...
            'charVector', {'hello'}, ...
            'scalarCellstr', {{'hello'}})
        nonScalarInput = struct( ...
            'stringArray', {["a","b"]}, ...
            'cellstrArray', {{'a','b'}})
    end

    methods (Test, TestTags = {'Unit'})
        function acceptsValidInput(testCase, validInput)
            testCase.verifyWarningFree( ...
                @() aisdk.llms.internal.mustBeNonzeroLengthTextScalar(validInput));
        end

        function rejectsEmptyString(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeNonzeroLengthTextScalar(""), ...
                "MATLAB:validators:mustBeNonzeroLengthText");
        end

        function rejectsNonScalarInput(testCase, nonScalarInput)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeNonzeroLengthTextScalar(nonScalarInput), ...
                "MATLAB:validators:mustBeTextScalar");
        end
    end
end
