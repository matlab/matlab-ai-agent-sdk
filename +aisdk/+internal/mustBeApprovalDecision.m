function mustBeApprovalDecision(decision)
% This function is undocumented and will change in a future release

% Copyright 2026 The MathWorks, Inc.
    if ~isstruct(decision) || ~isscalar(decision)
        aisdk.internal.throwError("aisdk:agent:approvalDecisionNotStruct", class(decision));
    end

    flags = ["Approved", "Permanent"];
    for field = [flags, "Reason"]
        if ~isfield(decision, field)
            aisdk.internal.throwError("aisdk:agent:approvalDecisionMissingField", field);
        end
    end

    for field = flags
        value = decision.(field);
        if ~islogical(value) || ~isscalar(value)
            aisdk.internal.throwError("aisdk:agent:approvalDecisionFlagNotLogical", field);
        end
    end

    reason = decision.Reason;
    stringScalar = isstring(reason) && isscalar(reason);
    charRow = ischar(reason) && (isrow(reason) || isempty(reason));
    if ~stringScalar && ~charRow
        aisdk.internal.throwError("aisdk:agent:approvalDecisionReasonNotText");
    end
end
