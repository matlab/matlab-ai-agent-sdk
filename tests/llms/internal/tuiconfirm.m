classdef tuiconfirm < matlab.uitest.TestCase
% Tests for aisdk.llms.internal.ConfirmDialog and uiconfirm wrapper.

%   Copyright 2026 The MathWorks, Inc.

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

        function onceMode_showsDontAskCheckbox(testCase)
            dlg = makeDialog(testCase, "once");

            testCase.verifyNotEmpty(dlg.DontAskCheckbox);
            testCase.press(dlg.ApproveButton);

            testCase.verifyFalse(dlg.Result.Permanent);
        end

        function dontAskChecked_setsPermanent(testCase)
            dlg = makeDialog(testCase, "once");

            testCase.choose(dlg.DontAskCheckbox, true);
            testCase.press(dlg.ApproveButton);

            testCase.verifyTrue(dlg.Result.Permanent);
        end

        function alwaysMode_hasNoCheckbox(testCase)
            dlg = makeDialog(testCase, "always");

            testCase.verifyEmpty(dlg.DontAskCheckbox);
            testCase.press(dlg.ApproveButton);
        end

        function construction_displaysToolNameAndArguments(testCase)
            tool = aisdk.LLMTool(@(x) x, Name="getWeather", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="number"), ...
                OutputArguments=aisdk.LLMToolArgument("y", DataType="number"), ...
                RequiresApproval="always");
            args = struct("city", "London", "units", "celsius");
            dlg = aisdk.llms.internal.ConfirmDialog(tool, args);

            labels = findall(dlg.Figure, "Type", "uilabel");
            labelTexts = string({labels.Text});
            testCase.verifyTrue(any(labelTexts == "getWeather"));

            ta = findall(dlg.Figure, "Type", "uitextarea");
            areaText = strjoin(ta.Value, newline);
            testCase.verifySubstring(areaText, "London");
            testCase.verifySubstring(areaText, "celsius");

            testCase.press(dlg.ApproveButton);
        end

        function emptyReason_returnsString(testCase)
            dlg = makeDialog(testCase, "always");

            testCase.press(dlg.ApproveButton);

            testCase.verifyClass(dlg.Result.Reason, "string");
        end

        function wrapper_returnsResultStruct(testCase)
            % Shadows ConfirmDialog with a test double from
            % tests/resources/doubles/ that has no UI: wait() is a no-op
            % and Result is struct(Approved=true, Permanent=false, Reason="").
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(fileparts(fileparts(fileparts( ...
                mfilename('fullpath')))), 'resources', 'doubles')));

            tool = aisdk.LLMTool(@(x) x, Name="testTool", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="number"), ...
                OutputArguments=aisdk.LLMToolArgument("y", DataType="number"), ...
                RequiresApproval="always");
            args = struct("x", 1);

            result = aisdk.llms.internal.uiconfirm(tool, args);

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
        RequiresApproval=approvalMode);
    args = struct("x", 1);
    dlg = aisdk.llms.internal.ConfirmDialog(tool, args);
end

