classdef tApprovalRequest < matlab.unittest.TestCase
% Tests for aisdk.llms.tool.ApprovalRequest.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function enumValues_neverAndAlways_areDistinct(testCase)
            testCase.verifyNotEqual(aisdk.llms.tool.ApprovalRequest.never, aisdk.llms.tool.ApprovalRequest.always);
        end

        function enumValues_neverAndOnce_areDistinct(testCase)
            testCase.verifyNotEqual(aisdk.llms.tool.ApprovalRequest.never, aisdk.llms.tool.ApprovalRequest.once);
        end

        function enumValues_onceAndAlways_areDistinct(testCase)
            testCase.verifyNotEqual(aisdk.llms.tool.ApprovalRequest.once, aisdk.llms.tool.ApprovalRequest.always);
        end

        function enumValues_fromString_constructsCorrectly(testCase)
            mode = aisdk.llms.tool.ApprovalRequest("never");
            testCase.verifyEqual(mode, aisdk.llms.tool.ApprovalRequest.never);
        end
    end

end
