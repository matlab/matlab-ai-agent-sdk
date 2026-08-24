function result = uiconfirm(tool, toolArguments)
%uiconfirm GUI callback for AIAgent tool call confirmation.
%   RESULT = uiconfirm(TOOL, TOOLARGUMENTS) opens a modal dialog
%   displaying the tool name and its arguments as pretty-printed JSON. The
%   user can approve or deny the call and optionally provide a message.
%   TOOL is a scalar aisdk.llms.tool.LLMTool. RESULT is a struct with fields
%   Approved, Permanent, and Reason. When the tool has ApprovalRequest
%   set to "once", an additional "Approve Always" button is shown.
%
%   Copyright 2026 The MathWorks, Inc.

    arguments
        tool          (1,1) aisdk.llms.tool.LLMTool
        toolArguments (1,1) struct
    end

    dlg = aisdk.llms.internal.ConfirmDialog(tool, toolArguments);
    dlg.wait();
    result = dlg.Result;
end
