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

        function constructorSetsContent(testCase)
            msg = aisdk.LLMToolResultMessage("the result", ToolCallID="tc1", Name="myTool");
            testCase.verifyEqual(msg.Content, "the result");
        end

        function constructorRejectsCharToolCallID(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMToolResultMessage("result", ToolCallID='someId', Name="myTool"), ...
                "llms:message:InvalidToolCallID");
        end
    end

end
