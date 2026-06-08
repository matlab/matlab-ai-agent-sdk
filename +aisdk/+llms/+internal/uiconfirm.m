function result = uiconfirm(tool, toolArguments)
%uiconfirm GUI callback for AIAgent tool call confirmation.
%   RESULT = uiconfirm(TOOL, TOOLARGUMENTS) opens a modal dialog
%   displaying the tool name and its arguments as pretty-printed JSON. The
%   user can approve or deny the call and optionally provide a message.
%   TOOL is a scalar aisdk.llms.tool.LLMTool. RESULT is a struct with fields
%   Approved, Permanent, and Reason. When the tool has RequiresApproval
%   set to "once", an additional "Approve Always" button is shown.
%
%   Copyright 2026 The MathWorks, Inc.

    arguments
        tool          (1,1) aisdk.llms.tool.LLMTool
        toolArguments (1,1) struct
    end

    toolName = tool.Name;
    showAlwaysOption = (tool.RequiresApproval == "once");

    argsJson = jsonencode(toolArguments, PrettyPrint=true);

    fig = uifigure("Name", "AI Agent", ...
        "WindowStyle", "normal", ...
        "Position", [100 100 420 270], ...
        "Resize", "off");
    movegui(fig, "center");

    if showAlwaysOption
        rowHeights = {'fit', 22, '1x', 22, 22, 30};
    else
        rowHeights = {'fit', 22, '1x', 22, 30};
    end

    gl = uigridlayout(fig, ...
        "RowHeight", rowHeights, ...
        "ColumnWidth", {80, '1x'}, ...
        "ColumnSpacing", 10, ...
        "Padding", [15 15 15 15]);

    headerLabel = uilabel(gl, ...
        "Text", "The agent wants to execute a tool call. Would you like to proceed?", ...
        "FontWeight", "bold", ...
        "WordWrap", "on");
    headerLabel.Layout.Row = 1;
    headerLabel.Layout.Column = [1 2];

    toolNameLabel = uilabel(gl, ...
        "Text", "Name", ...
        "VerticalAlignment", "center");
    toolNameLabel.Layout.Row = 2;
    toolNameLabel.Layout.Column = 1;

    toolNameValue = uilabel(gl, ...
        "Text", toolName);
    toolNameValue.Layout.Row = 2;
    toolNameValue.Layout.Column = 2;

    argsLabel = uilabel(gl, ...
        "Text", "Arguments", ...
        "VerticalAlignment", "top");
    argsLabel.Layout.Row = 3;
    argsLabel.Layout.Column = 1;

    argsArea = uitextarea(gl, ...
        "Value", splitlines(argsJson), ...
        "Editable", "off", ...
        "FontName", "Monospaced", ...
        "BackgroundColor", [0.94 0.94 0.94]);
    argsArea.Layout.Row = 3;
    argsArea.Layout.Column = 2;

    reasonLabel = uilabel(gl, ...
        "Text", "Reason", ...
        "VerticalAlignment", "center");
    reasonLabel.Layout.Row = 4;
    reasonLabel.Layout.Column = 1;

    reasonField = uieditfield(gl, ...
        "Placeholder", "(optional)");
    reasonField.Layout.Row = 4;
    reasonField.Layout.Column = 2;

    result = struct("Approved", false, "Permanent", false, "Reason", "");

    if showAlwaysOption
        dontAskBox = uicheckbox(gl, ...
            "Text", "Don't ask me again", ...
            "Value", false);
        dontAskBox.Layout.Row = 5;
        dontAskBox.Layout.Column = [1 2];

        btnRow = 6;
    else
        btnRow = 5;
    end

    btnLayout = uigridlayout(gl, ...
        "RowHeight", {'1x'}, ...
        "ColumnWidth", {'1x', 'fit', 'fit'}, ...
        "Padding", [0 0 0 0]);
    btnLayout.Layout.Row = btnRow;
    btnLayout.Layout.Column = [1 2];

    approveBtn = uibutton(btnLayout, ...
        "Text", "Approve", ...
        "ButtonPushedFcn", @(~,~) approveCallback());
    approveBtn.Layout.Column = 2;

    denyBtn = uibutton(btnLayout, ...
        "Text", "Deny", ...
        "ButtonPushedFcn", @(~,~) denyCallback());
    denyBtn.Layout.Column = 3;

    fig.KeyPressFcn = @(~,evt) onKeyPress(evt);
    uiwait(fig);

    result.Reason = string(result.Reason);

    function approveCallback()
        result.Approved = true;
        if showAlwaysOption
            result.Permanent = dontAskBox.Value;
        end
        result.Reason = string(reasonField.Value);
        uiresume(fig);
        close(fig);
    end

    function denyCallback()
        result.Approved = false;
        result.Permanent = false;
        result.Reason = string(reasonField.Value);
        uiresume(fig);
        close(fig);
    end

    function onKeyPress(evt)
        if evt.Key == "escape"
            denyCallback();
        end
    end
end
