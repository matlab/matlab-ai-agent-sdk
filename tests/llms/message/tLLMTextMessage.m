classdef tLLMTextMessage < matlab.unittest.TestCase
% Tests for aisdk.llms.message.LLMTextMessage.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        function constructorSetsRoleUser(testCase)
            msg = aisdk.llms.message.LLMTextMessage("hello", "user");
            testCase.verifyEqual(msg.Role, "user");
        end

        function constructorSetsRoleAssistant(testCase)
            msg = aisdk.llms.message.LLMTextMessage("hello", "assistant");
            testCase.verifyEqual(msg.Role, "assistant");
        end

        function constructorSetsType(testCase)
            msg = aisdk.llms.message.LLMTextMessage("hello", "user");
            testCase.verifyEqual(msg.Type, "text");
        end

        function constructorSetsContent(testCase)
            msg = aisdk.llms.message.LLMTextMessage("my question", "user");
            testCase.verifyEqual(msg.Content, "my question");
        end

        function contentCanBeEmpty(testCase)
            msg = aisdk.llms.message.LLMTextMessage("", "user");
            testCase.verifyEqual(msg.Content, "");
        end

        function constructorAcceptsChar_createsMessage(testCase)
            msg = aisdk.llms.message.LLMTextMessage('hello char', "user");
            testCase.verifyEqual(msg.Content, "hello char");
        end

        function constructorRejectsNonScalarStringArray_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.message.LLMTextMessage(["a","b"], "user"), ...
                "llms:message:InvalidTextContent");
        end

        function constructorRejectsNumericContent_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.message.LLMTextMessage(123, "user"), ...
                "llms:message:InvalidTextContent");
        end

        function constructorAcceptsRoleTool_setsRole(testCase)
            msg = aisdk.llms.message.LLMTextMessage("result", "tool");
            testCase.verifyEqual(msg.Role, "tool");
        end

        function constructorRejectsInvalidRole_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.message.LLMTextMessage("hello", "system"), ...
                "MATLAB:validators:mustBeMember");
        end
    end

end
