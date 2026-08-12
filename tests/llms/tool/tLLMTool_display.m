classdef tLLMTool_display < matlab.unittest.TestCase
% Tests for LLMTool non-scalar display.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function array_showsHeaderWithDimensions(testCase)
            tools = [iLocalTool("a"), iLocalTool("b"), iLocalTool("c")];
            output = formattedDisplayText(tools);
            expected = aisdk.llms.internal.MessageCatalog.getMessage( ...
                "llms:tool:arrayHeader", "1×3");
            testCase.verifySubstring(output, expected);
        end

        function heterogeneous_omitsCallableToolHeader(testCase)
            tools = [iLocalTool("myLocal"), iMCPTool("myMCP")];
            output = formattedDisplayText(tools);
            expected = aisdk.llms.internal.MessageCatalog.getMessage( ...
                "llms:tool:arrayHeader", "1×2");
            testCase.verifySubstring(output, expected);
            testCase.verifyThat(output, ...
                ~matlab.unittest.constraints.ContainsSubstring("CallableTool"));
            testCase.verifyThat(output, ...
                ~matlab.unittest.constraints.ContainsSubstring("heterogeneous"));
        end

        function zeroArgs_showsEmptyParentheses(testCase)
            tools = [iLocalTool("noArgs"), iLocalTool("noArgs")];
            output = formattedDisplayText(tools);
            testCase.verifySubstring(output, "noArgs()");
        end

        function signature_showsRequiredAndOptional(testCase)
            args = [aisdk.LLMToolArgument("query"), ...
                    aisdk.LLMToolArgument("limit", Required=false)];
            tool = aisdk.llms.tool.LocalLLMTool(@pwd, Name="search", ...
                Description="Search", InputArguments=args);
            output = formattedDisplayText([tool, tool]);
            testCase.verifySubstring(output, "query");
            testCase.verifySubstring(output, "<limit>");
        end

        function signature_showsNameValueStyle(testCase)
            args = aisdk.LLMToolArgument("verbose", NameValue=true);
            tool = aisdk.llms.tool.LocalLLMTool(@pwd, Name="myTool", ...
                Description="A tool", InputArguments=args);
            output = formattedDisplayText([tool, tool]);
            testCase.verifySubstring(output, "Name=Value");
        end

        function manyArgs_truncatesWithEllipsis(testCase)
            args = [aisdk.LLMToolArgument("firstName"), ...
                    aisdk.LLMToolArgument("secondName"), ...
                    aisdk.LLMToolArgument("thirdName"), ...
                    aisdk.LLMToolArgument("fourthName"), ...
                    aisdk.LLMToolArgument("fifthName")];
            tool = aisdk.llms.tool.LocalLLMTool(@pwd, Name="myTool", ...
                Description="A tool", InputArguments=args);
            output = formattedDisplayText([tool, tool]);
            testCase.verifySubstring(output, ...
                "myTool(firstName, secondName, thirdName, fourthName, fifthN…)");
        end

        function mcpTool_showsEllipsisSignature(testCase)
            tools = [iMCPTool("evalCode"), iMCPTool("evalCode")];
            output = formattedDisplayText(tools);
            testCase.verifySubstring(output, "evalCode(…)");
        end

        function longDescription_truncatesAt60Chars(testCase)
            longDesc = repmat('x', 1, 80);
            tool = aisdk.llms.tool.LocalLLMTool(@pwd, Name="longTool", ...
                Description=longDesc);
            output = formattedDisplayText([tool, tool]);
            testCase.verifySubstring(output, ...
                repmat('x', 1, 60) + "…");
        end

        function borderlineDescription_notTruncated(testCase)
            desc61 = repmat('y', 1, 61);
            tool = aisdk.llms.tool.LocalLLMTool(@pwd, Name="borderline", ...
                Description=desc61);
            output = formattedDisplayText([tool, tool]);
            testCase.verifySubstring(output, desc61);
            testCase.verifyThat(output, ...
                ~matlab.unittest.constraints.ContainsSubstring("…"));
        end

        function descriptionWithNewline_showsOnOneLine(testCase)
            tool = aisdk.llms.tool.LocalLLMTool(@pwd, Name="multiline", ...
                Description="Line one" + newline + "Line two");
            output = formattedDisplayText([tool, tool]);
            testCase.verifySubstring(output, "Line one Line two");
        end

        function longArgs_truncatesAndClosesParenthesis(testCase)
            args = [aisdk.LLMToolArgument("thisIsAVeryLongArgumentNameThatExceedsFortyChars"), ...
                    aisdk.LLMToolArgument("b")];
            tool = aisdk.llms.tool.LocalLLMTool(@pwd, Name="wideTool", ...
                Description="Wide", InputArguments=args);
            output = formattedDisplayText([tool, tool]);
            testCase.verifySubstring(output, ...
                "wideTool(thisIsAVeryLongArgumentNameThatExceedsFortyChars, …)");
        end

        function longToolName_reducesArgBudget(testCase)
            name = "myPackage_mySubpackage_evaluate";
            args = [aisdk.LLMToolArgument("expressionToRun"), ...
                    aisdk.LLMToolArgument("timeout"), ...
                    aisdk.LLMToolArgument("verbose")];
            tool = aisdk.llms.tool.LocalLLMTool(@pwd, Name=name, ...
                Description="Evaluate", InputArguments=args);
            output = formattedDisplayText([tool, tool]);
            testCase.verifySubstring(output, name + "(");
            testCase.verifySubstring(output, "…)");
        end

        function veryLongToolName_showsEllipsisOnly(testCase)
            name = "thisIsAnExtremelyLongToolNameThatExceedsSixtyCharactersTotal";
            args = aisdk.LLMToolArgument("arg1");
            tool = aisdk.llms.tool.LocalLLMTool(@pwd, Name=name, ...
                Description="Long name", InputArguments=args);
            output = formattedDisplayText([tool, tool]);
            testCase.verifySubstring(output, name + "(…)");
        end

        function typeColumn_showsLocalLLMToolOrMCPTool(testCase)
            tools = [iLocalTool("myLocal"), iMCPTool("myMCP")];
            output = formattedDisplayText(tools);
            testCase.verifySubstring(output, "LocalLLMTool");
            testCase.verifySubstring(output, "MCPTool");
        end


        function workspaceColumn_showsNoneOrAgent(testCase)
            localTool = iLocalTool("basic");
            workspaceTool = aisdk.llms.tool.LocalLLMTool(@eig, Name="wsTool", ...
                Description="A tool", Workspace="agent", ...
                InputArguments=aisdk.LLMToolArgument("A", DataType="number"), ...
                OutputArguments=aisdk.LLMToolArgument("V", DataType="number"));
            mcpTool = iMCPTool("remote");
            tools = [localTool, workspaceTool, mcpTool];
            output = formattedDisplayText(tools);
            testCase.verifySubstring(output, '"none"');
            testCase.verifySubstring(output, '"agent"');
        end
    end

end

function tool = iLocalTool(name)
    tool = aisdk.llms.tool.LocalLLMTool(@pwd, Name=name, Description="A tool");
end


function tool = iMCPTool(name)
    tool = aisdk.llms.tool.MCPTool();
    tool.Name = name;
    tool.Description = "An MCP tool";
    tool.DisplayTitle = name;
end
