classdef StubDialogFigure < handle
% Deletable stand-in for the figure owned by a ConfirmDialog.
%   awaitApprovalDecision only calls isvalid() and delete() on the Figure
%   property, and both work on any handle object, so tests can assert the
%   deletion without creating graphics.

%   Copyright 2026 The MathWorks, Inc.
end
