function mustBeValidToolCallID(val)
%mustBeValidToolCallID Validate that val is a scalar string or []. Should reject char.

%   Copyright 2026 The MathWorks, Inc.

    if ~(isequal(val, []) || (isstring(val) && isscalar(val))) || ischar(val)
        error("llms:message:InvalidToolCallID", ...
            aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:message:InvalidToolCallID"));
    end
end
