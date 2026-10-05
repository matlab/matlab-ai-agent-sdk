classdef tmustBeValidStop < matlab.unittest.TestCase
% Tests for aisdk.internal.mustBeValidStop.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        validInput = struct( ...
            'empty', {[]}, ...
            'singleString', {"stop"}, ...
            'charVector', {'stop'}, ...
            'fourSequences', {["a","b","c","d"]})
    end

    methods (Test, TestTags = {'Unit'})
        function acceptsValidInput(testCase, validInput)
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeValidStop(validInput));
        end

        function rejectsEmptyStringElement(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeValidStop(""), ...
                "MATLAB:validators:mustBeNonzeroLengthText");
        end
    end
end
