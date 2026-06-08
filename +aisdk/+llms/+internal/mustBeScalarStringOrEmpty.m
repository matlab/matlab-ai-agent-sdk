function mustBeScalarStringOrEmpty(val)
%mustBeScalarStringOrEmpty Validate that val is a scalar string, char array, or [].

%   Copyright 2026 The MathWorks, Inc.

    if ~(isempty(val) && isequal(val, []) || ischar(val) || (isstring(val) && isscalar(val)))
        error("llms:message:InvalidToolCallID", ...
            aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:message:InvalidToolCallID"));
    end
end
