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

        function constructed_declaresOnlyRequiredNameInput(testCase)
            tool = testCase.createTool();
            inputs = tool.InputArguments;
            testCase.assertNumElements(inputs, 1);
            % "name" is fixed by the tool schema, independent of the registered skill name.
            testCase.verifyEqual(inputs.Name, "name");
            testCase.verifyEqual(inputs.DataType, "string");
            testCase.verifyTrue(inputs.Required);
        end

        function evaluateWithSkillName_returnsBody(testCase)
            tool = testCase.createTool();
            output = tool.evaluate(struct('name', 'test-skill'));
            testCase.verifyEqual(output, "Body of test-skill.");
        end

        function evaluateWithResourcePath_returnsContent(testCase)
            tool = testCase.createToolWithResource();
            output = tool.evaluate(struct('name', 'res-skill/references/guide.md'));
            testCase.verifyEqual(output, "guide content");
        end

        function evaluateWithFolderResourcePath_throwsSkillNotFound(testCase)
            tool = testCase.createToolWithResource();

            testCase.verifyError( ...
                @() tool.evaluate(struct('name', 'res-skill-folder/references/guide.md')), ...
                "aisdk:skills:SkillNotFound");
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
            skillDir = fullfile(tmpDir, "res-skill-folder");
            mkdir(skillDir);
            refsDir = fullfile(skillDir, "references");
            mkdir(refsDir);
            writelines(["---"; "name: res-skill"; "description: has resources"; "---"; "Body"], ...
                fullfile(skillDir, "SKILL.md"));
            file = fopen(fullfile(refsDir, "guide.md"), 'w');
            cleanup = onCleanup(@() fclose(file));
            fprintf(file, '%s', "guide content");
            clear cleanup
            reg = aisdk.internal.SkillRegistry(tmpDir);
            tool = aisdk.tool.LoadSkillTool(reg);
        end
    end
end
