classdef tApprovalRequest < matlab.unittest.TestCase
% Tests for aisdk.tool.ApprovalRequest.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function enumValues_neverAndAlways_areDistinct(testCase)
            testCase.verifyNotEqual(aisdk.tool.ApprovalRequest.never, aisdk.tool.ApprovalRequest.always);
        end

        function enumValues_neverAndOnce_areDistinct(testCase)
            testCase.verifyNotEqual(aisdk.tool.ApprovalRequest.never, aisdk.tool.ApprovalRequest.once);
        end

        function enumValues_onceAndAlways_areDistinct(testCase)
            testCase.verifyNotEqual(aisdk.tool.ApprovalRequest.once, aisdk.tool.ApprovalRequest.always);
        end

        function enumValues_fromString_constructsCorrectly(testCase)
            mode = aisdk.tool.ApprovalRequest("never");
            testCase.verifyEqual(mode, aisdk.tool.ApprovalRequest.never);
        end
    end

end
