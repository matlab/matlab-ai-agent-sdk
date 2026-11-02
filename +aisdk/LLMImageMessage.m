classdef LLMImageMessage < aisdk.message.LLMMessage
%LLMImageMessage An image message in a conversation.
%
%   msg = aisdk.LLMImageMessage(IMGARRAY) creates a user image message
%   from a nonsparse MATLAB grayscale or RGB image array.
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
%       Image                - MATLAB image array (numeric), usable
%                              with imshow/imwrite.
%
%       Detail               - Image resolution detail level.

%   Copyright 2026 The MathWorks, Inc.

    properties
        %IMAGE   Nonsparse MATLAB grayscale or RGB image array.
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

            this@aisdk.message.LLMMessage("user");
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
        function label = displayTypeLabel(~)
            label = "Image";
        end

        function txt = contentPreview(this)
            sz = size(this.Image);
            txt = "<image " + strjoin(string(sz), "×") + " " + class(this.Image) + ">";
        end

        function groups = getPropertyGroups(obj)
            props = struct( ...
                "Role", obj.Role, ...
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
                aisdk.internal.throwError("aisdk:message:NotAnImage", source);
            end
        end
    else
        aisdk.internal.throwError("aisdk:message:InvalidImageSource");
    end
end

function img = readURL(url, downloadFcn)
    tempFile = [tempname, '.tmp'];
    cleanupObj = onCleanup(@() deleteIfExists(tempFile)); %#ok<NASGU>
    try
        downloadFcn(tempFile, url);
        img = imread(tempFile);
    catch
        aisdk.internal.throwError("aisdk:message:NotAnImage", url);
    end
end

function deleteIfExists(filePath)
    if isfile(filePath)
        delete(filePath);
    end
end

function mustBeImageArray(val)
    validateattributes(val, ["double" "single" "logical" "uint8" "uint16"], ...
        ["nonempty" "nonsparse"]);
    if ~(ismatrix(val) || (ndims(val) == 3 && size(val, 3) == 3))
        aisdk.internal.throwError("aisdk:message:InvalidImageDimensions");
    end
    if islogical(val) && ~ismatrix(val)
        aisdk.internal.throwError("aisdk:message:InvalidLogicalImageDimensions");
    end
end
