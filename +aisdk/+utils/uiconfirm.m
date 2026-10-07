function result = uiconfirm(tool, toolArguments)
%uiconfirm GUI callback for AIAgent tool call confirmation.
%   RESULT = uiconfirm(TOOL, TOOLARGUMENTS) opens a modal dialog
%   displaying the tool name and its arguments as pretty-printed JSON. The
%   user can approve, approve-always, or deny the call and optionally
%   provide a message. TOOL is a scalar tool object. RESULT is
%   a struct with fields Approved, Permanent, and Reason. When the tool has
%   ApprovalRequest set to "once", an additional "Always Approve" button is
%   shown that approves the call permanently.
%
%   When MATLAB cannot reach a human at all, uiconfirm throws rather than
%   returning a decision: in -batch mode there is no interactive user, and
%   with no display (-nodisplay, -noFigureWindows, deployed) the dialog
%   cannot open. AIAgent turns that error into a non-permanent denial, so
%   the run continues without blocking. A caller that invokes uiconfirm
%   directly must handle the error itself.
%
%   Copyright 2026 The MathWorks, Inc.

    arguments
        tool          (1,1) aisdk.tool.internal.CallableTool
        toolArguments (1,1) struct
    end

    % Non-interactive automation (-batch): a display may exist but no human
    % is present to answer, and the dialog would block the run.
    if batchStartupOptionUsed
        aisdk.internal.throwError("aisdk:uiconfirm:noUserAvailable");
    end

    dlg = aisdk.internal.ConfirmDialog(tool, toolArguments);
    result = aisdk.internal.awaitApprovalDecision(dlg);
end
