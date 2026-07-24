function result = uiconfirm(~, ~)
% Test double that auto-approves tool calls without opening a UI dialog.
    result = struct("Approved", true, "Permanent", false, "Reason", "");
end
