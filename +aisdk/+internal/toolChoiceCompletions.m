function choices = toolChoiceCompletions(agent)
% This function is undocumented and will change in a future release

%toolChoiceCompletions Candidate values for the run ToolChoice argument.
%   CHOICES = toolChoiceCompletions(AGENT) returns the values that
%   run(AGENT, PROMPT, ToolChoice=CHOICE) accepts when Tools is not
%   specified: "auto" and "none", plus "required" and the name of each tool
%   when AGENT has any tools.

%   Copyright 2026 The MathWorks, Inc.

    choices = ["auto", "none", "required"];

    % Do not throw errors during tab completion.
    try
        if ~isa(agent, "aisdk.AIAgent") || ~isscalar(agent)
            return
        end
        tools = agent.Tools;
        if isempty(tools)
            choices = ["auto", "none"];
        else
            choices = [choices, tools.Name];
        end
    catch
        choices = ["auto", "none", "required"];
    end
end
