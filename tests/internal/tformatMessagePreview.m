classdef tformatMessagePreview < matlab.unittest.TestCase
% Tests for aisdk.internal.formatMessagePreview.

% Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function whitespace_preservesSpacesAndShowsLineBreaksAndTabs(testCase)
            % char(13) is carriage return; char(9) is a tab.
            % Include CRLF, LF, and CR line endings.
            text = "  first  " + char(13) + newline + char(9) + ...
                "second" + newline + "third" + char(13) + "last  ";

            actual = aisdk.internal.formatMessagePreview(text);

            testCase.verifyEqual(actual, "  first  ↵\tsecond↵third↵last  ");
        end

        function previewLimit_countsVisibleMarkers(testCase)
            text59 = string(repmat('a', 1, 59));

            actual = aisdk.internal.formatMessagePreview(text59 + newline + "b");

            testCase.verifyEqual(actual, text59 + "↵…");
        end
    end
end
