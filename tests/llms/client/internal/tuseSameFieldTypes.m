classdef tuseSameFieldTypes < matlab.unittest.TestCase
%tuseSameFieldTypes Tests for aisdk.llms.client.internal.useSameFieldTypes.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function convertsToString(testCase)
            data = struct("name", 'Alice');
            proto = struct("name", "");
            result = aisdk.llms.client.internal.useSameFieldTypes(data, proto);
            testCase.verifyEqual(result.name, "Alice");
        end

        function convertsToInteger(testCase)
            data = struct("count", 5);
            proto = struct("count", int32(0));
            result = aisdk.llms.client.internal.useSameFieldTypes(data, proto);
            testCase.verifyEqual(result.count, int32(5));
        end

        function convertsToCategorical(testCase)
            data = struct("color", "red");
            proto = struct("color", categorical("red", ["red","green","blue"]));
            result = aisdk.llms.client.internal.useSameFieldTypes(data, proto);
            testCase.verifyEqual(result.color, categorical("red", ["red","green","blue"]));
        end

        function handlesNestedStruct(testCase)
            data = struct("person", struct("name", 'Bob', "age", 25));
            proto = struct("person", struct("name", "", "age", int32(0)));
            result = aisdk.llms.client.internal.useSameFieldTypes(data, proto);
            testCase.verifyEqual(result.person.name, "Bob");
            testCase.verifyEqual(result.person.age, int32(25));
        end

        function handlesStructArray(testCase)
            data = [struct("x", 1); struct("x", 2)];
            proto = struct("x", int32(0));
            result = aisdk.llms.client.internal.useSameFieldTypes(data, proto);
            testCase.verifyEqual(numel(result), 2);
            testCase.verifyEqual(result(1).x, int32(1));
            testCase.verifyEqual(result(2).x, int32(2));
        end

        function handlesMissingPrototype(testCase)
            data = struct("val", []);
            proto = struct("val", missing);
            result = aisdk.llms.client.internal.useSameFieldTypes(data, proto);
            testCase.verifyTrue(ismissing(result.val));
        end
    end
end
