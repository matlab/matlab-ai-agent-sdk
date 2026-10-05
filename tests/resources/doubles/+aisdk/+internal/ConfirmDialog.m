classdef ConfirmDialog < handle
% Test double for ConfirmDialog — no UI, no-op wait, fixed Result.

    properties (SetAccess=private)
        Result struct = struct("Approved", true, "Permanent", false, "Reason", "")
    end

    methods
        function this = ConfirmDialog(~, ~)
        end

        function wait(this) %#ok<MANU>
        end
    end
end
