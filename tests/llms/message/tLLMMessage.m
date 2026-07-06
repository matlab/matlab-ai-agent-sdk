classdef tLLMMessage < matlab.unittest.TestCase
% Tests for aisdk.llms.message.LLMMessage.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function canCreateHeterogeneousArray(testCase)
            msg1 = aisdk.LLMTextMessage("hello");
            msg2 = aisdk.LLMToolCallMessage("myTool", struct(), ToolCallID="tc1");
            arr = [msg1, msg2];
            testCase.verifyLength(arr, 2);
            testCase.verifyClass(arr, 'aisdk.llms.message.LLMMessage');
        end

        function canConcatenateAllSubclasses(testCase)
            user = aisdk.LLMTextMessage("hello");
            assistant = aisdk.LLMTextMessage("hi", Role="assistant");
            toolCall = aisdk.LLMToolCallMessage("myTool", struct("a", 1), ToolCallID="tc1");
            toolResult = aisdk.LLMToolResultMessage("result", ToolCallID="tc1", Name="myTool");
            arr = [user, assistant, toolCall, toolResult];
            testCase.verifyLength(arr, 4);
        end

        function displayScalar_showsTextMessage(testCase)
            msg = aisdk.LLMTextMessage("hello");
            output = formattedDisplayText(msg);
            testCase.verifySubstring(output, "hello");
        end

        function displayArray_showsTextMessages(testCase)
            msgs = [aisdk.LLMTextMessage("hello"), ...
                    aisdk.LLMTextMessage("world", Role="assistant")];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, "hello");
            testCase.verifySubstring(output, "world");
        end

        function roleIsImmutable(testCase)
            msg = aisdk.LLMTextMessage("hello");
            testCase.verifyError(...
                @() iSetRole(msg), "MATLAB:class:SetProhibited");
        end

        function typeIsImmutable(testCase)
            msg = aisdk.LLMTextMessage("hello");
            testCase.verifyError(...
                @() iSetType(msg), "MATLAB:class:SetProhibited");
        end

        function displayArray_toolCallShowsName(testCase)
            toolCall = aisdk.LLMToolCallMessage("myTool", struct(), ToolCallID="tc1");
            msgs = [toolCall, toolCall];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, "myTool");
        end

        function displayArray_toolCallWithArgs_showsArguments(testCase)
            toolCall = aisdk.LLMToolCallMessage("myTool", struct("city", "Cambridge"), ToolCallID="tc1");
            msgs = [toolCall, toolCall];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, 'myTool({"city":"Cambridge"})');
        end

        function displayArray_toolCallEmptyArgs_showsNameOnly(testCase)
            toolCall = aisdk.LLMToolCallMessage("myTool", struct(), ToolCallID="tc1");
            msgs = [toolCall, toolCall];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, """myTool""");
            testCase.verifyThat(output, ...
                ~matlab.unittest.constraints.ContainsSubstring("myTool("));
        end

        function displayArray_toolCallLongArgs_truncates(testCase)
            longVal = repmat('x', 1, 80);
            toolCall = aisdk.LLMToolCallMessage("myTool", struct("key", longVal), ToolCallID="tc1");
            msgs = [toolCall, toolCall];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, "myTool(");
            testCase.verifySubstring(output, "...");
        end

        function contentPreview_truncatesLongContent(testCase)
            longText = repmat('a', 1, 80);
            msg = aisdk.LLMTextMessage(longText);
            msgs = [msg, msg];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, "...");
        end

        function contentPreview_multilineContent_showsOnOneLine(testCase)
            msg = aisdk.LLMTextMessage("line1" + newline + "line2");
            msgs = [msg, msg];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, "line1 line2");
        end

        function contentPreview_emptyString_returnsEmptyQuotes(testCase)
            msg = aisdk.LLMTextMessage("");
            msgs = [msg, msg];
            output = formattedDisplayText(msgs);
            testCase.verifySubstring(output, """""");
        end

        function displayArray_toolRole_showsToolLabel(testCase)
            toolResult = aisdk.LLMToolResultMessage("res", ToolCallID="tc1", Name="myTool");
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
            imgMsg = aisdk.LLMImageMessage(img);
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

