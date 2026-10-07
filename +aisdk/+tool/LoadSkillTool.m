classdef LoadSkillTool < aisdk.tool.BuiltInTool
%LoadSkillTool Built-in tool that loads a skill's full instructions.

% Copyright 2026 The MathWorks, Inc.

    properties (Access = private)
        Registry
    end

    methods (Hidden)
        function this = LoadSkillTool(registry)
            this.Registry = registry;
            this.Name = "loadSkill";
            this.Description = "Load a skill's full content into your context so you can follow its instructions." + newline + newline + ...
                "Skills are listed in your system instructions. When you need to use one, load it first" + newline + ...
                "to get the detailed instructions. After reading a skill, load any files it references " + newline + ...
                "(e.g. ""See references/foo.md"") before proceeding with the task." + newline + newline + ...
                "Examples:" + newline + ...
                "- loadSkill(name: ""gdrive"") -> Loads the gdrive skill instructions" + newline + ...
                "- loadSkill(name: ""my-skill/references/guide.md"") -> Loads a supporting file referenced by the skill";
            this.DisplayTitle = "Load Skill";
            % Loading a skill only reads files from the user's SkillDirectories.
            this.ApprovalRequest = "never";
            this.InputArguments = aisdk.LLMToolArgument("name", ...
                Description="Name of the skill to load. Use ""skill-name/path"" to load a supporting file.", ...
                DataType="string", Required=true);
        end
    end

    methods (Access = protected)
        function [output, workspace] = evaluateImpl(this, args, workspace)
            if ~isfield(args, 'name')
                aisdk.internal.throwError("aisdk:requiredArgumentNotFound", "name");
            end
            output = this.Registry.loadSkillImpl(args.name);
        end
    end
end
