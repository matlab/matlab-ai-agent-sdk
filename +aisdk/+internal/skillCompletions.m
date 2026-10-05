function names = skillCompletions(agent)
% This function is undocumented and will change in a future release

%skillCompletions Candidate values for the loadSkill name argument.
%   NAMES = skillCompletions(AGENT) returns the skill names that
%   loadSkill(AGENT,SKILL) accepts, followed by the skill-name/relative-path
%   combinations that loadSkill(AGENT,SKILLRESOURCE) accepts. Both syntaxes
%   offer the full list, for discoverability.

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
        resourcePaths = strings(1, 0);
        for skill = registry.Skills
            names(end+1) = skill.Name; %#ok<AGROW>
            resources = skill.Resources;
            if numEntries(resources) > 0
                relativePaths = reshape(string(keys(resources)), 1, []);
                resourcePaths = [resourcePaths, skill.Name + "/" + relativePaths]; %#ok<AGROW>
            end
        end
        names = [names, resourcePaths];
    catch
        names = strings(1, 0);
    end
end
