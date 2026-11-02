function toolCalls = normalizeToolCallsShape(toolCalls)
%normalizeToolCallsShape Convert tool calls to an N-by-1 cell array.

%   Copyright 2026 The MathWorks, Inc.

if isempty(toolCalls)
    toolCalls = cell(0,1);
elseif ~iscell(toolCalls)
    toolCalls = num2cell(toolCalls);
end
toolCalls = reshape(toolCalls, [], 1);
end
