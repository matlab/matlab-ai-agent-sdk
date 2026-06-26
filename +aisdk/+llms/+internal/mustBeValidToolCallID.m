function mustBeValidToolCallID(val)
%mustBeValidToolCallID Validate that val is a scalar string. Rejects char and [].

%   Copyright 2026 The MathWorks, Inc.

    if ~(isstring(val) && isscalar(val))
        error("llms:message:InvalidToolCallID", ...
            aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:message:InvalidToolCallID"));
    end
end
