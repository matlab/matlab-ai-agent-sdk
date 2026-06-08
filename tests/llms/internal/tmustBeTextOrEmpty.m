classdef tmustBeTextOrEmpty < matlab.unittest.TestCase
% Tests for aisdk.llms.internal.mustBeTextOrEmpty.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        validInput = struct( ...
            'scalarString', {"hello"}, ...
            'charVector', {'abc'}, ...
            'emptyChar', {''}, ...
            'emptyDouble', {[]}, ...
            'emptyString', {""})
    end

    methods (Test)
        function acceptsValidInput(testCase, validInput)
            testCase.verifyWarningFree( ...
                @() aisdk.llms.internal.mustBeTextOrEmpty(validInput));
        end

        function rejectsNonScalarText(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeTextOrEmpty(["a","b"]), ...
                "MATLAB:validators:mustBeTextScalar");
        end
    end
end
