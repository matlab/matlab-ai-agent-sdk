classdef tskillCompletions < matlab.unittest.TestCase
% Tests for aisdk.internal.skillCompletions.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        NotAnAgent = {42, "text", [], struct("SkillRegistry", 1), {1, 2}}
    end

    methods (TestClassSetup)
        function addResourcesToPath(testCase)
            testsRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testsRoot, "helpers")));
        end
    end

    methods (Test, TestTags = {'Unit'})

        function returnsEachSkillNameAndResource(testCase)
            % Both loadSkill syntaxes see every candidate, for discoverability.
            agent = testCase.createAgentWithSkills();
            names = aisdk.internal.skillCompletions(agent);
            testCase.verifyEqual(sort(names), ["datacleaning", "livescript", ...
                "livescript/example.m", "livescript/references/guide.md"]);
        end

        function skillWithoutSupportingFiles_contributesOnlyItsName(testCase)
            tmpDir = testCase.createTemporaryFolder();
            testCase.writeSkill(tmpDir, "datacleaning");
            agent = aisdk.AIAgent(MockClient(), SkillDirectories=tmpDir);

            testCase.verifyEqual(aisdk.internal.skillCompletions(agent), "datacleaning");
        end

        function skillAddedAfterConstruction_isNotOffered(testCase)
            % Completion reports the cached registry rather than rescanning.
            tmpDir = testCase.createTemporaryFolder();
            testCase.writeSkill(tmpDir, "livescript");
            agent = aisdk.AIAgent(MockClient(), SkillDirectories=tmpDir);
            testCase.writeSkill(tmpDir, "addedlater");

            testCase.verifyEqual(aisdk.internal.skillCompletions(agent), "livescript");
        end

        function agentWithoutSkillDirectories_returnsEmptyRow(testCase)
            agent = aisdk.AIAgent(MockClient());
            testCase.verifyEqual(aisdk.internal.skillCompletions(agent), strings(1, 0));
        end

        function notAnAgent_returnsEmptyRow(testCase, NotAnAgent)
            testCase.verifyEqual(aisdk.internal.skillCompletions(NotAnAgent), ...
                strings(1, 0));
        end

        function nonscalarAgent_returnsEmptyRow(testCase)
            agent = testCase.createAgentWithSkills();
            agents = [agent, agent];
            testCase.verifyEqual(aisdk.internal.skillCompletions(agents), ...
                strings(1, 0));
        end

    end

    methods (Access = private)

        function agent = createAgentWithSkills(testCase)
            tmpDir = testCase.createTemporaryFolder();
            skillDir = testCase.writeSkill(tmpDir, "livescript");
            writelines("example content", fullfile(skillDir, "example.m"));
            mkdir(fullfile(skillDir, "references"));
            writelines("guide content", fullfile(skillDir, "references", "guide.md"));
            testCase.writeSkill(tmpDir, "datacleaning");
            agent = aisdk.AIAgent(MockClient(), SkillDirectories=tmpDir);
        end

        function skillDir = writeSkill(~, parentDir, name)
            skillDir = fullfile(parentDir, name);
            mkdir(skillDir);
            writelines(["---"; "name: " + name; "description: desc"; "---"; "Body"], ...
                fullfile(skillDir, "SKILL.md"));
        end

    end

end
