function tf = batchStartupOptionUsed
% Test double that shadows the MATLAB built-in and reports -batch mode, so
% the uiconfirm fail-safe can be exercised from an interactive session.
% Only active while a test applies a PathFixture for this folder.

%   Copyright 2026 The MathWorks, Inc.

    tf = true;
end
