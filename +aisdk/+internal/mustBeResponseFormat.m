function mustBeResponseFormat(format)
% This function is undocumented and will change in a future release

% Copyright 2026 The MathWorks, Inc.
    if isstring(format) || ischar(format) || iscellstr(format)
        mustBeTextScalar(format);
        if ~ismember(format,["text","json"]) && ...
            ~startsWith(format,asManyOfPattern(whitespacePattern)+"{")
            error("aisdk:incorrectResponseFormat", ...
                aisdk.internal.MessageCatalog.getMessage("aisdk:incorrectResponseFormat"));
        end
    elseif ~isstruct(format)
        error("aisdk:incorrectResponseFormat", ...
            aisdk.internal.MessageCatalog.getMessage("aisdk:incorrectResponseFormat"));
    end
end
