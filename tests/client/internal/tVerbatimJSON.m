classdef tVerbatimJSON < matlab.unittest.TestCase
%tVerbatimJSON Tests for aisdk.client.internal.VerbatimJSON.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function encodesRawString(testCase)
            rawSchema = '{"type":"object","properties":{"x":{"type":"number"}}}';
            obj = aisdk.client.internal.VerbatimJSON(rawSchema);
            testCase.verifyEqual(jsonencode(obj), string(rawSchema));
        end

        function embeddedInStructEncodesInline(testCase)
            rawSchema = '{"type":"string"}';
            obj = aisdk.client.internal.VerbatimJSON(rawSchema);
            s = struct("schema", obj, "name", "test");
            encoded = jsonencode(s);
            testCase.verifySubstring(encoded, '"schema":{"type":"string"}');
        end
    end
end
