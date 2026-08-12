classdef tAgentGraph < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addToPath(testCase)
            repoRoot = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'demos', 'serdes')));
        end
    end

    methods (Test, TestTags = {'Unit'})

        %% executionOrder

        function executionOrder_linearChain_returnsSourceToSink(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a",w))
                agentgraph.FunctionNode("B", @(w) deal("b",w))
                agentgraph.FunctionNode("C", @(w) deal("c",w))
            ];
            edges = ["A","B"; "B","C"];
            g = agentgraph.AgentGraph(nodes, edges);

            names = g.executionOrder();

            testCase.verifyEqual(names, ["A","B","C"]);
        end

        function executionOrder_diamondDAG_respectsDependencyOrder(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a",w))
                agentgraph.FunctionNode("B", @(w) deal("b",w))
                agentgraph.FunctionNode("C", @(w) deal("c",w))
                agentgraph.FunctionNode("D", @(w) deal("d",w))
            ];
            edges = ["A","B"; "A","C"; "B","D"; "C","D"];
            g = agentgraph.AgentGraph(nodes, edges);

            names = g.executionOrder();

            posA = find(names == "A");
            posB = find(names == "B");
            posC = find(names == "C");
            posD = find(names == "D");
            testCase.verifyLessThan(posA, posB);
            testCase.verifyLessThan(posA, posC);
            testCase.verifyLessThan(posB, posD);
            testCase.verifyLessThan(posC, posD);
        end

        function executionOrder_cyclicGraph_throwsCyclicGraphError(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a",w))
                agentgraph.FunctionNode("B", @(w) deal("b",w))
            ];
            edges = ["A","B"; "B","A"];
            g = agentgraph.AgentGraph(nodes, edges);

            testCase.verifyError(@() g.executionOrder(), "agentgraph:cyclicGraph");
        end

        function executionOrder_withGoalNode_returnsAncestorsAndGoal(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a",w))
                agentgraph.FunctionNode("B", @(w) deal("b",w))
                agentgraph.FunctionNode("C", @(w) deal("c",w))
            ];
            edges = ["A","B"; "B","C"];
            g = agentgraph.AgentGraph(nodes, edges);

            names = g.executionOrder("B");

            testCase.verifyEqual(sort(names), sort(["A","B"]));
            testCase.verifyLessThan(find(names == "A"), find(names == "B"));
        end

        function executionOrder_goalWithNoAncestors_returnsSingleNode(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a",w))
                agentgraph.FunctionNode("B", @(w) deal("b",w))
            ];
            edges = ["A","B"];
            g = agentgraph.AgentGraph(nodes, edges);

            names = g.executionOrder("A");

            testCase.verifyEqual(names, "A");
        end

        %% getNode

        function getNode_existingName_returnsNode(testCase)
            nodeB = agentgraph.FunctionNode("B", @(w) deal("b",w));
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a",w))
                nodeB
            ];
            edges = ["A","B"];
            g = agentgraph.AgentGraph(nodes, edges);

            result = g.getNode("B");

            testCase.verifyEqual(result.Name, "B");
        end

        function getNode_missingName_throwsNodeNotFound(testCase)
            nodes = agentgraph.FunctionNode("A", @(w) deal("a",w));
            g = agentgraph.AgentGraph(nodes, string.empty(0,2));

            testCase.verifyError(@() g.getNode("Z"), "agentgraph:NodeNotFound");
        end

        %% describeNodes

        function describeNodes_withDescriptions_returnsBulletLines(testCase)
            nodes = [
                agentgraph.FunctionNode("build", @(w) deal("",w))
                agentgraph.FunctionNode("test", @(w) deal("",w))
            ];
            nodes(1).Description = "Compile the project";
            nodes(2).Description = "Run tests";
            edges = ["build","test"];
            g = agentgraph.AgentGraph(nodes, edges);

            text = g.describeNodes();

            testCase.verifySubstring(text, "- build: Compile the project");
            testCase.verifySubstring(text, "- test: Run tests");
        end

        function describeNodes_emptyDescription_omitsColon(testCase)
            nodes = agentgraph.FunctionNode("build", @(w) deal("",w));
            g = agentgraph.AgentGraph(nodes, string.empty(0,2));

            text = g.describeNodes();

            testCase.verifyEqual(text, "- build");
        end

        %% buildNodePrompt

        function buildNodePrompt_emptyHistory_returnsPromptOnly(testCase)
            g = agentgraph.AgentGraph( ...
                agentgraph.FunctionNode("A", @(w) deal("",w)), ...
                string.empty(0,2));

            nodePrompt = g.buildNodePrompt("Do the thing", strings(1,0));

            testCase.verifyEqual(nodePrompt, "Do the thing");
        end

        function buildNodePrompt_withHistory_appendsTranscript(testCase)
            g = agentgraph.AgentGraph( ...
                agentgraph.FunctionNode("A", @(w) deal("",w)), ...
                string.empty(0,2));
            history = ["nodeA: result1", "nodeB: result2"];

            nodePrompt = g.buildNodePrompt("Do the thing", history);

            testCase.verifySubstring(nodePrompt, "Do the thing");
            testCase.verifySubstring(nodePrompt, "Previous stages completed:");
            testCase.verifySubstring(nodePrompt, "nodeA: result1");
            testCase.verifySubstring(nodePrompt, "nodeB: result2");
        end
    end
end
