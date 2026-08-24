function mustBePositiveIntegerOrNaN(value)
% This function is undocumented and will change in a future release

%   Copyright 2026 The MathWorks, Inc.
    mustBeNumeric(value)
    if isnan(value)
        return
    end
    mustBePositive(value)
    mustBeInteger(value)
end
