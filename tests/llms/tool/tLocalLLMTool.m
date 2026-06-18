classdef tLocalLLMTool < matlab.unittest.TestCase
% Tests for aisdk.llms.tool.LocalLLMTool.

%   Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addFunctionsToPath(testCase)
            testsRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testsRoot, "resources", "functions")));
        end
    end

    methods (Test)
        function constructFromFunctionHandle(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyEqual(tool.Name, "addTwoNumbers");
        end

        function constructFromStringErrors(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool("addTwoNumbers"), ...
                "MATLAB:validation:UnableToConvert");
        end

        function extractsDescriptionFromMetadata(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbersUsingNVP);
            testCase.verifySubstring(tool.Description, "Add two numbers together");
        end

        function extractsInputsFromMetadata(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyLength(tool.InputArguments, 2);
            testCase.verifyEqual(tool.InputArguments(1).Name, "a");
            testCase.verifyEqual(tool.InputArguments(2).Name, "b");
            testCase.verifyEqual(tool.InputArguments(1).DataType, "number");
        end

        function extractsOutputsFromMetadata(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyLength(tool.OutputArguments, 1);
            testCase.verifyEqual(tool.OutputArguments(1).Name, "c");
        end

        function detectsNVPInputs(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbersUsingNVP);
            testCase.verifyLength(tool.InputArguments, 2);
            testCase.verifyTrue(tool.InputArguments(1).NameValue);
            testCase.verifyTrue(tool.InputArguments(2).NameValue);
        end

        function nvpArgsAreNotRequired(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbersUsingNVP);
            testCase.verifyFalse(tool.InputArguments(1).Required);
            testCase.verifyFalse(tool.InputArguments(2).Required);
        end

        function detectsPositionalInputs(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyFalse(tool.InputArguments(1).NameValue);
            testCase.verifyFalse(tool.InputArguments(2).NameValue);
        end

        function nvpArgsWithoutDefaultAreNotRequired(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@nvWithoutDefault);
            testCase.verifyFalse(tool.InputArguments(1).Required);
            testCase.verifyFalse(tool.InputArguments(2).Required);
        end

        function positionalArgsAreRequired(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyTrue(tool.InputArguments(1).Required);
            testCase.verifyTrue(tool.InputArguments(2).Required);
        end

        function mixedPositionalAndNVPRequired(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@greetUser);
            testCase.verifyTrue(tool.InputArguments(1).Required);
            testCase.verifyFalse(tool.InputArguments(2).Required);
        end

        function titleDefaultsToName(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyEqual(tool.DisplayTitle, "addTwoNumbers");
        end

        function customTitle(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, DisplayTitle="My Adder");
            testCase.verifyEqual(tool.DisplayTitle, "My Adder");
        end

        function customName(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, "myAdd");
            testCase.verifyEqual(tool.Name, "myAdd");
        end

        function customDescriptionOverridesMetadata(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, Description="Custom desc");
            testCase.verifyEqual(tool.Description, "Custom desc");
        end

        function defaultAnnotations(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyEqual(tool.Annotations, struct());
        end

        function customAnnotations(testCase)
            ann = struct("category", "math");
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, Annotations=ann);
            testCase.verifyEqual(tool.Annotations, ann);
        end

        function requiresApproval_withDefault_isNever(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyEqual(tool.RequiresApproval, aisdk.llms.tool.RequiresApproval.never);
        end

        function requiresApproval_withCustomValue_setsEnum(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, RequiresApproval="always");
            testCase.verifyEqual(tool.RequiresApproval, aisdk.llms.tool.RequiresApproval.always);
        end

        function inputsFromPrototypeStruct(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, ...
                InputArguments=struct("a", 5, "b", 3));
            testCase.verifyLength(tool.InputArguments, 2);
            testCase.verifyEqual(tool.InputArguments(1).Name, "a");
            testCase.verifyEqual(tool.InputArguments(1).DataType, "integer");
        end

        function inputsFromllmToolArgument(testCase)
            args = [aisdk.LLMToolArgument("a", DataType="number", Description="First"), ...
                  aisdk.LLMToolArgument("b", DataType="number", Description="Second")];
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, InputArguments=args);
            testCase.verifyLength(tool.InputArguments, 2);
            testCase.verifyEqual(tool.InputArguments(1).Description, "First");
        end

        function outputsFromPrototypeStruct(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, ...
                OutputArguments=struct("result", 1.0));
            testCase.verifyLength(tool.OutputArguments, 1);
            testCase.verifyEqual(tool.OutputArguments.Name, "result");
        end

        function callWithPositionalArgs(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            output = tool.evaluate(struct("a", 3, "b", 4));
            testCase.verifyEqual(output.c, 7);
        end

        function callWithNVPArgs(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbersUsingNVP);
            output = tool.evaluate(struct("a", 10, "b", 20));
            testCase.verifyEqual(output.c, 30);
        end

        function callSkipsOmittedOptionalArg(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@greetUser);
            output = tool.evaluate(struct("name", "Alice"));
            testCase.verifyEqual(output.msg, "Hello, Alice!");
        end

        function callErrorsOnMissingRequiredArg(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyError(@() tool.evaluate(struct("a", 1)), ...
                "llms:requiredArgumentNotFound");
        end

        function isLLMTool(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyInstanceOf(tool, "aisdk.llms.tool.LLMTool");
        end

        function isCallableTool(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyInstanceOf(tool, "aisdk.llms.tool.CallableTool");
        end

        function selectTool_existingName_returnsTool(testCase)
            tool1 = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            tool2 = aisdk.llms.tool.LocalLLMTool(@addTwoNumbersUsingNVP);
            tools = [tool1, tool2];
            found = tools.selectTool("addTwoNumbersUsingNVP");
            testCase.verifyEqual(found.Name, "addTwoNumbersUsingNVP");
        end

        function selectTool_unknownName_throwsError(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyError(@() tool.selectTool("nonexistent"), ...
                "llms:invalidFunctionCall");
        end

        function metadataDoubleTypeMapsToNumber(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyEqual(tool.InputArguments(1).DataType, "number");
            testCase.verifyEqual(tool.InputArguments(2).DataType, "number");
        end

        function heterogeneousConcatenation(testCase)
            tool1 = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            tool2 = aisdk.llms.tool.LocalLLMTool(@addTwoNumbersUsingNVP);
            tools = [tool1, tool2];
            testCase.verifyLength(tools, 2);
            testCase.verifyClass(tools, "aisdk.llms.tool.LocalLLMTool");
        end

        function constructFromEigWithMultipleOutputs(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@eig, ...
                Description="Eigenvalue decomposition", ...
                InputArguments=aisdk.LLMToolArgument("A", ...
                    DataType="number", Description="Input matrix"), ...
                OutputArguments=[...
                    aisdk.LLMToolArgument("V", Description="Right eigenvectors"), ...
                    aisdk.LLMToolArgument("D", Description="Eigenvalues"), ...
                    aisdk.LLMToolArgument("W", Description="Left eigenvectors")]);
            testCase.verifyEqual(tool.Name, "eig");
            testCase.verifyEqual(tool.Description, "Eigenvalue decomposition");
            testCase.verifyLength(tool.InputArguments, 1);
            testCase.verifyEqual(tool.InputArguments(1).Name, "A");
            testCase.verifyLength(tool.OutputArguments, 3);
            testCase.verifyEqual(tool.OutputArguments(1).Name, "V");
            testCase.verifyEqual(tool.OutputArguments(2).Name, "D");
            testCase.verifyEqual(tool.OutputArguments(3).Name, "W");
        end

        function callEigWithMultipleOutputs(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@eig, ...
                Description="Eigenvalue decomposition", ...
                InputArguments=aisdk.LLMToolArgument("A", ...
                    DataType="number", Description="Input matrix"), ...
                OutputArguments=[...
                    aisdk.LLMToolArgument("V", Description="Right eigenvectors"), ...
                    aisdk.LLMToolArgument("D", Description="Eigenvalues"), ...
                    aisdk.LLMToolArgument("W", Description="Left eigenvectors")]);

            % Simulate args as decoded from LLM JSON:
            % {"A": [[3,1,0],[0,3,1],[0,0,3]]}
            args = jsondecode('{"A":[[3,1,0],[0,3,1],[0,0,3]]}');

            output = tool.evaluate(args);
            [expectedV, expectedD, expectedW] = eig([3 1 0; 0 3 1; 0 0 3]);
            testCase.verifyEqual(output.V, expectedV, AbsTol=1e-14, RelTol=1e-10);
            testCase.verifyEqual(output.D, expectedD, AbsTol=1e-14, RelTol=1e-10);
            testCase.verifyEqual(output.W, expectedW, AbsTol=1e-14, RelTol=1e-10);
        end

        function callWithNoRegisteredOutputs(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            tool.OutputArguments = aisdk.LLMToolArgument.empty(1,0);
            output = tool.evaluate(struct("a", 3, "b", 4));
            testCase.verifyEqual(output, 7);
        end

        function callNVPWithNoRegisteredOutputs(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbersUsingNVP);
            tool.OutputArguments = aisdk.LLMToolArgument.empty(1,0);
            output = tool.evaluate(struct("a", 10, "b", 20));
            testCase.verifyEqual(output, 30);
        end

        function callContextualWithNoRegisteredOutputs(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@contextualAdd, ...
                Description="Add two numbers with context", ...
                InputArguments=[...
                    aisdk.LLMToolArgument("a", DataType="number"), ...
                    aisdk.LLMToolArgument("b", DataType="number")], ...
                OutputArguments=aisdk.LLMToolArgument.empty(1,0), ...
                Workspace="agent");

            args = struct("a", 3, "b", 4);

            workspace = struct("called", false);
            [output, workspace] = tool.evaluate(args, workspace);
            testCase.verifyEqual(output, 7);
            testCase.verifyTrue(workspace.called);
        end

        function callEigWithSingleOutput(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@eig, ...
                Description="Eigenvalues of a matrix", ...
                InputArguments=aisdk.LLMToolArgument("A", ...
                    DataType="number", Description="Input matrix"), ...
                OutputArguments=aisdk.LLMToolArgument("e", ...
                    Description="Column vector containing the eigenvalues of the input matrix"));

            args = jsondecode('{"A":[[3,1,0],[0,3,1],[0,0,3]]}');

            output = tool.evaluate(args);
            expected = eig([3 1 0; 0 3 1; 0 0 3]);
            testCase.verifyEqual(output.e, expected);
        end

        function callContextualEigWithMultipleOutputs(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@contextualEig, ...
                Description="Contextual eigenvalue decomposition", ...
                InputArguments=aisdk.LLMToolArgument("A", ...
                    DataType="number", Description="Input matrix"), ...
                OutputArguments=[...
                    aisdk.LLMToolArgument("V", Description="Right eigenvectors"), ...
                    aisdk.LLMToolArgument("D", Description="Eigenvalues"), ...
                    aisdk.LLMToolArgument("W", Description="Left eigenvectors")], ...
                Workspace="agent");

            args = jsondecode('{"A":[[3,1,0],[0,3,1],[0,0,3]]}');

            workspace = struct("called", false);
            [output, workspace] = tool.evaluate(args, workspace);
            [expectedV, expectedD, expectedW] = eig([3 1 0; 0 3 1; 0 0 3]);
            testCase.verifyEqual(output.V, expectedV, AbsTol=1e-14, RelTol=1e-10);
            testCase.verifyEqual(output.D, expectedD, AbsTol=1e-14, RelTol=1e-10);
            testCase.verifyEqual(output.W, expectedW, AbsTol=1e-14, RelTol=1e-10);
            testCase.verifyTrue(workspace.called);
        end

        function anonFunctionWithToolName(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@(x,y) x+y, "myAdder", ...
                InputArguments=[aisdk.LLMToolArgument("x", DataType="number"), ...
                    aisdk.LLMToolArgument("y", DataType="number")]);
            testCase.verifyEqual(tool.Name, "myAdder");
            output = tool.evaluate(struct("x", 3, "y", 4));
            testCase.verifyEqual(output, 7);
        end

        function anonymousFunction_positionalName_setsName(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@(x,y) x+y, "myAdder");
            testCase.verifyEqual(tool.Name, "myAdder");
        end

        function namedFunction_positionalName_overridesFuncName(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, "customName");
            testCase.verifyEqual(tool.Name, "customName");
        end

        function anonFunctionWithoutNameErrors(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool(@(x,y) x+y), ...
                "llms:anonymousFunctionRequiresName");
        end

        function duplicateInputNameErrors(testCase)
            dupeInputs = [aisdk.LLMToolArgument("x", DataType="number"), ...
                          aisdk.LLMToolArgument("x", DataType="number")];
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, InputArguments=dupeInputs), ...
                "llms:duplicateArgumentNames");
        end

        function duplicateOutputNameErrors(testCase)
            dupeOutputs = [aisdk.LLMToolArgument("y", DataType="number"), ...
                           aisdk.LLMToolArgument("y", DataType="number")];
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, OutputArguments=dupeOutputs), ...
                "llms:duplicateArgumentNames");
        end

        function constructor_invalidDefinition_errors(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool(42), ...
                "MATLAB:validation:UnableToConvert");
        end

        function construct_noWorkspaceSpecified_defaultsToNone(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@sin, Description="Sine");
            testCase.verifyEqual(tool.Workspace, "none");
        end

        function construct_workspaceNone_setsNone(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@sin, Description="Sine", Workspace="none");
            testCase.verifyEqual(tool.Workspace, "none");
        end

        function construct_invalidWorkspace_errors(testCase)
            testCase.verifyError(@() aisdk.llms.tool.LocalLLMTool(@sin, ...
                Description="Sine", Workspace="invalid"), ...
                "MATLAB:validators:mustBeMember");
        end

        function constructor_noMetadata_returnsEmptyInputs(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@() "hello", "noMeta", ...
                Description="A function with no metadata");
            testCase.verifyEmpty(tool.InputArguments);
        end

        function constructor_logicalInput_mapsToBoolean(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@logicalInput);
            testCase.verifyEqual(tool.InputArguments(1).DataType, "boolean");
        end

        function constructor_unknownType_errors(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool(@tableInput), ...
                "llms:unsupportedMATLABType");
        end

        function constructor_functionWithVarargin_excludesFromInputArguments(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@normcdf);
            testCase.verifySize(tool.InputArguments, [1 1]);
        end

        function constructor_functionWithVarargout_excludesFromOutputArguments(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@size);
            testCase.verifyEmpty(tool.OutputArguments);
        end

        function constructor_withNamespacedFunction_replacesDotsWithUnderscores(testCase)
            tool = aisdk.LLMTool(@some.namespace.testFcn);
            testCase.verifyEqual(tool.Name, "some_namespace_testFcn");
        end
    end

end

function [V, D, W, workspace] = contextualEig(workspace, A)
    [V, D, W] = eig(A);
    workspace.called = true;
end

function [output, workspace] = contextualAdd(workspace, a, b)
    output = a + b;
    workspace.called = true;
end
