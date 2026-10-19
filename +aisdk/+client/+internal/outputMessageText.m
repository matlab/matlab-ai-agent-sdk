function txt = outputMessageText(item)
% This function is undocumented and will change in a future release

%outputMessageText Text of the output_text parts of a Responses API message item.

%   Copyright 2026 The MathWorks, Inc.

txt = "";
if ~isfield(item,"content")
    return
end
content = item.content;
if ~iscell(content)
    content = num2cell(content);
end
for j = 1:numel(content)
    part = content{j};
    if isstruct(part) && isfield(part,"type") && string(part.type) == "output_text" ...
            && isfield(part,"text")
        txt = txt + string(part.text);
    end
end
end
