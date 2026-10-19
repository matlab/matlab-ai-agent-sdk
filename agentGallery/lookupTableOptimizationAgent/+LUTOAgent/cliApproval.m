function result = cliApproval(tool, toolArguments)
%cliApproval Command-window approval prompt for mutating tool calls.
%   Drop-in ApprovalFcn for aisdk.AIAgent. Prints the tool name and its
%   arguments, then asks the user to approve (y), deny (n), or approve all
%   future calls to the tool (a). Returns a struct with Approved, Permanent,
%   and Reason fields.

% Copyright 2026 The MathWorks, Inc.

    arguments
        tool
        toolArguments
    end

    fprintf("\n");
    fprintf("---------------------------------------------------------------\n");
    fprintf(" Approval required for tool: %s\n", tool.Name);
    fprintf(" Arguments: %s\n", jsonencode(toolArguments));
    fprintf("---------------------------------------------------------------\n");

    result = struct("Approved", false, "Permanent", false, "Reason", "");
    while true
        answer = lower(strtrim(string(input(" Approve? [y]es / [n]o / [a]lways: ", "s"))));
        switch answer
            case {"y","yes"}
                result.Approved = true;
                return
            case {"a","always"}
                result.Approved = true;
                result.Permanent = true;
                return
            case {"n","no",""}
                result.Approved = false;
                reason = strtrim(string(input(" Reason for denial (optional): ", "s")));
                result.Reason = reason;
                return
            otherwise
                fprintf(" Please answer y, n, or a.\n");
        end
    end
end
