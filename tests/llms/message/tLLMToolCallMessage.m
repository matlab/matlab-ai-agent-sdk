classdef tLLMToolCallMessage < matlab.unittest.TestCase
% Tests for aisdk.llms.message.LLMToolCallMessage.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        function constructorSetsRole(testCase)
            msg = aisdk.llms.message.LLMToolCallMessage("myTool", struct(), "tc1");
            testCase.verifyEqual(msg.Role, "assistant");
            testCase.verifyEqual(msg.Type, "tool-call");
        end

        function constructorSetsName(testCase)
            msg = aisdk.llms.message.LLMToolCallMessage("myTool", struct(), "tc1");
            testCase.verifyEqual(msg.Name, "myTool");
        end

        function constructorSetsToolCallID(testCase)
            msg = aisdk.llms.message.LLMToolCallMessage("myTool", struct(), "tc1");
            testCase.verifyEqual(msg.ToolCallID, "tc1");
        end

        function constructorSetsArguments(testCase)
            args = struct("x", 1, "y", "hello");
            msg = aisdk.llms.message.LLMToolCallMessage("myTool", args, "tc1");
            testCase.verifyEqual(msg.Arguments, args);
        end

        function argumentsDefaultsToEmptyStruct(testCase)
            msg = aisdk.llms.message.LLMToolCallMessage("myTool", struct(), "tc1");
            testCase.verifyEqual(msg.Arguments, struct());
        end

        function constructorAcceptsCharToolCallID(testCase)
            msg = aisdk.llms.message.LLMToolCallMessage("myTool", struct(), 'someId');
            testCase.verifyEqual(msg.ToolCallID, "someId");
        end

        function constructorRejectsEmptyName(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.message.LLMToolCallMessage("", struct(), "tc1"), ...
                "MATLAB:validators:mustBeNonzeroLengthText");
        end

        function contentDefault_returnsEmpty(testCase)
            msg = aisdk.llms.message.LLMToolCallMessage("myTool", struct(), "tc1");
            testCase.verifyEqual(msg.Content, []);
        end

        function displayScalar_showsToolName(testCase)
            msg = aisdk.llms.message.LLMToolCallMessage("myTool", struct(), "tc1");
            output = formattedDisplayText(msg);
            testCase.verifySubstring(output, "myTool");
        end

        function displayScalar_emptyArgs_showsNoJson(testCase)
            msg = aisdk.llms.message.LLMToolCallMessage("myTool", struct(), "tc1");
            output = formattedDisplayText(msg);
            testCase.verifyThat(output, ...
                ~matlab.unittest.constraints.ContainsSubstring("{"));
        end

        function displayScalar_withArgs_showsJsonArgs(testCase)
            msg = aisdk.llms.message.LLMToolCallMessage("myTool", struct("x", 1), "tc1");
            output = formattedDisplayText(msg);
            testCase.verifySubstring(output, """x"":1");
        end
    end

end
