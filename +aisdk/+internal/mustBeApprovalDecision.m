function mustBeApprovalDecision(decision)
% This function is undocumented and will change in a future release

% Copyright 2026 The MathWorks, Inc.
    if ~isstruct(decision) || ~isscalar(decision)
        error("aisdk:agent:approvalDecisionNotStruct", ...
            aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:agent:approvalDecisionNotStruct", class(decision)));
    end

    flags = ["Approved", "Permanent"];
    for field = [flags, "Reason"]
        if ~isfield(decision, field)
            error("aisdk:agent:approvalDecisionMissingField", ...
                aisdk.internal.MessageCatalog.getMessage( ...
                    "aisdk:agent:approvalDecisionMissingField", field));
        end
    end

    for field = flags
        value = decision.(field);
        if ~islogical(value) || ~isscalar(value)
            error("aisdk:agent:approvalDecisionFlagNotLogical", ...
                aisdk.internal.MessageCatalog.getMessage( ...
                    "aisdk:agent:approvalDecisionFlagNotLogical", field));
        end
    end

    reason = decision.Reason;
    stringScalar = isstring(reason) && isscalar(reason);
    charRow = ischar(reason) && (isrow(reason) || isempty(reason));
    if ~stringScalar && ~charRow
        error("aisdk:agent:approvalDecisionReasonNotText", ...
            aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:agent:approvalDecisionReasonNotText"));
    end
end
