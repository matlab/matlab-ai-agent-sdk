classdef tmustBeMessagesInput < matlab.unittest.TestCase
% Tests for aisdk.internal.mustBeMessagesInput.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        invalidInput = struct( ...
            'emptyChar', {''}, ...
            'nonScalarStringArray', {["a", "b"]}, ...
            'numeric', {42}, ...
            'charColumnVector', {['a';'b']})
    end

    methods (Test, TestTags = {'Unit'})
        function acceptsScalarString(testCase)
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeMessagesInput("hello"));
        end

        function acceptsCharRowVector(testCase)
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeMessagesInput('hello'));
        end

        function acceptsLLMMessageObject(testCase)
            message = aisdk.LLMTextMessage("hi");
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeMessagesInput(message));
        end

        function rejectsInvalidInput(testCase, invalidInput)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeMessagesInput(invalidInput), ...
                "aisdk:client:InvalidMessageInput");
        end
    end
end
