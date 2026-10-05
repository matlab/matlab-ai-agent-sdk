classdef ttoolChoiceCompletions < matlab.unittest.TestCase
% Tests for aisdk.internal.toolChoiceCompletions.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        NotAnAgent = {42, "text", [], struct("Tools", 1), {1, 2}}
    end

    methods (TestClassSetup)
        function addResourcesToPath(testCase)
            testsRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testsRoot, "helpers")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testsRoot, "resources", "functions")));
        end
    end

    methods (Test, TestTags = {'Unit'})

        function agentWithoutTools_offersAutoAndNone(testCase)
            % Without tools, ToolChoice must be "auto" or "none".
            agent = aisdk.AIAgent(MockClient());
            testCase.verifyEqual(aisdk.internal.toolChoiceCompletions(agent), ...
                ["auto", "none"]);
        end

        function agentWithTools_offersRequiredAndEachToolName(testCase)
            agent = aisdk.AIAgent(MockClient(), Tools=[ ...
                aisdk.LLMTool(@addTwoNumbers), ...
                aisdk.LLMTool(@addTwoNumbersUsingNVP)]);
            testCase.verifyEqual(aisdk.internal.toolChoiceCompletions(agent), ...
                ["auto", "none", "required", "addTwoNumbers", "addTwoNumbersUsingNVP"]);
        end

        function agentWithSkills_offersLoadSkillTool(testCase)
            tmpDir = testCase.createTemporaryFolder();
            skillDir = fullfile(tmpDir, "my-skill");
            mkdir(skillDir);
            writelines(["---"; "name: my-skill"; "description: desc"; "---"; "Body"], ...
                fullfile(skillDir, "SKILL.md"));
            agent = aisdk.AIAgent(MockClient(), SkillDirectories=tmpDir);

            testCase.verifyEqual(aisdk.internal.toolChoiceCompletions(agent), ...
                ["auto", "none", "required", "loadSkill"]);
        end

        function notAnAgent_offersKeywords(testCase, NotAnAgent)
            testCase.verifyEqual(aisdk.internal.toolChoiceCompletions(NotAnAgent), ...
                ["auto", "none", "required"]);
        end

        function nonscalarAgent_offersKeywords(testCase)
            agent = aisdk.AIAgent(MockClient());
            testCase.verifyEqual(aisdk.internal.toolChoiceCompletions([agent, agent]), ...
                ["auto", "none", "required"]);
        end

    end

end
