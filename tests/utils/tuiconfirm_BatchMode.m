classdef tuiconfirm_BatchMode < matlab.unittest.TestCase
% Tests for the -batch guard in aisdk.utils.uiconfirm. The batch
% branch throws before any dialog is constructed, so these need no graphics
% and run in any release. AIAgent turns the error into a denial; that half
% is covered by the throwing-callback tests in tAIAgent.m.

%   Copyright 2026 The MathWorks, Inc.

    methods (TestMethodSetup)
        function shadowBatchDetection(testCase)
            import matlab.unittest.fixtures.PathFixture
            import matlab.unittest.fixtures.SuppressedWarningsFixture

            % Shadows the batchStartupOptionUsed built-in with a double that
            % reports -batch mode. Applied first, the warning suppression
            % also covers the addpath that raises it.
            testCase.applyFixture( ...
                SuppressedWarningsFixture("MATLAB:dispatcher:nameConflict"));

            doublesDir = fullfile(fileparts(fileparts( ...
                mfilename("fullpath"))), "private", "batch-doubles");
            testCase.applyFixture(PathFixture(doublesDir));

            % Aborts before the test body: without the double, uiconfirm
            % would open a modal dialog and block the run waiting for a
            % human.
            testCase.assertTrue(batchStartupOptionUsed, ...
                "Test double for batchStartupOptionUsed not picked up.");
        end
    end

    methods (Test, TestTags = {'Unit'})
        function batchMode_throwsNoUserAvailable(testCase)
            testCase.verifyError( ...
                @() aisdk.utils.uiconfirm(makeTool, struct("x", 1)), ...
                "aisdk:uiconfirm:noUserAvailable");
        end

        function batchMode_opensNoDialog(testCase)
            before = numel(findall(groot, "Type", "figure"));

            testCase.verifyError( ...
                @() aisdk.utils.uiconfirm(makeTool, struct("x", 1)), ...
                "aisdk:uiconfirm:noUserAvailable");

            testCase.verifyEqual(numel(findall(groot, "Type", "figure")), ...
                before, "The batch guard must not construct a dialog.");
        end
    end
end

function tool = makeTool
    tool = aisdk.LLMTool(@(x) x, Name="testTool", ...
        InputArguments=aisdk.LLMToolArgument("x", DataType="number"), ...
        OutputArguments=aisdk.LLMToolArgument("y", DataType="number"), ...
        ApprovalRequest="always");
end
