classdef tLLMTool < matlab.unittest.TestCase
% Tests for the LLMTool factory function.

%   Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addFunctionsToPath(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(fileparts(mfilename("fullpath")), ...
                "resources", "functions")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(fileparts(mfilename("fullpath")), "helpers")));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function createFromFunctionHandle(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers);
            testCase.verifyClass(tool, "aisdk.llms.tool.LocalLLMTool");
            testCase.verifyEqual(tool.Name, "addTwoNumbers");
        end

        function createFromStringErrors(testCase)
            testCase.verifyError(@() aisdk.LLMTool("addTwoNumbers"), ...
                "llms:invalidFunctionDefinition");
        end

        function createFromCharVectorErrors(testCase)
            testCase.verifyError(@() aisdk.LLMTool('addTwoNumbers'), ...
                "llms:invalidFunctionDefinition");
        end

        function passesNameValueThrough(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, Description="Custom desc", ...
                InputArguments=struct("a", 5, "b", 3));
            testCase.verifyEqual(tool.Description, "Custom desc");
            testCase.verifyLength(tool.InputArguments, 2);
            testCase.verifyEqual(tool.InputArguments(1).Name, "a");
        end

        function passesNameOverride(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, "myAdd");
            testCase.verifyEqual(tool.Name, "myAdd");
        end

        function anonymousFunction_positionalName_setsName(testCase)
            tool = aisdk.LLMTool(@(x) x+1, "increment", Description="Add one", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="number"), ...
                OutputArguments=aisdk.LLMToolArgument("result", DataType="number"));
            testCase.verifyEqual(tool.Name, "increment");
        end

        function namedFunction_positionalName_overridesFuncName(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, "customName");
            testCase.verifyEqual(tool.Name, "customName");
        end

        function extractsMetadataAutomatically(testCase)
            tool = aisdk.LLMTool(@addTwoNumbersUsingNVP);
            testCase.verifySubstring(tool.Description, "Add two numbers together");
            testCase.verifyLength(tool.InputArguments, 2);
        end

        function resultIsCallable(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers);
            output = tool.evaluate(struct("a", 3, "b", 4));
            testCase.verifyEqual(output.c, 7);
        end

        function createFromZeroArgFunction(testCase)
            % tempdir: built-in with no input arguments
            tool = aisdk.LLMTool(@tempdir, Description="Get temp directory");
            testCase.verifyClass(tool, "aisdk.llms.tool.LocalLLMTool");
            testCase.verifyEqual(tool.Name, "tempdir");
            testCase.verifyEmpty(tool.InputArguments);
        end

        function errorOnUnrecognizedInput(testCase)
            testCase.verifyError(@() aisdk.LLMTool(42), ...
                "llms:invalidFunctionDefinition");
        end

        function errorWhenNoArgs(testCase)
            testCase.verifyError(@() aisdk.LLMTool(), "MATLAB:minrhs");
        end

        function mcpHTTPClient_extraArguments_errors(testCase)
            mockClient = mcpHTTPClientMock({ ...
                struct("name", "myTool", "description", "desc", "inputSchema", struct())});

            testCase.verifyError( ...
                @() aisdk.LLMTool(mockClient, "extra"), ...
                "MATLAB:TooManyInputs");
        end
    end

end
