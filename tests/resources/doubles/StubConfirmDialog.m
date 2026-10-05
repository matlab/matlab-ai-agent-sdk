classdef StubConfirmDialog < handle
% Test double for exercising awaitApprovalDecision without any UI.
%   StubConfirmDialog()            - wait() is a no-op; Result is a fixed
%                                    approval, mimicking an answered dialog.
%   StubConfirmDialog(throwMessage) - wait() throws with throwMessage,
%                                    mimicking a dialog that cannot be shown
%                                    (no display).
%   StubConfirmDialog(throwMessage,figureHandle) - as above, with the
%                                    Figure property set to figureHandle.
%                                    Pass gobjects(0) for a dialog that
%                                    holds no figure.
%   StubConfirmDialog.warningOnWait(id) - wait() issues warning id and
%                                    returns, mimicking the way uiwait
%                                    reports a figure it cannot show. Only
%                                    the caller's warning-to-error
%                                    promotion makes such a wait fail.
% Figure defaults to a live StubDialogFigure, so a test can assert whether
% awaitApprovalDecision deleted it.
% Instantiated directly by tests (not path-shadowing the real class).

%   Copyright 2026 The MathWorks, Inc.

    properties (SetAccess=private)
        Figure
        Result struct = struct("Approved", true, "Permanent", false, "Reason", "answered")
    end

    properties (Access=private)
        ThrowMessage string = string.empty
        WarningIdentifier string = string.empty
    end

    methods
        function this = StubConfirmDialog(throwMessage, figureHandle)
            arguments
                throwMessage string = string.empty
                figureHandle = StubDialogFigure()
            end
            this.ThrowMessage = throwMessage;
            this.Figure = figureHandle;
        end

        function wait(this)
            if ~isempty(this.WarningIdentifier)
                warning(this.WarningIdentifier, ...
                    "uiwait is not supported in this mode.");
            elseif ~isempty(this.ThrowMessage)
                error("aisdk:test:dialogUnavailable", "%s", this.ThrowMessage);
            end
        end
    end

    methods (Static)
        function this = warningOnWait(warningIdentifier)
            arguments
                warningIdentifier (1,1) string
            end
            this = StubConfirmDialog();
            this.WarningIdentifier = warningIdentifier;
        end
    end
end
