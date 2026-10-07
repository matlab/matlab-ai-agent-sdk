classdef tRxSignoffGraphDefinition < matlab.unittest.TestCase
%TRXSIGNOFFGRAPHDEFINITION  Tool exposure for the flat/graph comparison.

% Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addToPath(testCase)
            repoRoot = fileparts(fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath")))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, "agentGallery", "taskmaster")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, "agentGallery", "taskmaster", "examples", "serdes")));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function rxSignoffGraphDefinition_exposesFourteenToolsToFlatComparison(testCase)
            allTools = createSerdesTools();
            [nodes, ~] = rxSignoffGraphDefinition(allTools, aisdk.LLMClient("openai", "gpt-4.1-mini"));
            names = strings(1,0);
            for i = 1:numel(nodes)
                names = union(names, [nodes(i).Agent.Tools.Name]);
            end

            testCase.verifyEqual(numel(names), 14);
            testCase.verifyTrue(all(ismember(names, [allTools.Name])));
        end
    end
end
