classdef ConfirmDialog < handle
%ConfirmDialog Dialog for confirming AI agent tool calls.
%   Builds the UI and stores the result. Call wait() to block until the
%   user responds. The figure and components are public for testing.

% Copyright 2026 The MathWorks, Inc.

    properties (SetAccess=private)
        Figure matlab.ui.Figure
        ApproveButton matlab.ui.control.Button
        DenyButton matlab.ui.control.Button
        ReasonField matlab.ui.control.EditField
        DontAskCheckbox
        Result struct = struct("Approved", false, "Permanent", false, "Reason", "")
    end

    properties (Access=private)
        ShowAlwaysOption logical
    end

    methods
        function this = ConfirmDialog(tool, toolArguments)
            arguments
                tool          (1,1) aisdk.llms.tool.LLMTool
                toolArguments (1,1) struct
            end

            toolName = tool.Name;
            this.ShowAlwaysOption = (tool.RequiresApproval == "once");

            argsJson = jsonencode(toolArguments, PrettyPrint=true);

            this.Figure = uifigure("Name", "AI Agent", ...
                "WindowStyle", "normal", ...
                "Position", [100 100 420 270], ...
                "Resize", "off");
            movegui(this.Figure, "center");

            if this.ShowAlwaysOption
                rowHeights = {'fit', 22, '1x', 22, 22, 30};
            else
                rowHeights = {'fit', 22, '1x', 22, 30};
            end

            gl = uigridlayout(this.Figure, ...
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
                "BackgroundColor", this.Figure.Color);
            argsArea.Layout.Row = 3;
            argsArea.Layout.Column = 2;

            reasonLabel = uilabel(gl, ...
                "Text", "Reason", ...
                "VerticalAlignment", "center");
            reasonLabel.Layout.Row = 4;
            reasonLabel.Layout.Column = 1;

            this.ReasonField = uieditfield(gl, ...
                "Placeholder", "(optional)");
            this.ReasonField.Layout.Row = 4;
            this.ReasonField.Layout.Column = 2;

            if this.ShowAlwaysOption
                this.DontAskCheckbox = uicheckbox(gl, ...
                    "Text", "Don't ask me again", ...
                    "Value", false);
                this.DontAskCheckbox.Layout.Row = 5;
                this.DontAskCheckbox.Layout.Column = [1 2];
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

            this.ApproveButton = uibutton(btnLayout, ...
                "Text", "Approve", ...
                "ButtonPushedFcn", @(~,~) approve(this));
            this.ApproveButton.Layout.Column = 2;

            this.DenyButton = uibutton(btnLayout, ...
                "Text", "Deny", ...
                "ButtonPushedFcn", @(~,~) deny(this));
            this.DenyButton.Layout.Column = 3;

            this.Figure.KeyPressFcn = @(~,evt) onKeyPress(this, evt);
        end

        function wait(this)
            uiwait(this.Figure);
            this.Result.Reason = string(this.Result.Reason);
        end
    end

    methods (Access=private)
        function approve(this)
            this.Result.Approved = true;
            if this.ShowAlwaysOption
                this.Result.Permanent = this.DontAskCheckbox.Value;
            end
            this.Result.Reason = string(this.ReasonField.Value);
            uiresume(this.Figure);
            close(this.Figure);
        end

        function deny(this)
            this.Result.Approved = false;
            this.Result.Permanent = false;
            this.Result.Reason = string(this.ReasonField.Value);
            uiresume(this.Figure);
            close(this.Figure);
        end

        function onKeyPress(this, evt)
            if evt.Key == "escape"
                deny(this);
            end
        end
    end
end
