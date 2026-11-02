function result = reformatOutput(result,responseFormat,nvp)
% This function is undocumented and will change in a future release

%reformatOutput - Create the expected struct for structured output

%   Copyright 2026 The MathWorks, Inc.

    arguments
        result
        responseFormat
        nvp.HasToolCalls (1,1) logical = false
    end

    if ~isstruct(responseFormat)
        return
    end
    if strlength(result) == 0
        if ~nvp.HasToolCalls
            aisdk.internal.throwError("aisdk:modelReturnedNoOutput");
        end
        return
    end
    try
        result = jsondecode(result);
    catch
        aisdk.internal.throwError("aisdk:apiReturnedIncompleteJSON",result);
    end
    % A model with nothing to list may answer "null" instead of wrapping
    % an empty list; keep the empty result and let useSameFieldTypes
    % below turn it into an empty struct of the expected form.
    if ~isscalar(responseFormat) && ~isempty(result)
        result = result.result;
    end
    result = aisdk.client.internal.useSameFieldTypes(result,responseFormat);
end
