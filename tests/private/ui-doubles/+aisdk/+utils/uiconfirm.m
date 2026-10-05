function result = uiconfirm(~, ~)
% Test double that auto-approves tool calls without opening a UI dialog.

%   Copyright 2026 The MathWorks, Inc.

    result = struct("Approved", true, "Permanent", false, "Reason", "");
end
