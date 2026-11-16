function text = formatPreview(text)
%formatPreview Normalize prose whitespace and truncate for display.

% Copyright 2026 The MathWorks, Inc.

    text = strip(regexprep(text, "\s+", " "));
    text = aisdk.internal.truncateForDisplay(text);
end
