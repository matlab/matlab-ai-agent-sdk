classdef ConfirmDialog < handle
%ConfirmDialog Dialog for confirming AI agent tool calls.
%   Builds the UI and stores the result. When the tool has ApprovalRequest
%   set to "once", a third "Always Approve" button appears alongside
%   "Approve" and "Deny" to make the approval permanent. Call wait() to
%   block until the user responds. The figure and components are public for
%   testing.
%
%   Deny is the default button: wait() gives it the keyboard focus, so
%   Enter denies the call, as does Escape.

% Copyright 2026 The MathWorks, Inc.

    properties (SetAccess=private)
        Figure matlab.ui.Figure
        ApproveButton matlab.ui.control.Button
        ApproveAlwaysButton matlab.ui.control.Button
        DenyButton matlab.ui.control.Button
        ArgumentsArea matlab.ui.control.TextArea
        ReasonField matlab.ui.control.TextArea
        Result struct = struct("Approved", false, "Permanent", false, "Reason", "")
    end

    properties (Access=private)
        ShowAlwaysOption logical
    end

    methods
        function this = ConfirmDialog(tool, toolArguments)
            arguments
                tool          (1,1) aisdk.tool.LLMTool
                toolArguments (1,1) struct
            end

            toolName = tool.Name;
            this.ShowAlwaysOption = (tool.ApprovalRequest == "once");

            argsJson = jsonencode(toolArguments, PrettyPrint=true);

            this.Figure = uifigure("Name", ...
                aisdk.internal.MessageCatalog.getMessage("aisdk:confirmDialog:title"), ...
                "WindowStyle", "normal", ...
                "Position", [100 100 420 321]);
            movegui(this.Figure, "center");

            % Scrollable so that shrinking the resizable figure below the
            % height the fixed rows need scrolls the layout instead of
            % clipping the button row out of view.
            gl = uigridlayout(this.Figure, ...
                "RowHeight", {'fit', 22, '1x', 2, 44, 22, 30}, ...
                "ColumnWidth", {80, '1x'}, ...
                "ColumnSpacing", 10, ...
                "Padding", [15 15 15 15], ...
                "Scrollable", "on");

            headerLabel = uilabel(gl, ...
                "Text", aisdk.internal.MessageCatalog.getMessage( ...
                    "aisdk:confirmDialog:header", tool.DisplayTitle), ...
                "FontWeight", "bold", ...
                "WordWrap", "on");
            headerLabel.Layout.Row = 1;
            headerLabel.Layout.Column = [1 2];

            toolNameLabel = uilabel(gl, ...
                "Text", aisdk.internal.MessageCatalog.getMessage("aisdk:confirmDialog:nameLabel"), ...
                "VerticalAlignment", "center");
            toolNameLabel.Layout.Row = 2;
            toolNameLabel.Layout.Column = 1;

            toolNameValue = uilabel(gl, ...
                "Text", toolName, ...
                "FontName", "Monospaced");
            toolNameValue.Layout.Row = 2;
            toolNameValue.Layout.Column = 2;

            argsLabel = uilabel(gl, ...
                "Text", aisdk.internal.MessageCatalog.getMessage("aisdk:confirmDialog:argumentsLabel"), ...
                "VerticalAlignment", "top");
            argsLabel.Layout.Row = 3;
            argsLabel.Layout.Column = 1;

            this.ArgumentsArea = uitextarea(gl, ...
                "Value", splitlines(argsJson), ...
                "Editable", "off", ...
                "FontName", "Monospaced", ...
                "BackgroundColor", this.Figure.Color);
            this.ArgumentsArea.Layout.Row = 3;
            this.ArgumentsArea.Layout.Column = 2;

            % Horizontal separator between the arguments and the Reason
            % box. Derive a subtle line color from the (theme-resolved)
            % figure background so it reads correctly in light and dark
            % themes.
            separator = uipanel(gl, ...
                "BorderType", "none", ...
                "BackgroundColor", separatorColor(this.Figure.Color));
            separator.Layout.Row = 4;
            separator.Layout.Column = [1 2];

            reasonLabel = uilabel(gl, ...
                "Text", aisdk.internal.MessageCatalog.getMessage("aisdk:confirmDialog:feedbackLabel"), ...
                "VerticalAlignment", "top");
            reasonLabel.Layout.Row = 5;
            reasonLabel.Layout.Column = 1;

            this.ReasonField = uitextarea(gl, ...
                "Placeholder", aisdk.internal.MessageCatalog.getMessage("aisdk:confirmDialog:feedbackPlaceholder"));
            this.ReasonField.Layout.Row = 5;
            this.ReasonField.Layout.Column = 2;

            % Button row: an "Always Approve" button appears between Approve
            % and Deny only when the tool's ApprovalRequest is "once".
            if this.ShowAlwaysOption
                btnColumns = {'1x', 'fit', 'fit', 'fit'};
            else
                btnColumns = {'1x', 'fit', 'fit'};
            end

            btnLayout = uigridlayout(gl, ...
                "RowHeight", {'1x'}, ...
                "ColumnWidth", btnColumns, ...
                "Padding", [0 0 0 0]);
            % Row 6 is left empty to add spacing between the feedback box
            % and the buttons.
            btnLayout.Layout.Row = 7;
            btnLayout.Layout.Column = [1 2];

            this.ApproveButton = uibutton(btnLayout, ...
                "Text", aisdk.internal.MessageCatalog.getMessage("aisdk:confirmDialog:approveButton"), ...
                "ButtonPushedFcn", @(~,~) finish(this, Approved=true, Permanent=false));
            this.ApproveButton.Layout.Column = 2;

            if this.ShowAlwaysOption
                this.ApproveAlwaysButton = uibutton(btnLayout, ...
                    "Text", aisdk.internal.MessageCatalog.getMessage("aisdk:confirmDialog:approveAlwaysButton"), ...
                    "ButtonPushedFcn", @(~,~) finish(this, Approved=true, Permanent=true));
                this.ApproveAlwaysButton.Layout.Column = 3;
                denyColumn = 4;
            else
                denyColumn = 3;
            end

            this.DenyButton = uibutton(btnLayout, ...
                "Text", aisdk.internal.MessageCatalog.getMessage("aisdk:confirmDialog:denyButton"), ...
                "ButtonPushedFcn", @(~,~) finish(this, Approved=false, Permanent=false));
            this.DenyButton.Layout.Column = denyColumn;

            this.Figure.KeyPressFcn = @(~,evt) onKeyPress(this, evt);
        end

        function wait(this)
            focusDefaultButton(this);
            uiwait(this.Figure);
            this.Result.Reason = string(this.Result.Reason);
        end

        function button = focusDefaultButton(this)
            % Deny is the default button, and is returned so tests can
            % assert the choice. A dialog that cannot take focus still
            % opens and waits.
            button = this.DenyButton;
            try
                focus(button);
            catch
            end
        end
    end

    methods (Access=private)
        function finish(this, opts)
            arguments
                this
                opts.Approved  (1,1) logical = false
                opts.Permanent (1,1) logical = false
            end

            this.Result.Approved = opts.Approved;
            this.Result.Permanent = opts.Permanent;
            % The feedback field is a multi-line uitextarea whose Value is
            % a cell array of char rows (one per line). Join them into a
            % single string, preserving line breaks.
            this.Result.Reason = join(string(this.ReasonField.Value), newline);
            uiresume(this.Figure);
            close(this.Figure);
        end

        function onKeyPress(this, evt)
            if evt.Key == "escape"
                finish(this, Approved=false, Permanent=false);
            end
        end
    end
end

function color = separatorColor(bg)
% Nudge the figure background toward its opposite lightness so the
% separator is a subtle contrast in either theme: slightly darker on a
% light background, slightly lighter on a dark one.
    luminance = 0.299*bg(1) + 0.587*bg(2) + 0.114*bg(3);
    if luminance > 0.5
        color = max(bg - 0.15, 0);
    else
        color = min(bg + 0.20, 1);
    end
end
