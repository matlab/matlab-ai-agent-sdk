function [observation, workspace] = contextualFromMeta(workspace, value)
% A contextual function whose first input is struct (workspace).
% Used to test automatic contextual detection from metadata.
% Inputs
% - workspace struct the shared workspace
% - value double a number to store

% Copyright 2026 The MathWorks, Inc.

    arguments (Input)
        workspace (1,1) struct
        value (1,1) double
    end
    arguments (Output)
        observation string
        workspace (1,1) struct
    end
    workspace.stored = value;
    observation = "stored";
end
