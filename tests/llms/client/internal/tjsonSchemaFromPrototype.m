classdef tjsonSchemaFromPrototype < matlab.unittest.TestCase
%tjsonSchemaFromPrototype Tests for aisdk.llms.client.internal.jsonSchemaFromPrototype.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function scalarStructProducesObjectSchema(testCase)
            proto = struct("name", "", "age", int32(0));
            schema = aisdk.llms.client.internal.jsonSchemaFromPrototype(proto);
            testCase.verifyEqual(schema.type, "object");
            testCase.verifyEqual(schema.properties.name.type, "string");
            testCase.verifyEqual(schema.properties.age.type, "integer");
            testCase.verifyEqual(schema.additionalProperties, false);
            testCase.verifyTrue(any(schema.required == "name"));
            testCase.verifyTrue(any(schema.required == "age"));
        end

        function numericFieldMapsToNumber(testCase)
            proto = struct("value", 3.14);
            schema = aisdk.llms.client.internal.jsonSchemaFromPrototype(proto);
            testCase.verifyEqual(schema.properties.value.type, "number");
        end

        function logicalFieldMapsToBoolean(testCase)
            proto = struct("flag", true);
            schema = aisdk.llms.client.internal.jsonSchemaFromPrototype(proto);
            testCase.verifyEqual(schema.properties.flag.type, "boolean");
        end

        function stringFieldMapsToString(testCase)
            proto = struct("label", "");
            schema = aisdk.llms.client.internal.jsonSchemaFromPrototype(proto);
            testCase.verifyEqual(schema.properties.label.type, "string");
        end

        function categoricalFieldMapsToEnum(testCase)
            proto = struct("color", categorical("red", ["red","green","blue"]));
            schema = aisdk.llms.client.internal.jsonSchemaFromPrototype(proto);
            testCase.verifyEqual(schema.properties.color.type, "string");
            testCase.verifyEqual(schema.properties.color.enum, {'red';'green';'blue'});
        end

        function missingFieldMapsToNull(testCase)
            proto = struct("empty", missing);
            schema = aisdk.llms.client.internal.jsonSchemaFromPrototype(proto);
            testCase.verifyEqual(schema.properties.empty.type, "null");
        end

        function nestedStructProducesNestedObject(testCase)
            proto = struct("person", struct("name", "", "age", int32(0)));
            schema = aisdk.llms.client.internal.jsonSchemaFromPrototype(proto);
            testCase.verifyEqual(schema.properties.person.type, "object");
            testCase.verifyEqual(schema.properties.person.properties.name.type, "string");
        end

        function nonScalarStructWrapsInResultField(testCase)
            proto = repmat(struct("x", 0.0), 2, 1);
            schema = aisdk.llms.client.internal.jsonSchemaFromPrototype(proto);
            testCase.verifyEqual(schema.type, "object");
            testCase.verifyTrue(isfield(schema.properties, "result"));
            testCase.verifyEqual(schema.properties.result.type, "array");
            testCase.verifyEqual(schema.properties.result.items.type, "object");
        end

        function nonStructInputErrors(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.client.internal.jsonSchemaFromPrototype("not a struct"), ...
                "llms:incorrectResponseFormat");
        end

        function unsupportedTypeErrors(testCase)
            proto = struct("bad", @disp);
            testCase.verifyError( ...
                @() aisdk.llms.client.internal.jsonSchemaFromPrototype(proto), ...
                "llms:unsupportedDatatypeInPrototype");
        end

        function cellstrFieldMapsToString(testCase)
            proto = struct("someField", {{'someValue'}});
            schema = aisdk.llms.client.internal.jsonSchemaFromPrototype(proto);
            testCase.verifyEqual(schema.properties.someField.type, "string");
        end

        function dlarrayIsNotTreatedAsNumeric(testCase)
            testCase.assumeTrue(exist('dlarray','class') == 8, ...
                "Deep Learning Toolbox not available");
            proto = struct("val", dlarray(1));
            testCase.verifyError( ...
                @() aisdk.llms.client.internal.jsonSchemaFromPrototype(proto), ...
                "llms:unsupportedDatatypeInPrototype");
        end
    end
end
