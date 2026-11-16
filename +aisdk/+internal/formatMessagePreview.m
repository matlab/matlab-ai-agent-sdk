function text = formatMessagePreview(text)
%formatMessagePreview Show line breaks and tabs while preserving message spacing.

% Copyright 2026 The MathWorks, Inc.

    % char(13) is carriage return: normalize CRLF and CR line endings to LF.
    text = replace(text, [char(13), newline], newline);
    text = replace(text, char(13), newline);
    text = replace(text, newline, "↵");
    % char(9) is a tab: show it visibly without changing column alignment.
    text = replace(text, char(9), "\t");
    text = aisdk.internal.truncateForDisplay(text);
end
