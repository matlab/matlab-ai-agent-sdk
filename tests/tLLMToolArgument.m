classdef tLLMToolArgument < matlab.unittest.TestCase
% Tests for LLMToolArgument.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function constructorSetsName(testCase)
            arg = aisdk.LLMToolArgument("x");
            testCase.verifyEqual(arg.Name, "x");
        end

        function defaultDescription(testCase)
            arg = aisdk.LLMToolArgument("x");
            testCase.verifyEqual(arg.Description, "");
        end

        function defaultType(testCase)
            arg = aisdk.LLMToolArgument("x");
            testCase.verifyEqual(arg.DataType, "");
        end

        function defaultRequired(testCase)
            arg = aisdk.LLMToolArgument("x");
            testCase.verifyTrue(arg.Required);
        end

        function defaultNameValue(testCase)
            arg = aisdk.LLMToolArgument("x");
            testCase.verifyFalse(arg.NameValue);
        end


        function customValues(testCase)
            arg = aisdk.LLMToolArgument("city", ...
                Description="City name", DataType="string", ...
                Required=false, NameValue=true);
            testCase.verifyEqual(arg.Description, "City name");
            testCase.verifyEqual(arg.DataType, "string");
            testCase.verifyFalse(arg.Required);
            testCase.verifyTrue(arg.NameValue);
        end

        function summaryReturnsTable(testCase)
            args = [aisdk.LLMToolArgument("a", DataType="number", Description="First"), ...
                   aisdk.LLMToolArgument("b", DataType="string", Description="Second")];
            tbl = args.summary;
            testCase.verifyClass(tbl, "table");
            testCase.verifyEqual(height(tbl), 2);
            testCase.verifyEqual(tbl.Name, ["a"; "b"]);
        end

        function fromPrototypeInfersNumber(testCase)
            args = aisdk.LLMToolArgument(struct("x", pi));
            testCase.verifyEqual(args.DataType, "number");
        end

        function fromPrototypeInfersInteger(testCase)
            args = aisdk.LLMToolArgument(struct("n", 5));
            testCase.verifyEqual(args.DataType, "integer");
        end

        function fromPrototypeInf_infersNumber(testCase)
            args = aisdk.LLMToolArgument(struct("val", Inf));
            testCase.verifyEqual(args.DataType, "number");
        end

        function fromPrototypeNaN_infersNumber(testCase)
            args = aisdk.LLMToolArgument(struct("val", NaN));
            testCase.verifyEqual(args.DataType, "number");
        end

        function fromPrototypeNumericArray_errors(testCase)
            testCase.verifyError(@() aisdk.LLMToolArgument(struct("weights", [-0.1, 0.8, -0.1])), ...
                "llms:arrayPrototypeNotSupported");
        end

        function fromPrototypeLogicalArray_errors(testCase)
            testCase.verifyError(@() aisdk.LLMToolArgument(struct("flags", [true false true])), ...
                "llms:arrayPrototypeNotSupported");
        end

        function fromPrototypeInfersString(testCase)
            args = aisdk.LLMToolArgument(struct("s", "hello"));
            testCase.verifyEqual(args.DataType, "string");
        end

        function fromPrototypeInfersBoolean(testCase)
            args = aisdk.LLMToolArgument(struct("flag", true));
            testCase.verifyEqual(args.DataType, "boolean");
        end

        function fromPrototypeMultipleFields(testCase)
            args = aisdk.LLMToolArgument(struct("a", 1, "b", pi));
            testCase.verifyLength(args, 2);
            testCase.verifyEqual(args(1).Name, "a");
            testCase.verifyEqual(args(2).Name, "b");
        end

        function fromPrototype_scalarRequired_appliesToAll(testCase)
            args = aisdk.LLMToolArgument(struct("x", 1, "y", "hi"), Required=false);
            testCase.verifyFalse(args(1).Required);
            testCase.verifyFalse(args(2).Required);
        end

        function fromPrototype_arrayRequired_appliesPerField(testCase)
            args = aisdk.LLMToolArgument(struct("a", 1, "b", 2), Required=[true, false]);
            testCase.verifyTrue(args(1).Required);
            testCase.verifyFalse(args(2).Required);
        end

        function arrayConstruction(testCase)
            args = [aisdk.LLMToolArgument("a"), aisdk.LLMToolArgument("b")];
            testCase.verifyLength(args, 2);
        end

        function emptyArray(testCase)
            args = aisdk.LLMToolArgument.empty(1, 0);
            testCase.verifyEmpty(args);
        end

        function errorOnNumericInput(testCase)
            testCase.verifyError(@() aisdk.LLMToolArgument(42), ...
                "llmToolArgument:invalidInput");
        end

        function errorOnLogicalInput(testCase)
            testCase.verifyError(@() aisdk.LLMToolArgument(true), ...
                "llmToolArgument:invalidInput");
        end

        function errorOnStringArray(testCase)
            testCase.verifyError(@() aisdk.LLMToolArgument(["a", "b"]), ...
                "llmToolArgument:invalidInput");
        end

        function errorOnStructArray(testCase)
            s = [struct("a", 1), struct("a", 2)];
            testCase.verifyError(@() aisdk.LLMToolArgument(s), ...
                "llmToolArgument:invalidInput");
        end

        function nonScalarRequired_errors(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMToolArgument("x", Required=[true, false]), ...
                "llmToolArgument:nonScalarRequired");
        end

        function nonScalarNameValue_errors(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMToolArgument("x", NameValue=[true, false]), ...
                "llmToolArgument:nonScalarNameValue");
        end

        function nameValue_noExplicitRequired_defaultsToFalse(testCase)
            arg = aisdk.LLMToolArgument("x", NameValue=true);
            testCase.verifyFalse(arg.Required);
        end

        function nameValue_explicitRequiredTrue_succeeds(testCase)
            % MATLAB-required: must be provided to call the function without
            % error. For name-values, this is always false (they have defaults).
            % Schema-required: the LLM must provide this in its tool call.
            % LLMToolArgument.Required controls the latter, not the former.
            arg = aisdk.LLMToolArgument("x", Required=true, NameValue=true);
            testCase.verifyTrue(arg.Required);
            testCase.verifyTrue(arg.NameValue);
        end

        function errorOnComplexNumericInPrototype(testCase)
            testCase.verifyError(@() aisdk.LLMToolArgument(struct("z", 1+2i)), ...
                "llms:unsupportedDatatypeInPrototype");
        end

        function errorOnNestedStructInPrototype(testCase)
            testCase.verifyError(@() aisdk.LLMToolArgument(struct("s", struct("a", 1))), ...
                "llms:unsupportedDatatypeInPrototype");
        end

        function fromPrototypeNonBaseNumeric_errors(testCase)
            testCase.verifyError(@() aisdk.LLMToolArgument(struct("x", dlarray(0))), ...
                "llms:unsupportedDatatypeInPrototype");
        end
    end

end
