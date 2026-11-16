function text = truncateForDisplay(text)
%truncateForDisplay Flatten newlines and limit previews to 60 characters.

% Copyright 2026 The MathWorks, Inc.

    text = replace(text, newline, " ");
    if strlength(text) > 60
        text = extractBefore(text, 61) + "…";
    end
end
