classdef tLLMTextMessage < matlab.unittest.TestCase
% Tests for aisdk.LLMTextMessage.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
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

        function constructorSetsText(testCase)
            msg = aisdk.LLMTextMessage("my question");
            testCase.verifyEqual(msg.Text, "my question");
        end

        function textCanBeEmpty(testCase)
            msg = aisdk.LLMTextMessage("");
            testCase.verifyEqual(msg.Text, "");
        end

        function constructorAcceptsChar_createsMessage(testCase)
            msg = aisdk.LLMTextMessage('hello char');
            testCase.verifyEqual(msg.Text, "hello char");
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

        function constructorRejectsRoleTool_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMTextMessage("result", Role="tool"), ...
                "MATLAB:validators:mustBeMember");
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

        function settingText_toNumeric_throwsError(testCase)
            msg = aisdk.LLMTextMessage("hello");
            testCase.verifyError( ...
                @() iSetText(msg, 42), ...
                "llms:message:InvalidTextContent");
        end

        function settingText_toStringArray_throwsError(testCase)
            msg = aisdk.LLMTextMessage("hello");
            testCase.verifyError( ...
                @() iSetText(msg, ["a","b"]), ...
                "llms:message:InvalidTextContent");
        end
    end

end

function iSetText(msg, val)
    msg.Text = val; %#ok<NASGU>
end
