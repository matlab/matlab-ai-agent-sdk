function mustBeToolArguments(args)
% This function is undocumented and will change in a future release

% Copyright 2026 The MathWorks, Inc.
    if isstruct(args) && ~isscalar(args)
        error("llms:invalidToolArguments", ...
            aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:invalidToolArguments"));
    elseif ~isstruct(args) && ~isa(args, "aisdk.LLMToolArgument")
        error("llms:invalidToolArguments", ...
            aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:invalidToolArguments"));
    end
end
