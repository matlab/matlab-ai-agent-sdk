classdef tLLMToolResultMessage < matlab.unittest.TestCase
% Tests for aisdk.llms.message.LLMToolResultMessage.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        function constructorSetsRole(testCase)
            msg = aisdk.llms.message.LLMToolResultMessage("result", "myTool", "tc1");
            testCase.verifyEqual(msg.Role, "tool");
            testCase.verifyEqual(msg.Type, "text");
        end

        function constructorSetsToolCallID(testCase)
            msg = aisdk.llms.message.LLMToolResultMessage("result", "myTool", "tc1");
            testCase.verifyEqual(msg.ToolCallID, "tc1");
        end

        function constructorSetsName(testCase)
            msg = aisdk.llms.message.LLMToolResultMessage("result", "myTool", "tc1");
            testCase.verifyEqual(msg.Name, "myTool");
        end

        function constructorSetsContent(testCase)
            msg = aisdk.llms.message.LLMToolResultMessage("the result", "myTool", "tc1");
            testCase.verifyEqual(msg.Content, "the result");
        end

        function constructorAcceptsCharToolCallID(testCase)
            msg = aisdk.llms.message.LLMToolResultMessage("result", "myTool", 'someId');
            testCase.verifyEqual(msg.ToolCallID, "someId");
        end
    end

end
