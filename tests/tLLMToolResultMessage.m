classdef tLLMToolResultMessage < matlab.unittest.TestCase
% Tests for aisdk.LLMToolResultMessage.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        function constructorSetsRole(testCase)
            msg = aisdk.LLMToolResultMessage("result", ToolCallID="tc1", Name="myTool");
            testCase.verifyEqual(msg.Role, "tool");
            testCase.verifyEqual(msg.Type, "text");
        end

        function constructorSetsToolCallID(testCase)
            msg = aisdk.LLMToolResultMessage("result", ToolCallID="tc1", Name="myTool");
            testCase.verifyEqual(msg.ToolCallID, "tc1");
        end

        function constructorSetsName(testCase)
            msg = aisdk.LLMToolResultMessage("result", ToolCallID="tc1", Name="myTool");
            testCase.verifyEqual(msg.Name, "myTool");
        end

        function constructorSetsResult(testCase)
            msg = aisdk.LLMToolResultMessage("the result", ToolCallID="tc1", Name="myTool");
            testCase.verifyEqual(msg.Result, "the result");
        end

        function constructorRejectsCharToolCallID(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMToolResultMessage("result", ToolCallID='someId', Name="myTool"), ...
                "llms:message:InvalidToolCallID");
        end

        function settingResult_updatesValue(testCase)
            msg = aisdk.LLMToolResultMessage("ok", ToolCallID="id", Name="n");
            msg.Result = "updated";
            testCase.verifyEqual(msg.Result, "updated");
        end

        function settingName_toNumeric_throwsError(testCase)
            msg = aisdk.LLMToolResultMessage("ok", ToolCallID="id", Name="myTool");
            testCase.verifyError( ...
                @() iSetName(msg, 42), ...
                "MATLAB:validators:mustBeTextScalar");
        end
    end

end

function iSetName(msg, val)
    msg.Name = val; %#ok<NASGU>
end
