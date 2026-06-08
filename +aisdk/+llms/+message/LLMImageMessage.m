classdef LLMImageMessage < aisdk.llms.message.LLMMessage
%LLMImageMessage An image message in a conversation.
%
%   msg = aisdk.llms.message.LLMImageMessage(CONTENT, ROLE) creates an image
%   message from CONTENT, which can be a file path, URL, or MATLAB image
%   array.
%
%   msg = aisdk.llms.message.LLMImageMessage(CONTENT, ROLE, Detail=D) sets the
%   image resolution detail level ("auto", "low", "high", or "original").
%   Only consumed by providers that support it (currently OpenAI).
%
%   LLMImageMessage Properties (inherited):
%       Role                 - "user", "assistant", or "tool".
%
%       Type                 - Always "image".
%
%       Content              - MATLAB image array (numeric), usable
%                              with imshow/imwrite.
%
%   LLMImageMessage Properties:
%       Detail               - Image resolution detail level.

%   Copyright 2026 The MathWorks, Inc.

    properties (SetAccess = immutable)
        %DETAIL   Image resolution detail level: "auto", "low", "high", or "original".
        Detail(1,1) string {mustBeMember(Detail, ["auto","low","high","original"])} = "auto"
    end

    methods
        function this = LLMImageMessage(content, role, nvp)
            arguments
                content
                role(1,1) string {mustBeMember(role, ["user","assistant","tool"])}
                nvp.Detail(1,1) string {mustBeMember(nvp.Detail, ["auto","low","high","original"])} = "auto"
            end

            this@aisdk.llms.message.LLMMessage(role, "image");
            this.Detail = nvp.Detail;
            this.Content = resolveToImageArray(content);
        end
    end

    methods (Access = protected)
        function validateContent(~, val)
            mustBeImageArray(val);
        end

        function txt = contentPreview(this)
            sz = size(this.Content);
            txt = "<image " + strjoin(string(sz), "x") + " " + class(this.Content) + ">";
        end

        function groups = getPropertyGroups(obj)
            props = struct( ...
                "Role", obj.Role, ...
                "Type", obj.Type, ...
                "Content", contentPreview(obj));
            if obj.Detail ~= "auto"
                props.Detail = obj.Detail;
            end
            groups = matlab.mixin.util.PropertyGroup(props);
        end
    end

end

function img = resolveToImageArray(source)
    if isnumeric(source) || islogical(source)
        mustBeImageArray(source);
        img = source;
    elseif (isstring(source) && isscalar(source)) || ischar(source)
        source = string(source);
        if startsWith(source, ("https://" | "http://"))
            img = readURL(source);
        else
            img = imread(source);
        end
    else
        error("llms:message:InvalidImageSource", ...
            "Image source must be a file path, URL, or numeric image array.");
    end
end

function img = readURL(url)
    tempFile = [tempname, '.tmp'];
    cleanupObj = onCleanup(@() delete(tempFile));
    websave(tempFile, url);
    img = imread(tempFile);
end

function mustBeImageArray(val)
    okType = isnumeric(val) || islogical(val);
    okShape = ismatrix(val) || (ndims(val) == 3 && ismember(size(val,3), [1 3 4]));
    if ~(okType && okShape && ~isempty(val))
        error("llms:message:InvalidImageContent", ...
            "Content must be a nonempty numeric or logical image array.");
    end
end
