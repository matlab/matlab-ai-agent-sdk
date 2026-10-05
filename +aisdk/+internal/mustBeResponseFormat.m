function mustBeResponseFormat(format)
% This function is undocumented and will change in a future release

% Copyright 2026 The MathWorks, Inc.
    if isstring(format) || ischar(format) || iscellstr(format)
        mustBeTextScalar(format);
        if ~ismember(format,["text","json"]) && ...
            ~startsWith(format,asManyOfPattern(whitespacePattern)+"{")
            aisdk.internal.throwError("aisdk:incorrectResponseFormat");
        end
    elseif ~isstruct(format) || isempty(format)
        aisdk.internal.throwError("aisdk:incorrectResponseFormat");
    end
end
