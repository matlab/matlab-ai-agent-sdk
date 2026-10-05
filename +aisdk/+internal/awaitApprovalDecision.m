function result = awaitApprovalDecision(dlg)
%awaitApprovalDecision Block on an approval dialog until it is answered.
%   RESULT = awaitApprovalDecision(DLG) waits for DLG to be answered and
%   returns its Result struct. When the dialog cannot be shown (MATLAB
%   started with -nodisplay / -noFigureWindows, deployed, or otherwise no
%   display), waiting would otherwise block the agent run indefinitely.
%   Instead the failure is raised as an error, which AIAgent turns into a
%   non-permanent denial carrying the underlying message. DLG is any object
%   with a wait() method and Result/Figure properties
%   (aisdk.internal.ConfirmDialog in production).
%
%   Copyright 2026 The MathWorks, Inc.

    % With no display, uiwait warns and then blocks forever. Promote warnings
    % to errors around the wait so it throws at entry instead of hanging.
    oldWarn = warning("error", "MATLAB:hg:NoDisplayNoFigureSupportSeeReleaseNotes");
    restoreWarn = onCleanup(@() warning(oldWarn)); %#ok<NASGU>

    try
        dlg.wait();
    catch err
        if isprop(dlg, "Figure") && ~isempty(dlg.Figure) && all(isvalid(dlg.Figure))
            delete(dlg.Figure);
        end
        rethrow(err);
    end

    result = dlg.Result;
end
