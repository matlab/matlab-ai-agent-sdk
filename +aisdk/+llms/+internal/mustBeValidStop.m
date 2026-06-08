function mustBeValidStop(value)
% This function is undocumented and will change in a future release

%   Copyright 2026 The MathWorks, Inc.
    if ~isempty(value)
        mustBeVector(value);
        mustBeNonzeroLengthText(value);
    end
end
