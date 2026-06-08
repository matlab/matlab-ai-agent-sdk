classdef treformatOutput < matlab.unittest.TestCase
%treformatOutput Tests for aisdk.llms.client.internal.reformatOutput.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        function textFormatPassesThrough(testCase)
            result = aisdk.llms.client.internal.reformatOutput("hello", "text");
            testCase.verifyEqual(result, "hello");
        end

        function jsonFormatPassesThrough(testCase)
            result = aisdk.llms.client.internal.reformatOutput('{"x":1}', "json");
            testCase.verifyEqual(result, '{"x":1}');
        end

        function structFormatDecodesJSON(testCase)
            proto = struct("name", "", "age", int32(0));
            jsonStr = '{"name":"Alice","age":30}';
            result = aisdk.llms.client.internal.reformatOutput(jsonStr, proto);
            testCase.verifyTrue(isstruct(result));
            testCase.verifyEqual(result.name, "Alice");
            testCase.verifyEqual(result.age, int32(30));
        end

        function nonScalarPrototypeExtractsResultField(testCase)
            proto = repmat(struct("x", 0.0), 2, 1);
            jsonStr = '{"result":[{"x":1.5},{"x":2.5}]}';
            result = aisdk.llms.client.internal.reformatOutput(jsonStr, proto);
            testCase.verifyEqual(numel(result), 2);
            testCase.verifyEqual(result(1).x, 1.5);
            testCase.verifyEqual(result(2).x, 2.5);
        end

        function invalidJSONErrors(testCase)
            proto = struct("x", 0.0);
            testCase.verifyError( ...
                @() aisdk.llms.client.internal.reformatOutput("not json{", proto), ...
                "llms:apiReturnedIncompleteJSON");
        end
    end
end
