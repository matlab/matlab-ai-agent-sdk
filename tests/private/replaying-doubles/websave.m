function filename = websave(filename, ~)
%WEBSAVE Mock that writes a tiny valid image instead of downloading.
%   Used during test replay so that LLMImageMessage URL construction
%   succeeds without network access. The file is cleaned up by onCleanup
%   in readURL after imread reads it.

%   Copyright 2026 The MathWorks, Inc.

img = uint8(zeros(1, 1, 3));
imwrite(img, filename, "png");
end
