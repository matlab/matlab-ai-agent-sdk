classdef tmustBeTextOrEmpty < matlab.unittest.TestCase
% Tests for aisdk.internal.mustBeTextOrEmpty.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        validInput = struct( ...
            'scalarString', {"hello"}, ...
            'charVector', {'abc'}, ...
            'emptyChar', {''}, ...
            'emptyDouble', {[]}, ...
            'emptyString', {""})
    end

    methods (Test, TestTags = {'Unit'})
        function acceptsValidInput(testCase, validInput)
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeTextOrEmpty(validInput));
        end

        function rejectsNonScalarText(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeTextOrEmpty(["a","b"]), ...
                "MATLAB:validators:mustBeTextScalar");
        end
    end
end
