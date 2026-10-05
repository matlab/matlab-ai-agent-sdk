classdef tSkill < matlab.unittest.TestCase
% Tests for aisdk.internal.Skill.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})

        function constructedWithFields_exposesNameBodyDescription(testCase)
            skill = aisdk.internal.Skill("my-skill", "A description", "/path/SKILL.md", "Body text");
            testCase.verifyEqual(skill.Name, "my-skill");
            testCase.verifyEqual(skill.Description, "A description");
            testCase.verifyEqual(skill.Path, "/path/SKILL.md");
            testCase.verifyEqual(skill.Body, "Body text");
        end

        function constructedWithResources_returnsContentByRelPath(testCase)
            resources = dictionary;
            resources("references/guide.md") = "guide content";
            skill = aisdk.internal.Skill("s", "d", "/p", "body", resources);
            testCase.verifyEqual(skill.Resources("references/guide.md"), "guide content");
        end

        function constructedWithNoResources_hasEmptyResourceDict(testCase)
            skill = aisdk.internal.Skill("s", "d", "/p", "body");
            testCase.verifyEqual(skill.Resources, dictionary);
        end

    end
end
