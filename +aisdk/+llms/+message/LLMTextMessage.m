classdef LLMTextMessage < aisdk.llms.message.LLMMessage
%LLMTextMessage A plain text message in a conversation.
%
%   LLMTextMessage Properties (inherited):
%       Role                 - "user" or "assistant".
%
%       Type                 - Always "text".
%
%       Content              - The text of the message.

%   Copyright 2026 The MathWorks, Inc.

    methods
        function this = LLMTextMessage(content, role)
            arguments
                content {mustBeTextContent}
                role(1,1) string {mustBeMember(role, ["system","user","assistant","tool"])}
            end

            this@aisdk.llms.message.LLMMessage(role, "text");
            this.Content = string(content);
        end
    end

    methods (Access = protected)
        function validateContent(~, val)
            if ~(isstring(val) && isscalar(val))
                error("llms:message:InvalidContent", ...
                    "Content must be a scalar string.");
            end
        end
    end

end

function mustBeTextContent(val)
    if ~(isstring(val) || ischar(val))
        error("llms:message:InvalidTextContent", ...
            "Text message content must be a string or char.");
    end
    if isstring(val) && ~isscalar(val)
        error("llms:message:InvalidTextContent", ...
            "Text message content must be a scalar string.");
    end
end
