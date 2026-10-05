classdef tBuiltInTool < matlab.unittest.TestCase
% Tests for aisdk.tool.internal.BuiltInTool.

%   Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addResourcesToPath(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(fileparts(fileparts( ...
                mfilename('fullpath'))), "resources", "functions")));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function isSubclassOfCallableTool(testCase)
            tool = testCase.createLoadSkillTool();
            testCase.verifyInstanceOf(tool, 'aisdk.tool.internal.CallableTool');
        end

        function concatenatesWithOtherToolTypes(testCase)
            builtIn = testCase.createLoadSkillTool();
            local = aisdk.LLMTool(@addTwoNumbers);
            arr = [builtIn, local];
            testCase.verifyLength(arr, 2);
            testCase.verifyInstanceOf(arr, 'aisdk.tool.LLMTool');
        end

        function disp_arrayDisplay_showsBuiltInTypeLabel(testCase)
            tool = testCase.createLoadSkillTool();
            arr = [tool, tool];
            output = evalc('disp(arr)');
            testCase.verifySubstring(output, "built-in");
            testCase.verifySubstring(output, "loadSkill");
        end
    end

    methods (Access = private)
        function tool = createLoadSkillTool(~)
            findFcn = @(~) "/path/skill/SKILL.md";
            readFcn = @(~) sprintf("---\nname: skill\ndescription: d\n---\nBody");
            reg = aisdk.internal.SkillRegistry(pwd, ...
                DiscoverSkillsFcn=findFcn, FileReadFcn=readFcn, LastModifiedFcn=@(~) 1);
            tool = aisdk.tool.LoadSkillTool(reg);
        end
    end
end
