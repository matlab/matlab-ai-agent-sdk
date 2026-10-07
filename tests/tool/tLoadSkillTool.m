classdef tLoadSkillTool < matlab.unittest.TestCase
% Tests for aisdk.tool.LoadSkillTool.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})

        function constructed_isBuiltInTool(testCase)
            tool = testCase.createTool();
            testCase.verifyInstanceOf(tool, 'aisdk.tool.BuiltInTool');
        end

        function constructed_hasNameLoadSkill(testCase)
            tool = testCase.createTool();
            testCase.verifyEqual(tool.Name, "loadSkill");
        end

        function constructed_doesNotRequireApproval(testCase)
            tool = testCase.createTool();
            testCase.verifyEqual(tool.ApprovalRequest, aisdk.tool.ApprovalRequest.never);
        end

        function constructed_declaresNameInputArgument(testCase)
            tool = testCase.createTool();
            testCase.verifyEqual(numel(tool.InputArguments), 1);
            testCase.verifyEqual(tool.InputArguments(1).Name, "name");
            testCase.verifyEqual(tool.InputArguments(1).DataType, "string");
            testCase.verifyTrue(tool.InputArguments(1).Required);
        end

        function evaluateWithSkillName_returnsBody(testCase)
            tool = testCase.createTool();
            output = tool.evaluate(struct('name', 'test-skill'));
            testCase.verifyEqual(output, "Body of test-skill.");
        end

        function evaluateWithResourcePath_returnsContent(testCase)
            tool = testCase.createToolWithResource();
            output = tool.evaluate(struct('name', 'res-skill/references/guide.md'));
            testCase.verifySubstring(output, "guide content");
        end

        function description_referencesCorrectToolName(testCase)
            tool = testCase.createTool();
            testCase.verifySubstring(tool.Description, tool.Name);
        end

        function evaluateWithMalformedArgs_throwsRequiredArgumentNotFound(testCase)
            tool = testCase.createTool();
            testCase.verifyError( ...
                @() tool.evaluate(struct('bad_fieldname', 'skill-name')), ...
                "aisdk:requiredArgumentNotFound");
        end

    end

    methods (Access = private)
        function tool = createTool(testCase) %#ok<MANU>
            findFcn = @(~) "/path/test-skill/SKILL.md";
            readFcn = @(~) sprintf("---\nname: test-skill\ndescription: Test skill\n---\nBody of test-skill.");
            reg = aisdk.internal.SkillRegistry(pwd, ...
                DiscoverSkillsFcn=findFcn, FileReadFcn=readFcn, LastModifiedFcn=@(~) 1);
            tool = aisdk.tool.LoadSkillTool(reg);
        end

        function tool = createToolWithResource(testCase)
            tmpDir = testCase.createTemporaryFolder();
            skillDir = fullfile(tmpDir, "res-skill");
            mkdir(skillDir);
            refsDir = fullfile(skillDir, "references");
            mkdir(refsDir);
            writelines(["---"; "name: res-skill"; "description: has resources"; "---"; "Body"], ...
                fullfile(skillDir, "SKILL.md"));
            writelines("guide content", fullfile(refsDir, "guide.md"));
            reg = aisdk.internal.SkillRegistry(tmpDir);
            tool = aisdk.tool.LoadSkillTool(reg);
        end
    end
end
