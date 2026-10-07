classdef tnodeTrace < matlab.unittest.TestCase
%TNODETRACE  Public completed-node inspection.

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
        function withCompletedNodes_returnsExecutionOrder(testCase)
            nodes = [agentgraph.FunctionNode("A", @(w) deal("A", w)), ...
                agentgraph.FunctionNode("B", @(w) deal("B", w))];
            graph = agentgraph.AgentGraph(nodes, ["A", "B"], Name="outer");
            [~, workspace] = graph.traverse("request", struct());

            testCase.verifyEqual(agentgraph.utils.nodeTrace(workspace, "outer"), ...
                ["A", "B"]);
        end
    end
end
