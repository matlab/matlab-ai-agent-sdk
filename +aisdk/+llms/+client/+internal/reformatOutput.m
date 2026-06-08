function result = reformatOutput(result,responseFormat)
% This function is undocumented and will change in a future release

%reformatOutput - Create the expected struct for structured output

%   Copyright 2026 The MathWorks, Inc.

    if isstruct(responseFormat)
        try
            result = jsondecode(result);
        catch
            error("llms:apiReturnedIncompleteJSON",aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:apiReturnedIncompleteJSON",result))
        end
    end
    if isstruct(responseFormat) && ~isscalar(responseFormat)
        result = result.result;
    end
    if isstruct(responseFormat)
        result = aisdk.llms.client.internal.useSameFieldTypes(result,responseFormat);
    end
end
