classdef tmustBeValidStop < matlab.unittest.TestCase
% Tests for aisdk.llms.internal.mustBeValidStop.

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
                @() aisdk.llms.internal.mustBeValidStop(validInput));
        end

        function rejectsEmptyStringElement(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeValidStop(""), ...
                "MATLAB:validators:mustBeNonzeroLengthText");
        end
    end
end
