classdef tmustBeResponseFormat < matlab.unittest.TestCase
%tmustBeResponseFormat Tests for aisdk.llms.internal.mustBeResponseFormat.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function acceptsText(testCase)
            testCase.verifyWarningFree( ...
                @() aisdk.llms.internal.mustBeResponseFormat("text"));
        end

        function acceptsJson(testCase)
            testCase.verifyWarningFree( ...
                @() aisdk.llms.internal.mustBeResponseFormat("json"));
        end

        function acceptsStruct(testCase)
            testCase.verifyWarningFree( ...
                @() aisdk.llms.internal.mustBeResponseFormat(struct("x", 0)));
        end

        function acceptsJSONSchemaString(testCase)
            schema = '{"type":"object","properties":{"x":{"type":"number"}}}';
            testCase.verifyWarningFree( ...
                @() aisdk.llms.internal.mustBeResponseFormat(schema));
        end

        function acceptsJSONSchemaStringWithLeadingWhitespace(testCase)
            schema = '  {"type":"object"}';
            testCase.verifyWarningFree( ...
                @() aisdk.llms.internal.mustBeResponseFormat(schema));
        end

        function rejectsInvalidString(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeResponseFormat("invalid"), ...
                "llms:incorrectResponseFormat");
        end

        function rejectsNumeric(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeResponseFormat(42), ...
                "llms:incorrectResponseFormat");
        end

        function rejectsLogical(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.mustBeResponseFormat(true), ...
                "llms:incorrectResponseFormat");
        end
    end
end
