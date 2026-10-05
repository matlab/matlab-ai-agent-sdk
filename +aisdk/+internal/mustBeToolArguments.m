function mustBeToolArguments(args)
% This function is undocumented and will change in a future release

% Copyright 2026 The MathWorks, Inc.
    if isstruct(args) && ~isscalar(args)
        error("aisdk:invalidToolArguments", ...
            aisdk.internal.MessageCatalog.getMessage("aisdk:invalidToolArguments"));
    elseif ~isstruct(args) && ~isa(args, "aisdk.LLMToolArgument")
        error("aisdk:invalidToolArguments", ...
            aisdk.internal.MessageCatalog.getMessage("aisdk:invalidToolArguments"));
    end
end
