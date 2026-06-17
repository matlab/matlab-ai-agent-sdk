classdef tLLMTextMessage < matlab.unittest.TestCase
% Tests for aisdk.LLMTextMessage.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        function constructorSetsRoleUser(testCase)
            msg = aisdk.LLMTextMessage("hello", Role="user");
            testCase.verifyEqual(msg.Role, "user");
        end

        function constructorDefaultsToUserRole(testCase)
            msg = aisdk.LLMTextMessage("hello");
            testCase.verifyEqual(msg.Role, "user");
        end

        function constructorSetsRoleAssistant(testCase)
            msg = aisdk.LLMTextMessage("hello", Role="assistant");
            testCase.verifyEqual(msg.Role, "assistant");
        end

        function constructorSetsType(testCase)
            msg = aisdk.LLMTextMessage("hello");
            testCase.verifyEqual(msg.Type, "text");
        end

        function constructorSetsContent(testCase)
            msg = aisdk.LLMTextMessage("my question");
            testCase.verifyEqual(msg.Content, "my question");
        end

        function contentCanBeEmpty(testCase)
            msg = aisdk.LLMTextMessage("");
            testCase.verifyEqual(msg.Content, "");
        end

        function constructorAcceptsChar_createsMessage(testCase)
            msg = aisdk.LLMTextMessage('hello char');
            testCase.verifyEqual(msg.Content, "hello char");
        end

        function constructorRejectsNonScalarStringArray_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMTextMessage(["a","b"]), ...
                "llms:message:InvalidTextContent");
        end

        function constructorRejectsNumericContent_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMTextMessage(123), ...
                "llms:message:InvalidTextContent");
        end

        function constructorAcceptsRoleTool_setsRole(testCase)
            msg = aisdk.LLMTextMessage("result", Role="tool");
            testCase.verifyEqual(msg.Role, "tool");
        end

        function constructorAcceptsRoleSystem_setsRole(testCase)
            msg = aisdk.LLMTextMessage("hello", Role="system");
            testCase.verifyEqual(msg.Role, "system");
        end

        function constructorRejectsInvalidRole_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMTextMessage("hello", Role="developer"), ...
                "MATLAB:validators:mustBeMember");
        end
    end

end
