classdef tLLMMessage_display < matlab.unittest.TestCase
% Tests for LLMMessage array display.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function array_withTwoDimensions_usesCatalogHeader(testCase)
            msg = aisdk.LLMTextMessage("hello");
            messages = reshape([msg, msg, msg, msg], 2, 2);

            output = formattedDisplayText(messages);
            expected = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:message:arrayHeader", "2×2");

            testCase.verifySubstring(output, expected);
        end

        function array_atPreviewLimit_truncatesOnlyLongerText(testCase)
            text60 = string(repmat('a', 1, 60));
            text61 = text60 + "b";
            msg60 = aisdk.LLMTextMessage(text60);
            msg61 = aisdk.LLMTextMessage(text61);

            output = formattedDisplayText([msg60, msg61]);

            testCase.verifySubstring(output, '"' + text60 + '"');
            testCase.verifySubstring(output, '"' + text60 + '…"');
            testCase.verifyThat(output, ...
                ~matlab.unittest.constraints.ContainsSubstring(text61));
        end

        function array_withMarkdownToolResult_preservesSpacingAndShowsLineBreak(testCase)
            original = "Best Practices  " + newline + "  Next step";
            msg = aisdk.LLMToolResultMessage(original);

            output = formattedDisplayText([msg, msg]);

            testCase.verifySubstring(output, '"Best Practices  ↵  Next step"');
            testCase.verifyEqual(msg.Result, original);
        end
    end
end
