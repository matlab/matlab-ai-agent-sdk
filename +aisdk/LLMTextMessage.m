classdef LLMTextMessage < aisdk.llms.message.LLMMessage
%LLMTextMessage A plain text message in a conversation.
%
%   msg = aisdk.LLMTextMessage(TEXT) creates a user text message.
%
%   msg = aisdk.LLMTextMessage(TEXT, Role=ROLE) creates a text message with
%   the specified role ("system", "user", "assistant", or "tool").
%
%   LLMTextMessage Properties:
%       Role                 - "system", "user", "assistant", or "tool".
%
%       Type                 - Always "text".
%
%       Content              - The text of the message.

%   Copyright 2026 The MathWorks, Inc.

    methods
        function this = LLMTextMessage(content, nvp)
            arguments
                content {mustBeTextContent}
                nvp.Role(1,1) string {mustBeMember(nvp.Role, ["system","user","assistant","tool"])} = "user"
            end

            this@aisdk.llms.message.LLMMessage(nvp.Role, "text");
            this.Content = string(content);
        end
    end

    methods (Access = protected)
        function validateContent(~, val)
            if ~(isstring(val) && isscalar(val))
                error("llms:message:InvalidContent", ...
                    aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:message:InvalidContent"));
            end
        end
    end

end

function mustBeTextContent(val)
    if ~(isstring(val) || ischar(val)) || (isstring(val) && ~isscalar(val))
        error("llms:message:InvalidTextContent", ...
            aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:message:InvalidTextContent"));
    end
end
