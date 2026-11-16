classdef ttruncateForDisplay < matlab.unittest.TestCase
% Tests for aisdk.internal.truncateForDisplay.

% Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function shortText_isUnchanged(testCase)
            actual = aisdk.internal.truncateForDisplay("hello");

            testCase.verifyEqual(actual, "hello");
        end

        function multilineText_replacesNewlineAndPreservesSurroundingSpaces(testCase)
            text = "first " + newline + " second";

            actual = aisdk.internal.truncateForDisplay(text);

            testCase.verifyEqual(actual, "first   second");
        end

        function textWith60Characters_isUnchanged(testCase)
            text = string(repmat('a', 1, 60));

            actual = aisdk.internal.truncateForDisplay(text);

            testCase.verifyEqual(actual, text);
        end

        function textWith61Characters_keeps60AndAddsEllipsis(testCase)
            text60 = string(repmat('a', 1, 60));

            actual = aisdk.internal.truncateForDisplay(text60 + "b");

            testCase.verifyEqual(actual, text60 + "…");
        end
    end
end
