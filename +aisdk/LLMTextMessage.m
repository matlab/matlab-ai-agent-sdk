classdef LLMTextMessage < aisdk.llms.message.LLMMessage
%LLMTextMessage A plain text message in a conversation.
%
%   msg = aisdk.LLMTextMessage(text) creates a user text message.
%
%   msg = aisdk.LLMTextMessage(text, Role=role) creates a text message with
%   the specified role ("system", "user", or "assistant").
%
%   LLMTextMessage Properties:
%       Role                 - "system", "user", or "assistant".
%
%       Type                 - Always "text".
%
%       Text                 - The text of the message.

%   Copyright 2026 The MathWorks, Inc.

    properties
        %TEXT   The text of the message.
        Text
    end

    methods
        function this = LLMTextMessage(text, nvp)
            arguments
                text {mustBeTextContent}
                nvp.Role(1,1) string {mustBeMember(nvp.Role, ["system","user","assistant"])} = "user"
            end

            this@aisdk.llms.message.LLMMessage(nvp.Role, "text");
            this.Text = string(text);
        end

        function this = set.Text(this, val)
            mustBeTextContent(val);
            this.Text = string(val);
        end
    end

    methods (Access = protected)
        function txt = contentPreview(this)
            txt = this.truncateForDisplay(this.Text);
        end
    end

end

function mustBeTextContent(val)
    if ~(isstring(val) || ischar(val)) || (isstring(val) && ~isscalar(val))
        error("llms:message:InvalidTextContent", ...
            aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:message:InvalidTextContent"));
    end
end
