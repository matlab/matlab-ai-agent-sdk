classdef tLLMTool < matlab.unittest.TestCase
% Tests for aisdk.llms.tool.LLMTool.

%   Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addFunctionsToPath(testCase)
            testsRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testsRoot, "resources", "functions")));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function select_existingName_returnsTool(testCase)
            tool1 = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            tool2 = aisdk.llms.tool.LocalLLMTool(@greetUser);
            tools = [tool1, tool2];
            found = tools.select("addTwoNumbers");
            testCase.verifyEqual(found.Name, "addTwoNumbers");
        end

        function select_duplicateNames_returnsFirstMatch(testCase)
            tool1 = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, Description="First");
            tool2 = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers, Description="Second");
            tools = [tool1, tool2];
            found = tools.select("addTwoNumbers");
            testCase.verifyEqual(found.Description, "First");
        end

        function select_unknownName_throwsError(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            testCase.verifyError(@() tool.select("nonexistent"), ...
                "llms:invalidFunctionCall");
        end

        function concatenation_mixedSubclasses_createsHeterogeneousArray(testCase)
            tool1 = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            tool2 = aisdk.llms.tool.MCPTool();
            tool2.Name = "myTool";
            tools = [tool1, tool2];
            testCase.verifyLength(tools, 2);
            testCase.verifyInstanceOf(tools, "aisdk.llms.tool.LLMTool");
        end

        function select_heterogeneousArray_returnsCorrectSubclass(testCase)
            tool1 = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            tool2 = aisdk.llms.tool.MCPTool();
            tool2.Name = "myTool";
            tools = [tool1, tool2];
            found = tools.select("myTool");
            testCase.verifyEqual(found.Name, "myTool");
            testCase.verifyClass(found, "aisdk.llms.tool.MCPTool");
        end

        function setProperties_validValues_updatesAll(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            tool.Name = "renamed";
            tool.DisplayTitle = "My Title";
            tool.Description = "New desc";
            tool.Annotations = struct("key", "value");
            testCase.verifyEqual(tool.Name, "renamed");
            testCase.verifyEqual(tool.DisplayTitle, "My Title");
            testCase.verifyEqual(tool.Description, "New desc");
            testCase.verifyEqual(tool.Annotations.key, "value");
        end

        function display_heterogeneousArray_showsAllSubclassTypes(testCase)
            tool1 = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            tool2 = aisdk.llms.tool.MCPTool();
            tool2.Name = "mcpTool";
            tools = [tool1, tool2];
            output = formattedDisplayText(tools);
            testCase.verifySubstring(output, "LocalLLMTool");
            testCase.verifySubstring(output, "MCPTool");
        end

        function display_heterogeneousArray_showsTableColumns(testCase)
            tool1 = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
            tool2 = aisdk.llms.tool.MCPTool();
            tool2.Name = "mcpTool";
            tools = [tool1, tool2];
            output = formattedDisplayText(tools);
            testCase.verifySubstring(output, "Syntax");
            testCase.verifySubstring(output, "Description");
            testCase.verifySubstring(output, "Type");
            testCase.verifySubstring(output, "Workspace");
            cs = @matlab.unittest.constraints.ContainsSubstring;
            testCase.verifyThat(output, ~cs("InputArguments"));
            testCase.verifyThat(output, ~cs("OutputArguments"));
            testCase.verifyThat(output, ~cs("InputSchema"));
            testCase.verifyThat(output, ~cs("OutputSchema"));
        end
    end

end
