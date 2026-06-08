classdef tLLMMessage < matlab.unittest.TestCase
% Tests for the LLMMessage factory function.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        %% User text messages
        function stringDefaultsToTextMessage(testCase)
            msg = aisdk.LLMMessage("hello");
            testCase.verifyClass(msg, "aisdk.llms.message.LLMTextMessage");
            testCase.verifyEqual(msg.Role, "user");
            testCase.verifyEqual(msg.Content, "hello");
        end

        %% Images as MATLAB arrays
        function numericArrayDefaultsToImageMessage(testCase)
            img = uint8(zeros(2,2,3));
            msg = aisdk.LLMMessage(img);
            testCase.verifyClass(msg, "aisdk.llms.message.LLMImageMessage");
            testCase.verifyEqual(msg.Role, "user");
        end

        function logicalArrayDefaultsToImageMessage(testCase)
            img = true(4,4);
            msg = aisdk.LLMMessage(img);
            testCase.verifyClass(msg, "aisdk.llms.message.LLMImageMessage");
        end

        %% Images as file paths or URLs
        function stringWithTypeImageCreatesImageMessage(testCase)
            img = uint8(randi(255,4,4,3));
            f = [tempname, '.png'];
            testCase.addTeardown(@() delete(f));
            imwrite(img, f);

            msg = aisdk.LLMMessage(f, Type="image");
            testCase.verifyClass(msg, "aisdk.llms.message.LLMImageMessage");
        end

        %% Detail name-value pair
        function detailPassedToImageMessage(testCase)
            img = uint8(zeros(2,2,3));
            msg = aisdk.LLMMessage(img, Detail="low");
            testCase.verifyClass(msg, "aisdk.llms.message.LLMImageMessage");
            testCase.verifyEqual(msg.Detail, "low");
        end

        function detailDefaultsToAuto(testCase)
            img = uint8(zeros(2,2,3));
            msg = aisdk.LLMMessage(img);
            testCase.verifyClass(msg, "aisdk.llms.message.LLMImageMessage");
            testCase.verifyEqual(msg.Detail, "auto");
        end

        %% Role name-value pair
        function roleDefaultsToUser(testCase)
            msg = aisdk.LLMMessage("hello");
            testCase.verifyEqual(msg.Role, "user");
        end

        function roleAssistantCreatesAssistantMessage(testCase)
            msg = aisdk.LLMMessage("I am the assistant", Role="assistant");
            testCase.verifyClass(msg, "aisdk.llms.message.LLMTextMessage");
            testCase.verifyEqual(msg.Role, "assistant");
            testCase.verifyEqual(msg.Content, "I am the assistant");
        end

        function roleToolCreatesToolTextMessage(testCase)
            msg = aisdk.LLMMessage("tool output", Role="tool");
            testCase.verifyClass(msg, "aisdk.llms.message.LLMTextMessage");
            testCase.verifyEqual(msg.Role, "tool");
        end

        function roleWithImageType(testCase)
            img = uint8(zeros(2,2,3));
            msg = aisdk.LLMMessage(img, Role="assistant");
            testCase.verifyClass(msg, "aisdk.llms.message.LLMImageMessage");
            testCase.verifyEqual(msg.Role, "assistant");
        end

        %% Default type inference
        function defaultTypeForStringIsText(testCase)
            msg = aisdk.LLMMessage("hello");
            testCase.verifyEqual(msg.Type, "text");
        end

        function defaultTypeForNumericIsImage(testCase)
            img = uint8(zeros(2,2,3));
            msg = aisdk.LLMMessage(img);
            testCase.verifyEqual(msg.Type, "image");
        end

        %% Invalid inputs
        function rejectsInvalidType(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMMessage("hi", Type="invalid"), ...
                "MATLAB:validators:mustBeMember");
        end

        function scalarNumericDoesNotAutoDetectAsImage(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMMessage(3), ...
                "llms:message:InvalidTextContent");
        end

        function rejectsNonStringContentForText(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMMessage(uint8(zeros(2,2,3)), Type="text"), ...
                "llms:message:InvalidTextContent");
        end

        function rejectsInvalidRole(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMMessage("hi", Role="system"), ...
                "MATLAB:validators:mustBeMember");
        end

        %% Tool-call and tool-result construction
        function toolCallViaFactory(testCase)
            msg = aisdk.LLMMessage("", Type="tool-call", Name="myTool", ToolCallID="tc_1", Arguments=struct("x", 1));
            testCase.verifyClass(msg, "aisdk.llms.message.LLMToolCallMessage");
            testCase.verifyEqual(msg.Role, "assistant");
            testCase.verifyEqual(msg.Name, "myTool");
            testCase.verifyEqual(msg.ToolCallID, "tc_1");
            testCase.verifyEqual(msg.Arguments, struct("x", 1));
        end

        function toolResultViaFactory(testCase)
            msg = aisdk.LLMMessage("result text", Type="tool-result", Name="myTool", ToolCallID="tc_1");
            testCase.verifyClass(msg, "aisdk.llms.message.LLMToolResultMessage");
            testCase.verifyEqual(msg.Role, "tool");
            testCase.verifyEqual(msg.Content, "result text");
            testCase.verifyEqual(msg.Name, "myTool");
            testCase.verifyEqual(msg.ToolCallID, "tc_1");
        end

        function charInputDefaultsToTextMessage(testCase)
            msg = aisdk.LLMMessage('hello char');
            testCase.verifyClass(msg, "aisdk.llms.message.LLMTextMessage");
            testCase.verifyEqual(msg.Content, "hello char");
        end

        function explicitTypeText_createsTextMessage(testCase)
            msg = aisdk.LLMMessage("hello", Type="text");
            testCase.verifyClass(msg, "aisdk.llms.message.LLMTextMessage");
            testCase.verifyEqual(msg.Content, "hello");
        end

    end

end
