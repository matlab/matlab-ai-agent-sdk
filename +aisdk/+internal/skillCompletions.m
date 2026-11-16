function names = skillCompletions(agent, skillName)
% This function is undocumented and will change in a future release

%skillCompletions Candidate values for the loadSkill name argument.
%   NAMES = skillCompletions(AGENT) returns the skill names that
%   loadSkill(AGENT,SKILL) accepts. With SKILLNAME, returns that skill's
%   relative resource keys for completion of the optional resource path.

%   Copyright 2026 The MathWorks, Inc.

    names = strings(1, 0);

    % Do not throw errors during tab completion.
    try
        if ~isa(agent, "aisdk.AIAgent") || ~isscalar(agent)
            return
        end
        registry = agent.SkillRegistry;
        if isempty(registry)
            return
        end

        % For performance, report cached values without rescanning the file system.
        if nargin == 2
            names = registry.resourceCompletions(skillName);
        else
            names = reshape(string([registry.Skills.Name]), 1, []);
        end
    catch
        names = strings(1, 0);
    end
end
