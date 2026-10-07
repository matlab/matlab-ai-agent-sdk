classdef RouterLink < handle
%ROUTERLINK  Shared reference from copied graph tools to their routing agent.

% Copyright 2026 The MathWorks, Inc.

    properties
        Router aisdk.AIAgent {mustBeScalarOrEmpty} = aisdk.AIAgent.empty(1,0)
    end
end
