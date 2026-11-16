classdef tformatPreview < matlab.unittest.TestCase
% Tests for aisdk.internal.formatPreview.

% Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function proseWithWhitespace_isCollapsedAndTrimmed(testCase)
            text = "  First  " + newline + char(9) + "  Next  ";

            actual = aisdk.internal.formatPreview(text);

            testCase.verifyEqual(actual, "First Next");
        end

        function longProse_isNormalizedBeforeTruncation(testCase)
            text60 = string(repmat('a', 1, 60));

            actual = aisdk.internal.formatPreview("  " + text60 + "b  ");

            testCase.verifyEqual(actual, text60 + "…");
        end
    end
end
