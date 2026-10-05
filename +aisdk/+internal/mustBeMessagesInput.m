function mustBeMessagesInput(val)
%mustBeMessagesInput Validate that val is a string, char, or LLMMessage array.

%   Copyright 2026 The MathWorks, Inc.

    if isa(val, 'aisdk.message.LLMMessage')
        return
    end
    if isstring(val)
        if ~isscalar(val)
            error("aisdk:client:InvalidMessageInput", ...
                aisdk.internal.MessageCatalog.getMessage("aisdk:client:InvalidMessageInput"));
        end
        return
    end
    if ischar(val)
        if ~isrow(val)
            error("aisdk:client:InvalidMessageInput", ...
                aisdk.internal.MessageCatalog.getMessage("aisdk:client:InvalidMessageInput"));
        end
        return
    end
    error("aisdk:client:InvalidMessageInput", ...
        aisdk.internal.MessageCatalog.getMessage("aisdk:client:InvalidMessageInput"));
end
