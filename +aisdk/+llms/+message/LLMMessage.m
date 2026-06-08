classdef(Abstract) LLMMessage < matlab.mixin.Heterogeneous & matlab.mixin.CustomDisplay
%LLMMessage Abstract base class for all AI conversation messages.
%
%   LLMMessage Properties:
%       Role                 - The role of the message sender
%                              (e.g. "user", "assistant", "tool").
%
%       Type                 - The type of message content
%                              (e.g. "text", "tool-call").
%
%       Content              - The content of the message.

%   Copyright 2026 The MathWorks, Inc.

    properties (SetAccess = immutable)
        %ROLE   The role of the message sender.
        Role(1,1) string

        %TYPE   The type of message content.
        Type(1,1) string
    end

    properties
        %CONTENT   The content of the message.
        Content = []
    end

    methods
        function this = set.Content(this, val)
            this.validateContent(val);
            this.Content = val;
        end
    end

    methods (Access = protected)
        function this = LLMMessage(role, type)
            this.Role = role;
            this.Type = type;
        end

        function validateContent(~, val)
            if ~(isempty(val) && isequal(val, []) || (isstring(val) && isscalar(val)))
                error("llms:message:InvalidContent", ...
                    aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:message:InvalidContent"));
            end
        end

        function txt = contentPreview(this)
            txt = string(this.Content);
            if ~isscalar(txt) || ismissing(txt)
                txt = "";
            end
            txt = strip(txt, '"');
            txt = replace(txt, newline, " ");
            if strlength(txt) > 60
                txt = extractBefore(txt, 61) + "...";
            end
            txt = """" + txt + """";
        end
    end


    methods (Sealed, Access = protected)
        function displayScalarObject(obj)
            displayScalarObject@matlab.mixin.CustomDisplay(obj);
        end

        function displayNonScalarObject(obj)
            displayMessages(obj);
        end
    end

    methods (Sealed, Access = private)
        function displayMessages(obj)
            n = numel(obj);
            dimStr = matlab.mixin.CustomDisplay.convertDimensionsToString(obj);
            className = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
            fprintf("  %s %s array with messages:\n\n", dimStr, className);

            % Build display data
            roles  = strings(n,1);
            types  = strings(n,1);
            texts  = strings(n,1);
            for i = 1:n
                roles(i) = roleLabel(obj(i).Role);
                types(i) = typeLabel(obj(i).Type);
                if obj(i).Type == "tool-call"
                    texts(i) = obj(i).Name;
                else
                    texts(i) = obj(i).contentPreview();
                end
            end

            % Column widths
            idxWidth   = strlength(string(n));
            roleWidth  = max(strlength(roles));
            typeWidth  = max(strlength(types));

            for i = 1:n
                fprintf("    %-*s    %-*s    %-*s    %s\n", ...
                    idxWidth, string(i), ...
                    roleWidth, roles(i), ...
                    typeWidth, types(i), ...
                    texts(i));
            end
            fprintf("\n");
        end
    end

end

function label = roleLabel(role)
    switch role
        case "user"
            label = "User";
        case "assistant"
            label = "Assistant";
        case "tool"
            label = "Tool";
        otherwise
            label = role;
    end
end

function label = typeLabel(type)
    switch type
        case "text"
            label = "Text";
        case "tool-call"
            label = "Tool Call";
        case "image"
            label = "Image";
        otherwise
            label = type;
    end
end
