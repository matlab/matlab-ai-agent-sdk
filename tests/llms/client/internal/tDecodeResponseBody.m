classdef tDecodeResponseBody < matlab.unittest.TestCase
%tDecodeResponseBody Tests for decodeResponseBody.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function structInput_passesThrough(testCase)
            input = struct("foo", "bar");
            result = aisdk.llms.client.internal.decodeResponseBody(input);
            testCase.verifyEqual(result, input);
        end

        function cellInput_passesThrough(testCase)
            input = {struct("a", 1)};
            result = aisdk.llms.client.internal.decodeResponseBody(input);
            testCase.verifyEqual(result, input);
        end

        function numericBytes_decodesToStruct(testCase)
            jsonStr = '{"key":"value"}';
            bytes = uint8(jsonStr);
            result = aisdk.llms.client.internal.decodeResponseBody(bytes);
            testCase.verifyEqual(result.key, 'value');
        end

        function jsonString_decodesToStruct(testCase)
            result = aisdk.llms.client.internal.decodeResponseBody('{"x":42}');
            testCase.verifyEqual(result.x, 42);
        end

        function ndjsonString_withCompatibleStructures_decodesToArray(testCase)
            ndjson = sprintf('{"a":1}\n{"a":2}');
            result = aisdk.llms.client.internal.decodeResponseBody(ndjson);
            testCase.verifyClass(result, 'struct');
            testCase.verifyNumElements(result, 2);
            testCase.verifyEqual(result(1).a, 1);
            testCase.verifyEqual(result(2).a, 2);
        end

        function ndjsonString_withIncompatibleStructures_decodesToCellOfStruct(testCase)
            ndjson = sprintf('{"a":1}\n{"b":2}');
            result = aisdk.llms.client.internal.decodeResponseBody(ndjson);
            testCase.verifyClass(result, 'cell');
            testCase.verifyNumElements(result, 2);
            testCase.verifyEqual(result{1}.a, 1);
            testCase.verifyEqual(result{2}.b, 2);
        end

        function invalidString_returnsUnchanged(testCase)
            input = "not json at all";
            result = aisdk.llms.client.internal.decodeResponseBody(input);
            testCase.verifyEqual(result, input);
        end
    end

end
