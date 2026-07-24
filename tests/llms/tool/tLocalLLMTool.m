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

    methods (Test, TestTags = {'Unit'})
        function constructFromFunctionHandle(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyEqual(tool.Name, "addTwoNumbers");
        end

        function constructFromStringErrors(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool("addTwoNumbers"), ...
                "MATLAB:validation:UnableToConvert");
        end

        function constructFromFunctionWithUntypedArgument_leavesDataTypeEmpty(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@untypedArgument);
            testCase.verifyEqual(tool.InputArguments(1).DataType, "");
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

        function outputsFromllmToolArgument(testCase)
            args = aisdk.LLMToolArgument("result", DataType="number", Description="Sum");
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, OutputArguments=args);
            testCase.verifyLength(tool.OutputArguments, 1);
            testCase.verifyEqual(tool.OutputArguments(1).Description, "Sum");
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

        function select_existingName_returnsTool(testCase)
            tool1 = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            tool2 = aisdk.llms.tool.LocalLLMTool(@addTwoNumbersUsingNVP);
            tools = [tool1, tool2];
            found = tools.select("addTwoNumbersUsingNVP");
            testCase.verifyEqual(found.Name, "addTwoNumbersUsingNVP");
        end

        function select_unknownName_throwsError(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyError(@() tool.select("nonexistent"), ...
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

        function anonymousFunction_withExplicitArguments_evaluatesCorrectly(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@(x,y) x+y, "myAdder", ...
                InputArguments=[aisdk.LLMToolArgument("x", DataType="number"), ...
                    aisdk.LLMToolArgument("y", DataType="number")], ...
                OutputArguments=aisdk.LLMToolArgument("result", DataType="number"));
            output = tool.evaluate(struct("x", 3, "y", 4));
            testCase.verifyEqual(output.result, 7);
        end

        function anonymousFunction_positionalName_setsName(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@(x,y) x+y, "myAdder", ...
                InputArguments=[aisdk.LLMToolArgument("x", DataType="number"), ...
                    aisdk.LLMToolArgument("y", DataType="number")], ...
                OutputArguments=aisdk.LLMToolArgument("result"));
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

        function constructor_invalidInputArguments_errors(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, InputArguments=42), ...
                "llms:invalidToolArguments");
        end

        function constructor_invalidOutputArguments_errors(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, OutputArguments="bad"), ...
                "llms:invalidToolArguments");
        end

        function constructor_invalidDefinition_errors(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool(42), ...
                "MATLAB:validation:UnableToConvert");
        end

        function construct_noWorkspaceSpecified_defaultsToNone(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyEqual(tool.Workspace, "none");
        end

        function construct_workspaceNone_setsNone(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, Workspace="none");
            testCase.verifyEqual(tool.Workspace, "none");
        end

        function construct_invalidWorkspace_errors(testCase)
            testCase.verifyError(@() aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, ...
                Workspace="invalid"), ...
                "MATLAB:validators:mustBeMember");
        end

        function construct_workspaceAgent_withNoLLMVisibleOutput_errors(testCase)
            testCase.verifyError(@() aisdk.llms.tool.LocalLLMTool( ...
                @singleOutputWorkspace, "myTool", ...
                Description="Tool with only workspace output", ...
                Workspace="agent"), ...
                "llms:workspaceRequiresMultipleOutputs");
        end

        function construct_workspaceAgent_varargout_errors(testCase)
            testCase.verifyError(@() aisdk.llms.tool.LocalLLMTool( ...
                @varargoutWorkspace, "varTool", ...
                Description="Tool with varargout", ...
                Workspace="agent"), ...
                "llms:workspaceDoesNotSupportVarargout");
        end

        function constructor_nonexistentFunction_errors(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool(@functionThatDoesNotExist), ...
                "llms:cannotInferInputArguments");
        end

        function constructor_noMetadata_noInputArguments_errors(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool(@(a,b) a+b, "add"), ...
                "llms:cannotInferInputArguments");
        end

        function constructor_noMetadata_withExplicitArguments_succeeds(testCase)
            args = aisdk.LLMToolArgument("a", DataType="number");
            tool = aisdk.llms.tool.LocalLLMTool(@(a) a*2, "double", ...
                InputArguments=args, OutputArguments=aisdk.LLMToolArgument("result"));
            testCase.verifyLength(tool.InputArguments, 1);
        end

        function constructor_noMetadata_noOutputArguments_nargoutNotOne_errors(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool(@(a) a+1, "inc", ...
                    InputArguments=aisdk.LLMToolArgument("a", DataType="number")), ...
                "llms:unknownOutputCount");
        end

        function constructor_vararginInInputs_noInputArguments_errors(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool(@typedWithVarargin), ...
                "llms:vararginInInputs");
        end

        function constructor_vararginInInputs_withInputArguments_succeeds(testCase)
            args = [aisdk.LLMToolArgument("x", DataType="number"), ...
                    aisdk.LLMToolArgument("y", DataType="number")];
            tool = aisdk.llms.tool.LocalLLMTool(@typedWithVarargin, ...
                InputArguments=args);
            testCase.verifyLength(tool.InputArguments, 2);
        end

        function constructor_varargoutInOutputs_noOutputArguments_errors(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool(@size, ...
                    InputArguments=aisdk.LLMToolArgument("A", DataType="number")), ...
                "llms:varargoutInOutputs");
        end

        function constructor_varargoutInOutputs_withOutputArguments_succeeds(testCase)
            outs = [aisdk.LLMToolArgument("m"), aisdk.LLMToolArgument("n")];
            tool = aisdk.llms.tool.LocalLLMTool(@size, ...
                InputArguments=aisdk.LLMToolArgument("A", DataType="number"), ...
                OutputArguments=outs);
            testCase.verifyLength(tool.OutputArguments, 2);
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

        function constructor_withNamespacedFunction_replacesDotsWithUnderscores(testCase)
            tool = aisdk.LLMTool(@some.namespace.testFcn);
            testCase.verifyEqual(tool.Name, "some_namespace_testFcn");
        end

        function constructor_nonScalarMetafunction_errors(testCase)
            % Only applies on 25b and earlier (matlab.internal.metafunction path)
            testCase.assumeEmpty(which('metafunction'));
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool(@count), ...
                "llms:cannotInferInputArguments");
        end

        function constructor_nonScalarMetafunction_succeedsWithExplicitArgs(testCase)
            % Only applies on 25b and earlier (matlab.internal.metafunction path)
            testCase.assumeEmpty(which('metafunction'));
            tool = aisdk.llms.tool.LocalLLMTool(@count, ...
                InputArguments=struct(input="str"), ...
                OutputArguments=struct(n=0));
            testCase.verifyEqual(tool.InputArguments.Name, "input");
            testCase.verifyEqual(tool.OutputArguments.Name, "n");
        end

        function anonymousFunction_zeroInputsZeroOutputs_succeeds(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@() disp('Hello'), "greet", ...
                InputArguments=struct(), OutputArguments=struct());
            testCase.verifyEmpty(tool.InputArguments);
            testCase.verifyEmpty(tool.OutputArguments);
        end

        function anonymousFunction_explicitArguments_overrideEmptyMetadata(testCase)
            inputs = [aisdk.LLMToolArgument("x", DataType="number"), ...
                    aisdk.LLMToolArgument("y", DataType="number")];
            outputs = aisdk.LLMToolArgument("result", DataType="number");
            tool = aisdk.llms.tool.LocalLLMTool(@(x, y) x + y, "add", ...
                InputArguments=inputs, OutputArguments=outputs);
            testCase.verifyLength(tool.InputArguments, 2);
            testCase.verifyEqual(tool.InputArguments(1).Name, "x");
            testCase.verifyEqual(tool.InputArguments(2).Name, "y");
            testCase.verifyLength(tool.OutputArguments, 1);
            testCase.verifyEqual(tool.OutputArguments(1).Name, "result");
        end

        function staticMethod_extractsInputsFromMetadata(testCase)
            tool = aisdk.llms.tool.LocalLLMTool( ...
                @ToolTestHelper.addNumbers, "addNumbers");
            testCase.verifyLength(tool.InputArguments, 2);
            testCase.verifyEqual(tool.InputArguments(1).Name, "a");
            testCase.verifyEqual(tool.InputArguments(2).Name, "b");
        end

        function staticMethod_extractsOutputsFromMetadata(testCase)
            tool = aisdk.llms.tool.LocalLLMTool( ...
                @ToolTestHelper.addNumbers, "addNumbers");
            testCase.verifyLength(tool.OutputArguments, 1);
            testCase.verifyEqual(tool.OutputArguments(1).Name, "c");
        end

        function staticMethod_description_extractedFromMetadata(testCase)
            tool = aisdk.llms.tool.LocalLLMTool( ...
                @ToolTestHelper.addNumbers, "addNumbers");
            testCase.verifyEqual(tool.Description, "Add two numbers together.");
        end

        function staticMethod_name_replacesDotsWithUnderscores(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@ToolTestHelper.addNumbers);
            testCase.verifyEqual(tool.Name, "ToolTestHelper_addNumbers");
        end

        function staticMethod_multipleOutputs_extractedFromMetadata(testCase)
            tool = aisdk.llms.tool.LocalLLMTool( ...
                @ToolTestHelper.doAllMathsStatic, "doAllMathsStatic");
            testCase.verifyLength(tool.OutputArguments, 4);
            testCase.verifyEqual(tool.OutputArguments(1).Name, "added");
            testCase.verifyEqual(tool.OutputArguments(2).Name, "subtracted");
            testCase.verifyEqual(tool.OutputArguments(3).Name, "multiplied");
            testCase.verifyEqual(tool.OutputArguments(4).Name, "divided");
        end

        function instanceMethod_requiresName(testCase)
            obj = ToolTestHelper();
            testCase.verifyError( ...
                @() aisdk.llms.tool.LocalLLMTool(@obj.multiply), ...
                "llms:anonymousFunctionRequiresName");
        end

        function localFunction_inputArguments_extractedFromMetadata(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@localAdd);
            testCase.verifyLength(tool.InputArguments, 2);
            testCase.verifyEqual(tool.InputArguments(1).Name, "a");
            testCase.verifyEqual(tool.InputArguments(1).DataType, "number");
            testCase.verifyEqual(tool.InputArguments(2).Name, "b");
            testCase.verifyEqual(tool.InputArguments(2).DataType, "number");
        end

        function localFunction_outputArguments_extractedFromMetadata(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@localAdd);
            testCase.verifyLength(tool.OutputArguments, 1);
            testCase.verifyEqual(tool.OutputArguments(1).Name, "c");
        end

        function localFunction_description_extractedFromMetadata(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@localAdd);
            testCase.verifyEqual(tool.Description, "Add two numbers together.");
        end

        function localFunction_name_extractedFromHandle(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@localAdd);
            testCase.verifyEqual(tool.Name, "localAdd");
        end

        %% Display

        function display_showsCorrectProperties(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            output = formattedDisplayText(tool);
            testCase.verifySubstring(output, "Name");
            testCase.verifySubstring(output, "Description");
            testCase.verifySubstring(output, "InputArguments");
            testCase.verifySubstring(output, "OutputArguments");
            testCase.verifySubstring(output, "Workspace");
            testCase.verifySubstring(output, "RequiresApproval");
            testCase.verifySubstring(output, "DisplayTitle");
            testCase.verifySubstring(output, "Annotations");
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

function c = localAdd(a, b)
% localAdd - - - - Add two numbers together.

% Multiple dashes and spaces test that the prefix-stripping regex handles them correctly.
    arguments
        a (1,1) double
        b (1,1) double
    end
    c = a + b;
end

function workspace = singleOutputWorkspace(workspace)
    workspace.called = true;
end

function [c, varargout] = varargoutWorkspace(workspace, a, b)
    c = a + b;
    varargout{1} = workspace;
end
