function [observation, workspace] = setEyeHeight(workspace)
%setEyeHeight Workspace-aware stub tool at the bottom of a nesting.
%   Writes workspace.eyeHeight so a test can prove a field written by the
%   innermost tool survives all the way back to the top-level run.

% Copyright 2026 The MathWorks, Inc.

    workspace.eyeHeight = 0.42;
    observation = "eyeHeight = 0.42";
end
