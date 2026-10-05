function mustBeValidToolCallID(val)
%mustBeValidToolCallID Validate that val is a scalar string. Rejects char and [].

%   Copyright 2026 The MathWorks, Inc.

    if ~(isstring(val) && isscalar(val))
        error("aisdk:message:InvalidToolCallID", ...
            aisdk.internal.MessageCatalog.getMessage("aisdk:message:InvalidToolCallID"));
    end
end
