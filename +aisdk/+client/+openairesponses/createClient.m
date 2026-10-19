function client = createClient(modelName, varargin)
%   Copyright 2026 The MathWorks, Inc.
    rejectChatCompletionsOptions(varargin);
    client = aisdk.client.OpenAIResponsesClient(modelName, varargin{:});
end

function rejectChatCompletionsOptions(args)
    % Options OpenAIClient accepts at construction that the Responses API
    % has no equivalent for.
    unsupported = ["StopSequences", "PresencePenalty", "FrequencyPenalty"];
    names = args(1:2:end);
    isName = cellfun(@(x) ischar(x) || (isstring(x) && isscalar(x)), names);
    names = string(names(isName));
    for name = unsupported
        if any(strcmpi(names, name))
            aisdk.internal.throwError("aisdk:parameterUnsupportedByResponsesAPI", name);
        end
    end
end
 