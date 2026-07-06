classdef tLLMTool < matlab.unittest.TestCase
% Tests for aisdk.llms.tool.LLMTool.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function selectTool_existingName_returnsTool(testCase)
            tool1 = aisdk.llms.tool.LocalLLMTool(@sin);
            tool2 = aisdk.llms.tool.LocalLLMTool(@cos);
            tools = [tool1, tool2];
            found = tools.selectTool("sin");
            testCase.verifyEqual(found.Name, "sin");
        end

        function selectTool_duplicateNames_returnsFirstMatch(testCase)
            tool1 = aisdk.llms.tool.LocalLLMTool(@sin, Description="First");
            tool2 = aisdk.llms.tool.LocalLLMTool(@sin, "sin", Description="Second");
            tools = [tool1, tool2];
            found = tools.selectTool("sin");
            testCase.verifyEqual(found.Description, "First");
        end

        function selectTool_unknownName_throwsError(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@sin);
            testCase.verifyError(@() tool.selectTool("nonexistent"), ...
                "llms:invalidFunctionCall");
        end

        function concatenation_mixedSubclasses_createsHeterogeneousArray(testCase)
            tool1 = aisdk.llms.tool.LocalLLMTool(@sin);
            tool2 = aisdk.llms.tool.MCPTool();
            tool2.Name = "myTool";
            tools = [tool1, tool2];
            testCase.verifyLength(tools, 2);
            testCase.verifyInstanceOf(tools, "aisdk.llms.tool.LLMTool");
        end

        function selectTool_heterogeneousArray_returnsCorrectSubclass(testCase)
            tool1 = aisdk.llms.tool.LocalLLMTool(@sin);
            tool2 = aisdk.llms.tool.MCPTool();
            tool2.Name = "myTool";
            tools = [tool1, tool2];
            found = tools.selectTool("myTool");
            testCase.verifyEqual(found.Name, "myTool");
            testCase.verifyClass(found, "aisdk.llms.tool.MCPTool");
        end

        function setProperties_validValues_updatesAll(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@sin, Description="Sine");
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
            tool1 = aisdk.llms.tool.LocalLLMTool(@sin, Description="Sine");
            tool2 = aisdk.llms.tool.MCPTool();
            tool2.Name = "mcpTool";
            tools = [tool1, tool2];
            output = formattedDisplayText(tools);
            testCase.verifySubstring(output, "LocalLLMTool");
            testCase.verifySubstring(output, "MCPTool");
        end

        function display_scalarLocalLLMTool_showsNameAndDescription(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@sin, Description="Sine");
            output = formattedDisplayText(tool);
            testCase.verifySubstring(output, "sin");
            testCase.verifySubstring(output, "Sine");
        end

        function display_localLLMTool_showsWorkspaceField(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@sin, Description="Sine");
            output = formattedDisplayText(tool);
            testCase.verifySubstring(output, "Workspace");
        end

        function display_scalarMCPTool_showsNameAndDescription(testCase)
            tool = aisdk.llms.tool.MCPTool();
            tool.Name = "mcpTool";
            tool.Description = "An MCP tool";
            output = formattedDisplayText(tool);
            testCase.verifySubstring(output, "mcpTool");
            testCase.verifySubstring(output, "An MCP tool");
        end
    end

end
