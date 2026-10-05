function mustBeToolArguments(args)
% This function is undocumented and will change in a future release

% Copyright 2026 The MathWorks, Inc.
    if isstruct(args) && ~isscalar(args)
        aisdk.internal.throwError("aisdk:invalidToolArguments");
    elseif ~isstruct(args) && ~isa(args, "aisdk.LLMToolArgument")
        aisdk.internal.throwError("aisdk:invalidToolArguments");
    end
end
