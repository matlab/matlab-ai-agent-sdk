classdef tawaitApprovalDecision < matlab.unittest.TestCase
% Tests for aisdk.internal.awaitApprovalDecision — the no-display
% guard around an approval dialog. No graphics required: the dialog is a
% directly-instantiated stub, so these run in any release and headlessly.

%   Copyright 2026 The MathWorks, Inc.

    properties (Constant)
        NoDisplayWarning = "MATLAB:hg:NoDisplayNoFigureSupportSeeReleaseNotes"
    end

    methods (TestClassSetup)
        function addDoubles(testCase)
            doublesDir = fullfile(fileparts(fileparts( ...
                mfilename("fullpath"))), "resources", "doubles");
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture(doublesDir));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function dialogAnswered_returnsDialogResult(testCase)
            dlg = StubConfirmDialog();

            result = aisdk.internal.awaitApprovalDecision(dlg);

            testCase.verifyEqual(result, dlg.Result);
        end

        function dialogCannotBeShown_throws(testCase)
            dlg = StubConfirmDialog("no display available");

            testCase.verifyError(@() aisdk.internal.awaitApprovalDecision(dlg), ...
                "aisdk:test:dialogUnavailable");
        end

        function dialogCannotBeShown_deletesFigure(testCase)
            % A dialog that cannot be shown is never answered, so its
            % figure must not be left behind once the wait has failed.
            dlg = StubConfirmDialog("no display available");
            fig = dlg.Figure;
            testCase.assertTrue(isvalid(fig));

            testCase.verifyError(@() aisdk.internal.awaitApprovalDecision(dlg), ...
                "aisdk:test:dialogUnavailable");

            testCase.verifyFalse(isvalid(fig), ...
                "The doomed figure must be deleted before the error propagates.");
        end

        function dialogAnswered_doesNotDeleteFigureItself(testCase)
            % Deleting the figure belongs to the failure path only. The real
            % dialog closes its own window before wait() returns (covered in
            % tuiconfirm), and this stub deliberately leaves its figure open,
            % so a figure still alive here means awaitApprovalDecision did
            % not delete one it does not own.
            dlg = StubConfirmDialog();

            aisdk.internal.awaitApprovalDecision(dlg);

            testCase.verifyTrue(isvalid(dlg.Figure), ...
                "The success path must not delete the dialog's figure.");
        end

        function warningDuringWait_isPromotedToError(testCase)
            % The fail-safe rests on the promotion, not on the dialog: a
            % wait that only warns must still fail the call. The ambient
            % state is forced to "off" first, so the promotion is the only
            % thing that can turn the warning into an error.
            testCase.setNoDisplayWarning("off");
            dlg = StubConfirmDialog.warningOnWait(testCase.NoDisplayWarning);

            testCase.verifyError( ...
                @() aisdk.internal.awaitApprovalDecision(dlg), ...
                testCase.NoDisplayWarning);

            testCase.verifyFalse(isvalid(dlg.Figure), ...
                "A promoted warning takes the same cleanup path as a throw.");
        end

        function dialogWithoutFigure_rethrowsWithoutErroringInGuard(testCase)
            % A dialog that holds no figure must still surface its own
            % failure rather than one raised by the cleanup guard.
            dlg = StubConfirmDialog("no display available", gobjects(0));

            testCase.verifyError(@() aisdk.internal.awaitApprovalDecision(dlg), ...
                "aisdk:test:dialogUnavailable");
        end

        function answeredDialog_restoresWarningState(testCase)
            testCase.setNoDisplayWarning("off");

            aisdk.internal.awaitApprovalDecision(StubConfirmDialog());

            testCase.verifyEqual(testCase.noDisplayWarningState(), "off", ...
                "Promoting the warning to an error must not outlive the wait.");
        end

        function thrownDialog_restoresWarningState(testCase)
            testCase.setNoDisplayWarning("off");
            dlg = StubConfirmDialog("no display available");

            testCase.verifyError(@() aisdk.internal.awaitApprovalDecision(dlg), ...
                "aisdk:test:dialogUnavailable");

            testCase.verifyEqual(testCase.noDisplayWarningState(), "off", ...
                "The error path must restore the warning state too.");
        end
    end

    methods (Access=private)
        function setNoDisplayWarning(testCase, state)
            original = warning("query", testCase.NoDisplayWarning);
            testCase.addTeardown(@() warning(original));
            warning(state, testCase.NoDisplayWarning);
        end

        function state = noDisplayWarningState(testCase)
            current = warning("query", testCase.NoDisplayWarning);
            state = string(current.state);
        end
    end
end
