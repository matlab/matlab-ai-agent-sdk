classdef tSimulationGraphDefinition < matlab.unittest.TestCase
%TSIMULATIONGRAPHDEFINITION Verify the nested simulation's public behavior.

% Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addToPath(testCase)
            repoRoot = fileparts(fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath")))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'agentGallery', 'taskmaster')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'agentGallery', 'taskmaster', 'examples', 'nesting')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'helpers')));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function outerGraphRoutesIntoOneInnerGraph(testCase)
            [nodes, edges] = simulationGraphDefinition(MockClient());

            testCase.verifyEqual(edges, ["runSimulation", "reportResult"]);
            testCase.verifyClass(nodes(1), "agentgraph.AgentNode");
            testCase.verifyClass(nodes(2), "agentgraph.FunctionNode");
            graphTools = nodes(1).Agent.Tools(arrayfun(@(tool) ...
                isa(tool, "agentgraph.internal.GraphTargetTool"), nodes(1).Agent.Tools));
            testCase.verifyNumElements(graphTools, 1);
            testCase.verifyEqual([graphTools.Graph.Nodes.Name], ...
                ["configureModel", "solveModel", "checkResult"]);
        end

        function innerSimulationProducesCheckedResult(testCase)
            [nodes, ~] = simulationGraphDefinition(MockClient());
            graphTools = nodes(1).Agent.Tools(arrayfun(@(tool) ...
                isa(tool, "agentgraph.internal.GraphTargetTool"), nodes(1).Agent.Tools));
            inner = graphTools.Graph;

            [~, workspace] = inner.traverse("", struct());

            testCase.verifyEqual(workspace.displacementMm, 2);
            testCase.verifyEqual(workspace.limitMm, 3);
            testCase.verifyTrue(workspace.passed);
            testCase.verifyEqual(agentgraph.utils.nodeTrace(workspace, "inner"), ...
                ["configureModel", "solveModel", "checkResult"]);
        end
    end
end
