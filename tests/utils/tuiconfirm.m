classdef tuiconfirm < matlab.uitest.TestCase
% Tests for aisdk.internal.ConfirmDialog and the
% aisdk.utils.uiconfirm wrapper around it.

%   Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function requiresUpdatedGraphics(testCase)
            testCase.assumeFalse( ...
                isMATLABReleaseOlderThan("R2026b"), ...
                "MATLABWindow exited Unexpected in TeamCity.");
        end
    end

    methods (Test, TestTags = {'Unit'})
        function approveButton_approvesNonPermanently(testCase)
            dlg = makeDialog(testCase, "always");

            testCase.press(dlg.ApproveButton);

            testCase.verifyTrue(dlg.Result.Approved);
            testCase.verifyFalse(dlg.Result.Permanent);
            testCase.verifyEqual(dlg.Result.Reason, "");
        end

        function denyButton_deniesNonPermanently(testCase)
            dlg = makeDialog(testCase, "always");

            testCase.press(dlg.DenyButton);

            testCase.verifyFalse(dlg.Result.Approved);
            testCase.verifyFalse(dlg.Result.Permanent);
        end

        function hitEscape_deniesNonPermanently(testCase)
            dlg = makeDialog(testCase, "always");

            evt = struct("Key", "escape");
            dlg.Figure.KeyPressFcn(dlg.Figure, evt);

            testCase.verifyFalse(dlg.Result.Approved);
            testCase.verifyFalse(dlg.Result.Permanent);
        end

        function nonEmptyReason_includedInResult(testCase)
            dlg = makeDialog(testCase, "always");

            testCase.type(dlg.ReasonField, "not safe");
            testCase.press(dlg.DenyButton);

            testCase.verifyEqual(dlg.Result.Reason, "not safe");
        end

        function multilineReason_joinedWithNewlines(testCase)
            dlg = makeDialog(testCase, "always");

            % The feedback box is a multi-line uitextarea, whose Value is a
            % cell array with one char row per line.
            dlg.ReasonField.Value = {'first line'; 'second line'};
            testCase.press(dlg.ApproveButton);

            testCase.verifyClass(dlg.Result.Reason, "string");
            testCase.verifyEqual(dlg.Result.Reason, ...
                "first line" + newline + "second line");
        end

        function onceMode_showsApproveAlwaysButton(testCase)
            dlg = makeDialog(testCase, "once");

            testCase.verifyNotEmpty(dlg.ApproveAlwaysButton);
            testCase.press(dlg.ApproveButton);

            testCase.verifyFalse(dlg.Result.Permanent);
        end

        function approveAlways_setsPermanent(testCase)
            dlg = makeDialog(testCase, "once");

            testCase.press(dlg.ApproveAlwaysButton);

            testCase.verifyTrue(dlg.Result.Approved);
            testCase.verifyTrue(dlg.Result.Permanent);
        end

        function defaultButton_isDeny(testCase)
            dlg = makeDialog(testCase, "once");

            focused = dlg.focusDefaultButton();

            testCase.verifySameHandle(focused, dlg.DenyButton, ...
                "Deny must take the initial keyboard focus.");
        end

        function alwaysMode_hasNoApproveAlwaysButton(testCase)
            dlg = makeDialog(testCase, "always");

            testCase.verifyEmpty(dlg.ApproveAlwaysButton);
            testCase.press(dlg.ApproveButton);
        end

        function construction_displaysToolNameAndArguments(testCase)
            tool = aisdk.LLMTool(@(x) x, Name="getWeather", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="number"), ...
                OutputArguments=aisdk.LLMToolArgument("y", DataType="number"), ...
                ApprovalRequest="always");
            args = struct("city", "London", "units", "celsius");
            dlg = aisdk.internal.ConfirmDialog(tool, args);

            labels = findall(dlg.Figure, "Type", "uilabel");
            labelTexts = string({labels.Text});
            testCase.verifyTrue(any(labelTexts == "getWeather"));

            areaText = strjoin(dlg.ArgumentsArea.Value, newline);
            testCase.verifySubstring(areaText, "London");
            testCase.verifySubstring(areaText, "celsius");

            testCase.press(dlg.ApproveButton);
        end

        function construction_headerUsesDisplayTitle(testCase)
            tool = aisdk.LLMTool(@(x) x, Name="getWeather", ...
                DisplayTitle="Get the weather", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="number"), ...
                OutputArguments=aisdk.LLMToolArgument("y", DataType="number"), ...
                ApprovalRequest="always");
            dlg = aisdk.internal.ConfirmDialog(tool, struct("x", 1));

            labels = findall(dlg.Figure, "Type", "uilabel");
            labelTexts = string({labels.Text});
            testCase.verifyTrue(any(contains(labelTexts, "Get the weather")), ...
                "Header should display the tool's DisplayTitle.");

            testCase.press(dlg.ApproveButton);
        end

        function answeredDialog_closesItsFigure(testCase)
            dlg = makeDialog(testCase, "always");
            fig = dlg.Figure;
            testCase.assertTrue(isvalid(fig));

            testCase.press(dlg.ApproveButton);

            testCase.verifyFalse(isvalid(fig), ...
                "Answering the dialog must close its window.");
        end

        function emptyReason_returnsString(testCase)
            dlg = makeDialog(testCase, "always");

            testCase.press(dlg.ApproveButton);

            testCase.verifyClass(dlg.Result.Reason, "string");
        end

        function wrapper_returnsResultStruct(testCase)
            testCase.assumeFail("Test double not picked up correctly.");

            % Shadows ConfirmDialog with a test double from
            % tests/resources/doubles/ that has no UI: wait() is a no-op
            % and Result is struct(Approved=true, Permanent=false, Reason="").
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(fileparts(fileparts( ...
                mfilename('fullpath'))), 'resources', 'doubles')));

            tool = aisdk.LLMTool(@(x) x, Name="testTool", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="number"), ...
                OutputArguments=aisdk.LLMToolArgument("y", DataType="number"), ...
                ApprovalRequest="always");
            args = struct("x", 1);

            result = aisdk.utils.uiconfirm(tool, args);

            testCase.verifyTrue(isstruct(result));
            testCase.verifyTrue(result.Approved);
            testCase.verifyFalse(result.Permanent);
            testCase.verifyClass(result.Reason, "string");
        end
    end
end

function dlg = makeDialog(testCase, approvalMode)
    tool = aisdk.LLMTool(@(x) x, Name="testTool", ...
        InputArguments=aisdk.LLMToolArgument("x", DataType="number"), ...
        OutputArguments=aisdk.LLMToolArgument("y", DataType="number"), ...
        ApprovalRequest=approvalMode);
    args = struct("x", 1);
    dlg = aisdk.internal.ConfirmDialog(tool, args);

    % Answering the dialog closes its own figure; this catches the tests
    % that leave it open.
    testCase.addTeardown(@() closeIfOpen(dlg.Figure));
end

function closeIfOpen(fig)
    if isvalid(fig)
        delete(fig)
    end
end

