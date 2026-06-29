classdef LLMImageMessage < aisdk.llms.message.LLMMessage
%LLMImageMessage An image message in a conversation.
%
%   msg = aisdk.LLMImageMessage(IMGARRAY) creates a user image message
%   from a MATLAB image array (numeric or logical).
%
%   msg = aisdk.LLMImageMessage(SOURCE) creates a user image message from
%   a file path or URL.
%
%   msg = aisdk.LLMImageMessage(__, Detail=D) sets the image resolution
%   detail level ("auto", "low", "high", or "original"). Only consumed by
%   providers that support it (currently OpenAI).
%
%   LLMImageMessage Properties:
%       Role                 - Always "user".
%
%       Type                 - Always "image".
%
%       Image                - MATLAB image array (numeric), usable
%                              with imshow/imwrite.
%
%       Detail               - Image resolution detail level.

%   Copyright 2026 The MathWorks, Inc.

    properties
        %IMAGE   MATLAB image array (numeric or logical).
        Image
    end

    properties (SetAccess = immutable)
        %DETAIL   Image resolution detail level: "auto", "low", "high", or "original".
        Detail(1,1) string {mustBeMember(Detail, ["auto","low","high","original"])} = "auto"
    end

    properties (Hidden)
        DownloadFcn function_handle = @websave
    end

    methods
        function this = LLMImageMessage(content, nvp)
            arguments
                content
                nvp.Detail(1,1) string {mustBeMember(nvp.Detail, ["auto","low","high","original"])} = "auto"
                nvp.DownloadFcn function_handle = @websave
            end

            this@aisdk.llms.message.LLMMessage("user", "image");
            this.Detail = nvp.Detail;
            this.DownloadFcn = nvp.DownloadFcn;
            this.Image = resolveToImageArray(content, this.DownloadFcn);
        end

        function this = set.Image(this, val)
            mustBeImageArray(val);
            this.Image = val;
        end
    end

    methods (Access = protected)
        function txt = contentPreview(this)
            sz = size(this.Image);
            txt = "<image " + strjoin(string(sz), "×") + " " + class(this.Image) + ">";
        end

        function groups = getPropertyGroups(obj)
            props = struct( ...
                "Role", obj.Role, ...
                "Type", obj.Type, ...
                "Image", contentPreview(obj));
            if obj.Detail ~= "auto"
                props.Detail = obj.Detail;
            end
            groups = matlab.mixin.util.PropertyGroup(props);
        end
    end

end

function img = resolveToImageArray(source, downloadFcn)
    if isnumeric(source) || islogical(source)
        mustBeImageArray(source);
        img = source;
    elseif (isstring(source) && isscalar(source)) || ischar(source)
        source = string(source);
        if startsWith(source, ("https://" | "http://"))
            img = readURL(source, downloadFcn);
        else
            try
                img = imread(source);
            catch e
                if e.identifier == "MATLAB:imagesci:imread:fileDoesNotExist"
                    rethrow(e);
                end
                error("llms:message:NotAnImage", "%s", ...
                    aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:message:NotAnImage", source));
            end
        end
    else
        error("llms:message:InvalidImageSource", ...
            aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:message:InvalidImageSource"));
    end
end

function img = readURL(url, downloadFcn)
    tempFile = [tempname, '.tmp'];
    cleanupObj = onCleanup(@() deleteIfExists(tempFile)); %#ok<NASGU>
    try
        downloadFcn(tempFile, url);
        img = imread(tempFile);
    catch
        error("llms:message:NotAnImage", "%s", ...
            aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:message:NotAnImage", url));
    end
end

function deleteIfExists(filePath)
    if isfile(filePath)
        delete(filePath);
    end
end

function mustBeImageArray(val)
    okType = isnumeric(val) || islogical(val);
    okShape = ismatrix(val) || (ndims(val) == 3 && ismember(size(val,3), [1 3 4]));
    if ~(okType && okShape && ~isempty(val))
        error("llms:message:InvalidImageContent", ...
            aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:message:InvalidImageContent"));
    end
end
