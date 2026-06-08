function mustBeMessagesInput(val)
%mustBeMessagesInput Validate that val is a string, char, or LLMMessage array.

%   Copyright 2026 The MathWorks, Inc.

    if isa(val, 'aisdk.llms.message.LLMMessage')
        return
    end
    if isstring(val)
        if ~isscalar(val)
            error("llms:client:InvalidMessageInput", ...
                aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:client:InvalidMessageInput"));
        end
        return
    end
    if ischar(val)
        if ~isrow(val)
            error("llms:client:InvalidMessageInput", ...
                aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:client:InvalidMessageInput"));
        end
        return
    end
    error("llms:client:InvalidMessageInput", ...
        aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:client:InvalidMessageInput"));
end
