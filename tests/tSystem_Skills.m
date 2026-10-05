classdef tSystem_Skills < matlab.unittest.TestCase
% tSystem - Tests verifying the high-level requirements for skills support.

%   Copyright 2026 The MathWorks, Inc.

    properties
        Client = aisdk.LLMClient("openai", "gpt-4.1-mini", Temperature=0)
    end

    properties (Constant, Access=private)
        SkillBody = "When reviewing, prefer arguments blocks over inputParser."
        ResourceContent = "Checklist: name functions as verbs."
        ResourcePath = "code-review/references/checklist.md"
    end

    properties (Access=private)
        SkillsRoot (1,1) string
    end

    methods (TestMethodSetup)
        function createSkills(testCase)
            % Two skills, one of them with a supporting resource, so that
            % every test works against a realistic catalog.
            testCase.SkillsRoot = testCase.createTemporaryFolder();
            testCase.writeSkill(fullfile(testCase.SkillsRoot, "summarize"), "summarize", ...
                "Summarize text into concise bullet points.", "Summarize body.");
            testCase.writeSkill(fullfile(testCase.SkillsRoot, "code-review"), "code-review", ...
                "Review MATLAB code for quality issues.", testCase.SkillBody, ...
                Resources=dictionary("references/checklist.md", testCase.ResourceContent));
        end
    end

    methods (Test, TestTags = {'System'})

        %% Agents discover skills without loading their content

        function construct_withSkillDirectories_catalogsSkillsWithoutBodies(testCase)
            agent = aisdk.AIAgent(testCase.Client, ...
                SkillDirectories=testCase.SkillsRoot, DisplayMode="off");

            testCase.verifyEqual(sort(agent.Skills), ["code-review"; "summarize"]);

            % Names and descriptions are advertised to the model, but the
            % skill body does not occupy the context until it is loaded.
            import matlab.unittest.constraints.ContainsSubstring
            context = testCase.getStoredPromptAndCatalog(agent);
            testCase.verifyThat(context, ContainsSubstring("code-review"));
            testCase.verifyThat(context, ...
                ContainsSubstring("Review MATLAB code for quality issues."));
            testCase.verifyThat(context, ~ContainsSubstring(testCase.SkillBody));
        end

        %% Skills can be loaded on demand by the user

        function loadSkill_withSkillName_injectsSkillBody(testCase)
            agent = aisdk.AIAgent(testCase.Client, ...
                SkillDirectories=testCase.SkillsRoot, DisplayMode="off");

            loadSkill(agent, "code-review");

            results = testCase.getToolResults(agent);
            testCase.assertNotEmpty(results, "loadSkill should inject a tool result.");
            testCase.verifySubstring(results(end).Result, testCase.SkillBody);
        end

        %% Skills can be loaded on demand by the model

        function run_withLLMRequestedSkill_injectsSkillBody(testCase)
            agent = aisdk.AIAgent(testCase.Client, ...
                SkillDirectories=testCase.SkillsRoot, DisplayMode="off");

            run(agent, "Load the code-review skill.", ToolChoice="loadSkill");

            % ToolChoice only forces the first call, and the loop keeps
            % running afterwards: the model often spends a later turn loading
            % a supporting file. Assert on the forced call, not the last one.
            results = testCase.getToolResults(agent);
            testCase.assertNotEmpty(results, ...
                "The model should have called the loadSkill tool.");
            testCase.verifySubstring(results(1).Result, testCase.SkillBody);
        end

        function run_withLLMRequestedResource_injectsResourceContent(testCase)
            agent = aisdk.AIAgent(testCase.Client, ...
                SkillDirectories=testCase.SkillsRoot, DisplayMode="off");

            run(agent, "Load the skill resource named """ + testCase.ResourcePath + """.", ...
                ToolChoice="loadSkill");

            results = testCase.getToolResults(agent);
            testCase.assertNotEmpty(results, ...
                "The model should have called the loadSkill tool.");
            testCase.verifySubstring(results(1).Result, testCase.ResourceContent);
        end

    end

    methods (Access=private)

        function writeSkill(~, skillDir, name, description, body, nvp)
            arguments
                ~
                skillDir
                name
                description
                body
                nvp.Resources dictionary = dictionary(string.empty, string.empty)
            end
            mkdir(skillDir);
            writelines(["---"; "name: " + name; "description: " + description; ...
                "---"; body], fullfile(skillDir, "SKILL.md"));
            relPaths = keys(nvp.Resources);
            for k = 1:numel(relPaths)
                resourceFile = fullfile(skillDir, relPaths(k));
                mkdir(fileparts(resourceFile));
                writelines(nvp.Resources(relPaths(k)), resourceFile);
            end
        end

        function str = getStoredPromptAndCatalog(~, agent)
            % jsonencode serializes the filtered messages without naming a
            % content property: an empty selection of this heterogeneous array
            % is typed as the base class, so reading .Text/.Result would error
            % and require extra test logic to guard.
            msgs = agent.Messages;
            str = join([string(agent.SystemPrompt), ...
                agent.SkillRegistry.CatalogText, ...
                string(jsonencode(msgs(string([msgs.Type]) == "text")))], newline);
        end

        function results = getToolResults(~, agent)
            msgs = agent.Messages;
            results = msgs(string([msgs.Role]) == "tool");
        end

    end
end

