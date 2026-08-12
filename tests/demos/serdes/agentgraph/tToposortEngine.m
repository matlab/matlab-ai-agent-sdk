classdef tToposortEngine < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addToPath(testCase)
            repoRoot = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'demos', 'serdes')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'demos', 'serdes', 'agentgraph', 'helpers')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'helpers')));
        end
    end

    methods (Test, TestTags = {'Unit'})

        function traverse_linearGraph_executesInOrder(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a", appendOrder(w,"A")))
                agentgraph.FunctionNode("B", @(w) deal("b", appendOrder(w,"B")))
                agentgraph.FunctionNode("C", @(w) deal("c", appendOrder(w,"C")))
            ];
            edges = ["A","B"; "B","C"];
            g = agentgraph.AgentGraph(nodes, edges);
            ws = struct('order', {{}});

            [~, wsOut] = g.run([], "go", ws, aisdk.llms.tool.LLMTool.empty(1,0));

            testCase.verifyEqual(wsOut.order, {"A","B","C"});
        end

        function traverse_diamondGraph_respectsDependencyOrder(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a", appendOrder(w,"A")))
                agentgraph.FunctionNode("B", @(w) deal("b", appendOrder(w,"B")))
                agentgraph.FunctionNode("C", @(w) deal("c", appendOrder(w,"C")))
                agentgraph.FunctionNode("D", @(w) deal("d", appendOrder(w,"D")))
            ];
            edges = ["A","B"; "A","C"; "B","D"; "C","D"];
            g = agentgraph.AgentGraph(nodes, edges);
            ws = struct('order', {{}});

            [~, wsOut] = g.run([], "go", ws, aisdk.llms.tool.LLMTool.empty(1,0));

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

        function traverse_singleNode_returnsItsResult(testCase)
            nodes = agentgraph.FunctionNode("only", @(w) deal("single",w));
            g = agentgraph.AgentGraph(nodes, string.empty(0,2));

            [result, ~] = g.run([], "go", struct(), aisdk.llms.tool.LLMTool.empty(1,0));

            testCase.verifyEqual(result, "single");
        end

        function traverse_returnsLastNodeResult(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("first",w))
                agentgraph.FunctionNode("B", @(w) deal("second",w))
                agentgraph.FunctionNode("C", @(w) deal("third",w))
            ];
            edges = ["A","B"; "B","C"];
            g = agentgraph.AgentGraph(nodes, edges);

            [result, ~] = g.run([], "go", struct(), aisdk.llms.tool.LLMTool.empty(1,0));

            testCase.verifyEqual(result, "third");
        end

        function traverse_threadsWorkspaceAcrossNodes(testCase)
            fcnA = @(w) deal("a", setfield(w, 'sum', 1));
            fcnB = @(w) deal("b", setfield(w, 'sum', w.sum + 10));
            fcnC = @(w) deal("c", setfield(w, 'sum', w.sum + 100));
            nodes = [
                agentgraph.FunctionNode("A", fcnA)
                agentgraph.FunctionNode("B", fcnB)
                agentgraph.FunctionNode("C", fcnC)
            ];
            edges = ["A","B"; "B","C"];
            g = agentgraph.AgentGraph(nodes, edges);

            [~, wsOut] = g.run([], "go", struct(), aisdk.llms.tool.LLMTool.empty(1,0));

            testCase.verifyEqual(wsOut.sum, 111);
        end

        function traverse_nodeHistoryPassedViaPrompt(testCase)
            tokenInfo = struct("Tokens", struct( ...
                "NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"resultA", aisdk.LLMTextMessage("resultA", Role="assistant"), tokenInfo}
                {"done", aisdk.LLMTextMessage("done", Role="assistant"), tokenInfo}
            };

            nodeA = agentgraph.AgentNode("A", SystemPrompt="", MaxIterations=1);
            nodeB = agentgraph.AgentNode("B", SystemPrompt="", MaxIterations=1);

            nodes = [nodeA, nodeB];
            edges = ["A","B"];
            g = agentgraph.AgentGraph(nodes, edges);

            g.run(client, "original prompt", struct(), aisdk.llms.tool.LLMTool.empty(1,0));

            msgs = client.GenerateInputs{2};
            promptSent = msgs(end).Text;
            testCase.verifySubstring(promptSent, "Previous stages completed:");
            testCase.verifySubstring(promptSent, "A: resultA");
        end

        function traverse_goalNode_runsOnlyAncestorsAndGoal(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a", appendOrder(w,"A")))
                agentgraph.FunctionNode("B", @(w) deal("b", appendOrder(w,"B")))
                agentgraph.FunctionNode("C", @(w) deal("c", appendOrder(w,"C")))
            ];
            edges = ["A","B"; "B","C"];
            g = agentgraph.AgentGraph(nodes, edges);
            ws = struct('order', {{}});

            [~, wsOut] = g.run([], "go", ws, aisdk.llms.tool.LLMTool.empty(1,0), GoalNode="B");

            testCase.verifyEqual(wsOut.order, {"A","B"});
        end

        function traverse_nodeThrows_propagatesError(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a",w))
                agentgraph.FunctionNode("B", @throwFail)
            ];
            edges = ["A","B"];
            g = agentgraph.AgentGraph(nodes, edges);

            testCase.verifyError( ...
                @() g.run([], "go", struct(), aisdk.llms.tool.LLMTool.empty(1,0)), "test:fail");
        end
    end
end

function w = appendOrder(w, name)
    w.order{numel(w.order)+1} = name;
end

function [result, ws] = throwFail(~) %#ok<STOUT>
    error("test:fail", "broken");
end
