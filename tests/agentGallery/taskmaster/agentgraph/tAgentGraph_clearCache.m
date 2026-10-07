classdef tAgentGraph_clearCache < matlab.unittest.TestCase
%TAGENTGRAPH_CLEARCACHE  Public cache clearing at one graph layer.

% Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addToPath(testCase)
            root = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(root, "agentGallery", "taskmaster")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(root, "tests", "helpers")));
        end
    end

    methods (Test, TestTags = {'Integration'})
        function withoutNode_clearsImmediateLayer(testCase)
            [outer, inner, router] = nestedFixture();

            router.run("first");
            router.Workspace = outer.clearCache(router.Workspace);
            router.run("second");

            testCase.verifyEqual(router.Workspace.counts.outer, 2);
            testCase.verifyEqual(router.Workspace.counts.inner, 1);
            testCase.verifyEqual(agentgraph.utils.nodeTrace( ...
                router.Workspace, "outer.inner"), "A");
            testCase.verifyEqual(inner.Name, "inner");
        end

        function withNode_clearsNodeAndDownstream(testCase)
            nodes = [countedNode("A", "A"); countedNode("B", "B"); ...
                countedNode("C", "C")];
            graph = agentgraph.AgentGraph(nodes, ...
                ["A", "B"; "B", "C"], Name="inner");
            router = scriptedRouter(graph, "C", 2);

            router.run("first");
            router.Workspace = graph.clearCache(router.Workspace, Node="B");
            router.run("second");

            testCase.verifyEqual(router.Workspace.counts.A, 1);
            testCase.verifyEqual(router.Workspace.counts.B, 2);
            testCase.verifyEqual(router.Workspace.counts.C, 2);
        end

        function withSharedName_clearsEveryOccurrence(testCase)
            leftGraph = oneNodeGraph("shared", "left");
            rightGraph = oneNodeGraph("shared", "right");
            otherGraph = oneNodeGraph("different", "other");
            nodes = [
                agentgraph.AgentNode("left", scriptedRouter(leftGraph, "A", 2), ...
                    Description="Left branch", ClearHistory=false)
                agentgraph.AgentNode("right", scriptedRouter(rightGraph, "A", 2), ...
                    Description="Right branch", ClearHistory=false)
                agentgraph.AgentNode("other", scriptedRouter(otherGraph, "A", 2), ...
                    Description="Other branch", ClearHistory=false)
            ];
            outer = agentgraph.AgentGraph(nodes, ...
                ["left", "right"; "right", "other"], Name="outer");

            [~, workspace] = outer.traverse("first", struct());
            workspace = leftGraph.clearCache(workspace);
            [~, workspace] = outer.traverse("second", workspace);

            testCase.verifyEqual(workspace.counts.left, 2);
            testCase.verifyEqual(workspace.counts.right, 2);
            testCase.verifyEqual(workspace.counts.other, 1);
        end

        function onInnerGraph_preservesParentCache(testCase)
            [~, inner, router] = nestedFixture();

            router.run("first");
            router.Workspace = inner.clearCache(router.Workspace);
            router.run("second");

            testCase.verifyEqual(router.Workspace.counts.outer, 1);
            testCase.verifyEqual(router.Workspace.counts.inner, 1);
        end
    end

    methods (Test, TestTags = {'Unit'})
        function withUnknownNode_throwsUnknownNode(testCase)
            graph = oneNodeGraph("inner", "inner");

            testCase.verifyError( ...
                @() graph.clearCache(struct(), Node="missing"), ...
                "agentgraph:clearCacheUnknownNode");
        end
    end
end

function [outer, inner, router] = nestedFixture()
inner = oneNodeGraph("inner", "inner");
innerRouter = scriptedRouter(inner, "A", 2);
nodes = [countedNode("start", "outer"); ...
    agentgraph.AgentNode("inner", innerRouter, ...
        Description="Run inner graph", ClearHistory=false)];
outer = agentgraph.AgentGraph(nodes, ["start", "inner"], Name="outer");
router = scriptedRouter(outer, "inner", 2);
end

function graph = oneNodeGraph(graphName, counterName)
graph = agentgraph.AgentGraph(countedNode("A", counterName), ...
    string.empty(0,2), Name=graphName);
end

function node = countedNode(name, counterName)
node = agentgraph.FunctionNode(name, @(w) countRun(w, counterName), ...
    Description="Run " + name);
end

function [result, workspace] = countRun(workspace, counterName)
if ~isfield(workspace, "counts")
    workspace.counts = struct();
end
if ~isfield(workspace.counts, counterName)
    workspace.counts.(counterName) = 0;
end
workspace.counts.(counterName) = workspace.counts.(counterName) + 1;
result = counterName + ":" + workspace.counts.(counterName);
end

function router = scriptedRouter(graph, target, runCount)
client = MockClient();
outputs = cell(2 * runCount, 1);
for i = 1:runCount
    outputs{2*i - 1} = {"", aisdk.LLMToolCallMessage("runToTargetNode", ...
        struct("TargetNode", target), ToolCallID="call_" + i), tokenInfo()};
    outputs{2*i} = {"Done", aisdk.LLMTextMessage("Done", Role="assistant"), ...
        tokenInfo()};
end
client.GenerateOutputs = outputs;
router = agentgraph.taskmaster(graph, client, DisplayMode="off");
end

function info = tokenInfo()
info = struct("Tokens", struct("NumInputTokens", 10, ...
    "NumOutputTokens", 5, "NumTotalTokens", 15, "NumCachedInputTokens", 0));
end
