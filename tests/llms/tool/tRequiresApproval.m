classdef tRequiresApproval < matlab.unittest.TestCase
% Tests for aisdk.llms.tool.RequiresApproval.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        function enumValues_neverAndAlways_areDistinct(testCase)
            testCase.verifyNotEqual(aisdk.llms.tool.RequiresApproval.never, aisdk.llms.tool.RequiresApproval.always);
        end

        function enumValues_neverAndOnce_areDistinct(testCase)
            testCase.verifyNotEqual(aisdk.llms.tool.RequiresApproval.never, aisdk.llms.tool.RequiresApproval.once);
        end

        function enumValues_onceAndAlways_areDistinct(testCase)
            testCase.verifyNotEqual(aisdk.llms.tool.RequiresApproval.once, aisdk.llms.tool.RequiresApproval.always);
        end

        function enumValues_fromString_constructsCorrectly(testCase)
            mode = aisdk.llms.tool.RequiresApproval("never");
            testCase.verifyEqual(mode, aisdk.llms.tool.RequiresApproval.never);
        end
    end

end
