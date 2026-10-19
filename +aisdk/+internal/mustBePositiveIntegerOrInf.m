function mustBePositiveIntegerOrInf(value)
% This function is undocumented and will change in a future release

%   Copyright 2026 The MathWorks, Inc.
    mustBeNumeric(value)
    mustBePositive(value)
    if value == inf
        return
    end
    mustBeInteger(value)
end
