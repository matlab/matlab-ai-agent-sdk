classdef tLLMMessage < matlab.unittest.TestCase
% Tests for aisdk.llms.message.LLMMessage.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        function canCreateHeterogeneousArray(testCase)
            msg1 = aisdk.llms.message.LLMTextMessage("hello", "user");
            msg2 = aisdk.llms.message.LLMToolCallMessage("myTool", struct(), "tc1");
            arr = [msg1, msg2];
            testCase.verifyLength(arr, 2);
            testCase.verifyClass(arr, 'aisdk.llms.message.LLMMessage');
        end

        function canConcatenateAllSubclasses(testCase)
            user = aisdk.llms.message.LLMTextMessage("hello", "user");
            assistant = aisdk.llms.message.LLMTextMessage("hi", "assistant");
            toolCall = aisdk.llms.message.LLMToolCallMessage("myTool", struct("a", 1), "tc1");
            toolResult = aisdk.llms.message.LLMToolResultMessage("result", "myTool", "tc1");
            arr = [user, assistant, toolCall, toolResult];
            testCase.verifyLength(arr, 4);
        end

        function displayDoesNotError(testCase)
            msg = aisdk.llms.message.LLMTextMessage("hello", "user");
            testCase.verifyWarningFree(@() disp(msg));
        end

        function displayArrayDoesNotError(testCase)
            msgs = [aisdk.llms.message.LLMTextMessage("hello", "user"), ...
                    aisdk.llms.message.LLMTextMessage("world", "assistant")];
            testCase.verifyWarningFree(@() disp(msgs));
        end

        function roleIsImmutable(testCase)
            msg = aisdk.llms.message.LLMTextMessage("hello", "user");
            testCase.verifyError(...
                @() iSetRole(msg), "MATLAB:class:SetProhibited");
        end

        function typeIsImmutable(testCase)
            msg = aisdk.llms.message.LLMTextMessage("hello", "user");
            testCase.verifyError(...
                @() iSetType(msg), "MATLAB:class:SetProhibited");
        end

        function contentValidation_rejectsNumeric_throwsError(testCase)
            msg = aisdk.llms.message.LLMTextMessage("hello", "user");
            testCase.verifyError( ...
                @() iSetContent(msg, 42), "llms:message:InvalidContent");
        end

        function contentValidation_rejectsEmptyBrackets(testCase)
            msg = aisdk.llms.message.LLMTextMessage("hello", "user");
            testCase.verifyError( ...
                @() iSetContent(msg, []), "llms:message:InvalidContent");
        end

        function displayArray_toolCallShowsName(testCase)
            toolCall = aisdk.llms.message.LLMToolCallMessage("myTool", struct(), "tc1");
            msgs = [toolCall, toolCall];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, "myTool");
        end

        function contentPreview_truncatesLongContent(testCase)
            longText = repmat('a', 1, 80);
            msg = aisdk.llms.message.LLMTextMessage(longText, "user");
            msgs = [msg, msg];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, "...");
        end

        function contentPreview_multilineContent_showsOnOneLine(testCase)
            msg = aisdk.llms.message.LLMTextMessage("line1" + newline + "line2", "user");
            msgs = [msg, msg];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, "line1 line2");
        end

        function contentPreview_emptyString_returnsEmptyQuotes(testCase)
            msg = aisdk.llms.message.LLMTextMessage("", "user");
            msgs = [msg, msg];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, """""");
        end

        function displayArray_toolRole_showsToolLabel(testCase)
            toolResult = aisdk.llms.message.LLMToolResultMessage("res", "myTool", "tc1");
            msgs = [toolResult, toolResult];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, "Tool");
        end

        function displayArray_unknownRole_showsRawRole(testCase)
            msg = FakeMessage("custom-role", "text");
            msgs = [msg, msg];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, "custom-role");
        end

        function displayArray_imageType_showsImageLabel(testCase)
            img = uint8(randi(255, 4, 4, 3));
            imgMsg = aisdk.llms.message.LLMImageMessage(img, "user");
            msgs = [imgMsg, imgMsg];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, "Image");
        end

        function displayArray_unknownType_showsRawType(testCase)
            msg = FakeMessage("user", "custom-type");
            msgs = [msg, msg];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, "custom-type");
        end
    end

end

function iSetRole(msg)
    msg = subsasgn(msg, substruct('.','Role'), "assistant"); %#ok<NASGU>
end

function iSetType(msg)
    msg = subsasgn(msg, substruct('.','Type'), "tool-call"); %#ok<NASGU>
end

function iSetContent(msg, val)
    msg.Content = val; %#ok<NASGU>
end
