function result = reformatOutput(result,responseFormat)
% This function is undocumented and will change in a future release

%reformatOutput - Create the expected struct for structured output

%   Copyright 2026 The MathWorks, Inc.

    if isstruct(responseFormat)
        try
            result = jsondecode(result);
        catch
            aisdk.internal.throwError("aisdk:apiReturnedIncompleteJSON",result);
        end
    end
    if isstruct(responseFormat) && ~isscalar(responseFormat)
        % A model with nothing to list may answer "null" instead of wrapping
        % an empty list; keep the empty result and let useSameFieldTypes
        % below turn it into an empty struct of the expected form.
        if ~isempty(result)
            result = result.result;
        end
    end
    if isstruct(responseFormat)
        result = aisdk.client.internal.useSameFieldTypes(result,responseFormat);
    end
end
