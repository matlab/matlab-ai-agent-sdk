classdef tgraphLevels < matlab.unittest.TestCase
%TGRAPHLEVELS  Public graph-level workspace inspection.

% Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addToPath(testCase)
            root = fileparts(fileparts(fileparts(fileparts( ...
                fileparts(fileparts(mfilename("fullpath")))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(root, "agentGallery", "taskmaster")));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function withNestedRecords_returnsDottedPaths(testCase)
            workspace.agentgraph.outer.prompt = "outer request";
            workspace.agentgraph.outer.inner.prompt = "inner request";

            testCase.verifyEqual(agentgraph.utils.graphLevels(workspace), ...
                ["outer", "outer.inner"]);
        end
    end
end
