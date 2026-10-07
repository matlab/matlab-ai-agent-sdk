classdef tCreateSerdesSystem < matlab.unittest.TestCase
%TCREATESERDESSYSTEM  Defaults must not depend on the caller's folder.

% Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addToPath(testCase)
            repoRoot = fileparts(mfilename("fullpath"));
            for i = 1:6
                repoRoot = fileparts(repoRoot);
            end
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, "agentGallery", "taskmaster", ...
                    "examples", "serdes", "tools")));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function createSerdesSystem_withCurrentFolderConfig_usesToolDefaults(testCase)
            temp = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture());
            testCase.applyFixture( ...
                matlab.unittest.fixtures.CurrentFolderFixture(temp.Folder));
            file = fopen(fullfile(temp.Folder, "config.json"), "w");
            testCase.assertGreaterThan(file, 0);
            fprintf(file, '{"DataRate":56000000000,"modulation":4,"samplesPerSymbol":64,"berTarget":0.001}');
            fclose(file);

            [~, workspace] = createSerdesSystem(struct());

            testCase.verifyEqual(workspace.systemConfig.dataRate, 28e9);
            testCase.verifyEqual(workspace.systemConfig.modulation, 2);
            testCase.verifyEqual(workspace.systemConfig.samplesPerSymbol, 16);
            testCase.verifyEqual(workspace.systemConfig.berTarget, 1e-6);
        end
    end
end
