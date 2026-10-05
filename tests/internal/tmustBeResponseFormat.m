classdef tmustBeResponseFormat < matlab.unittest.TestCase
%tmustBeResponseFormat Tests for aisdk.internal.mustBeResponseFormat.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function acceptsText(testCase)
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeResponseFormat("text"));
        end

        function acceptsJson(testCase)
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeResponseFormat("json"));
        end

        function acceptsStruct(testCase)
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeResponseFormat(struct("x", 0)));
        end

        function acceptsJSONSchemaString(testCase)
            schema = '{"type":"object","properties":{"x":{"type":"number"}}}';
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeResponseFormat(schema));
        end

        function acceptsJSONSchemaStringWithLeadingWhitespace(testCase)
            schema = '  {"type":"object"}';
            testCase.verifyWarningFree( ...
                @() aisdk.internal.mustBeResponseFormat(schema));
        end

        function rejectsInvalidString(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeResponseFormat("invalid"), ...
                "aisdk:incorrectResponseFormat");
        end

        function rejectsEmptyStruct(testCase)
            % A prototype without elements describes no output at all.
            testCase.verifyError( ...
                @() aisdk.internal.mustBeResponseFormat(struct([])), ...
                "aisdk:incorrectResponseFormat");
        end

        function rejectsEmptyStructWithFields(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeResponseFormat(struct("x", {})), ...
                "aisdk:incorrectResponseFormat");
        end

        function rejectsNumeric(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeResponseFormat(42), ...
                "aisdk:incorrectResponseFormat");
        end

        function rejectsLogical(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.mustBeResponseFormat(true), ...
                "aisdk:incorrectResponseFormat");
        end
    end
end
