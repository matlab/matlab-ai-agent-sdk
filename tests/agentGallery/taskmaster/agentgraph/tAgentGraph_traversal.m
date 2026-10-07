classdef tAgentGraph_traversal < matlab.unittest.TestCase

% Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addToPath(testCase)
            repoRoot = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'agentGallery', 'taskmaster')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'agentGallery', 'taskmaster', 'agentgraph', 'helpers')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'helpers')));
        end
    end

    methods (Test, TestTags = {'Unit'})

        function linearGraph_executesInOrder(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a", appendOrder(w,"A")))
                agentgraph.FunctionNode("B", @(w) deal("b", appendOrder(w,"B")))
                agentgraph.FunctionNode("C", @(w) deal("c", appendOrder(w,"C")))
            ];
            edges = ["A","B"; "B","C"];
            g = agentgraph.AgentGraph(nodes, edges, Name="graph");
            ws = struct('order', {{}});

            [~, wsOut] = g.traverse("go", ws);

            testCase.verifyEqual(wsOut.order, {"A","B","C"});
        end

        function diamondGraph_respectsDependencyOrder(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a", appendOrder(w,"A")))
                agentgraph.FunctionNode("B", @(w) deal("b", appendOrder(w,"B")))
                agentgraph.FunctionNode("C", @(w) deal("c", appendOrder(w,"C")))
                agentgraph.FunctionNode("D", @(w) deal("d", appendOrder(w,"D")))
            ];
            edges = ["A","B"; "A","C"; "B","D"; "C","D"];
            g = agentgraph.AgentGraph(nodes, edges, Name="graph");
            ws = struct('order', {{}});

            [~, wsOut] = g.traverse("go", ws);

            order = string(wsOut.order);
            posA = find(order == "A");
            posB = find(order == "B");
            posC = find(order == "C");
            posD = find(order == "D");
            testCase.verifyLessThan(posA, posB);
            testCase.verifyLessThan(posA, posC);
            testCase.verifyLessThan(posB, posD);
            testCase.verifyLessThan(posC, posD);
        end

        function convergingY_runsBothSourcesBeforeSink(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a", appendOrder(w,"A")))
                agentgraph.FunctionNode("B", @(w) deal("b", appendOrder(w,"B")))
                agentgraph.FunctionNode("C", @(w) deal("c", appendOrder(w,"C")))
            ];
            g = agentgraph.AgentGraph(nodes, ["A","C"; "B","C"], Name="graph");
            ws = struct('order', {{}});

            [~, wsOut] = g.traverse("go", ws);

            order = string(wsOut.order);
            testCase.verifyEqual(sort(order), ["A","B","C"]);
            testCase.verifyEqual(order(end), "C");
        end

        function singleNode_returnsItsResult(testCase)
            nodes = agentgraph.FunctionNode("only", @(w) deal("single",w));
            g = agentgraph.AgentGraph(nodes, string.empty(0,2), Name="graph");

            [result, ~] = g.traverse("go", struct());

            testCase.verifyEqual(result, "single");
        end

        function returnsLastNodeResult(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("first",w))
                agentgraph.FunctionNode("B", @(w) deal("second",w))
                agentgraph.FunctionNode("C", @(w) deal("third",w))
            ];
            edges = ["A","B"; "B","C"];
            g = agentgraph.AgentGraph(nodes, edges, Name="graph");

            [result, ~] = g.traverse("go", struct());

            testCase.verifyEqual(result, "third");
        end

        function threadsWorkspaceAcrossNodes(testCase)
            fcnA = @(w) deal("a", setfield(w, 'sum', 1));
            fcnB = @(w) deal("b", setfield(w, 'sum', w.sum + 10));
            fcnC = @(w) deal("c", setfield(w, 'sum', w.sum + 100));
            nodes = [
                agentgraph.FunctionNode("A", fcnA)
                agentgraph.FunctionNode("B", fcnB)
                agentgraph.FunctionNode("C", fcnC)
            ];
            edges = ["A","B"; "B","C"];
            g = agentgraph.AgentGraph(nodes, edges, Name="graph");

            [~, wsOut] = g.traverse("go", struct());

            testCase.verifyEqual(wsOut.sum, 111);
        end

        function nodeHistoryPassedViaPrompt(testCase)
            tokenInfo = struct("Tokens", struct( ...
                "NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"resultA", aisdk.LLMTextMessage("resultA", Role="assistant"), tokenInfo}
                {"done", aisdk.LLMTextMessage("done", Role="assistant"), tokenInfo}
            };

            nodeA = agentgraph.AgentNode("A", aisdk.AIAgent(client, ...
                MaxIterations=1, DisplayMode="off"));
            nodeB = agentgraph.AgentNode("B", aisdk.AIAgent(client, ...
                MaxIterations=1, DisplayMode="off"));

            nodes = [nodeA, nodeB];
            edges = ["A","B"];
            g = agentgraph.AgentGraph(nodes, edges, Name="graph");

            g.traverse("original prompt", struct());

            msgs = client.GenerateInputs{2};
            promptSent = msgs(end).Text;
            testCase.verifySubstring(promptSent, "Previous stages completed:");
            testCase.verifySubstring(promptSent, "A: resultA");
        end

        function targetNode_runsOnlyAncestorsAndTarget(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a", appendOrder(w,"A")))
                agentgraph.FunctionNode("B", @(w) deal("b", appendOrder(w,"B")))
                agentgraph.FunctionNode("C", @(w) deal("c", appendOrder(w,"C")))
            ];
            edges = ["A","B"; "B","C"];
            g = agentgraph.AgentGraph(nodes, edges, Name="graph");
            ws = struct('order', {{}});

            [~, wsOut] = g.traverse("go", ws, TargetNode="B");

            testCase.verifyEqual(wsOut.order, {"A","B"});
        end

        function nodeThrows_propagatesError(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a",w))
                agentgraph.FunctionNode("B", @throwFail)
            ];
            edges = ["A","B"];
            g = agentgraph.AgentGraph(nodes, edges, Name="graph");

            testCase.verifyError( ...
                @() g.traverse("go", struct()), "test:fail");
        end
    end
end

function w = appendOrder(w, name)
    w.order{numel(w.order)+1} = name;
end

function [result, ws] = throwFail(~) %#ok<STOUT>
    error("test:fail", "broken");
end
