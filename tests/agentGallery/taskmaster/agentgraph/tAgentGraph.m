classdef tAgentGraph < matlab.unittest.TestCase

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
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'resources', 'functions')));
        end
    end

    methods (Test, TestTags = {'Unit'})

        %% Name and nodes

        function AgentGraph_withName_storesName(testCase)
            g = agentgraph.AgentGraph( ...
                agentgraph.FunctionNode("A", @(w) deal("a",w)), string.empty(0,2), ...
                Name="rxSignoff");

            testCase.verifyEqual(g.Name, "rxSignoff");
        end

        function withoutName_throwsMissingGraphName(testCase)
            node = agentgraph.FunctionNode("A", @(w) deal("a", w));

            testCase.verifyError( ...
                @() agentgraph.AgentGraph(node, string.empty(0,2)), ...
                "agentgraph:missingGraphName");
        end

        function withColumnNodes_storesRowNodes(testCase)
            nodes = [agentgraph.FunctionNode("A", @(w) deal("a", w)); ...
                agentgraph.FunctionNode("B", @(w) deal("b", w))];
            graph = agentgraph.AgentGraph(nodes, ["A", "B"], Name="graph");

            testCase.verifySize(graph.Nodes, [1, 2]);
            testCase.verifyEqual([graph.Nodes.Name], ["A", "B"]);
        end

        function AgentGraph_withInvalidName_throws(testCase)
            % Name keys a dynamic struct field (workspace.agentgraph.(Name)), so a
            % name that is not a valid variable name must fail at construction
            % rather than deep inside a traversal.
            testCase.verifyError( ...
                @() agentgraph.AgentGraph( ...
                    agentgraph.FunctionNode("A", @(w) deal("a",w)), string.empty(0,2), ...
                    Name="my graph"), ...
                "MATLAB:validators:mustBeValidVariableName");
        end

        function AgentGraph_setEdges_afterConstruction_throwsSetProhibited(testCase)
            graph = agentgraph.AgentGraph( ...
                agentgraph.FunctionNode("A", @(w) deal("a",w)), ...
                string.empty(0,2), Name="graph");

            testCase.verifyError(@() setEdges(graph), ...
                "MATLAB:class:SetProhibited");
        end

        function AgentGraph_helperMethods_areHidden(testCase)
            classInfo = ?agentgraph.AgentGraph;
            helperNames = ["executionOrder", "dependencyString", ...
                "describeNodes", "getNode", "buildNodePrompt"];

            for name = helperNames
                method = classInfo.MethodList( ...
                    string({classInfo.MethodList.Name}) == name);
                testCase.verifyTrue(method.Hidden, name + " should be hidden");
            end
        end

        function traverseAtWorkspacePath_isNotPublic(testCase)
            classInfo = ?agentgraph.AgentGraph;
            method = classInfo.MethodList( ...
                string({classInfo.MethodList.Name}) == "traverseAtWorkspacePath");

            testCase.verifyEqual(method.Access, {?agentgraph.internal.GraphTargetTool});
        end

        %% Nodes

        function AgentGraph_withNoNodes_throws(testCase)
            % An empty graph would reach join() of an empty array, which returns
            % <missing> -- describeNodes() feeds a taskmaster's routing prompt.
            testCase.verifyError( ...
                @() agentgraph.AgentGraph( ...
                    agentgraph.FunctionNode.empty(1,0), string.empty(0,2), Name="graph"), ...
                "MATLAB:validators:mustBeNonempty");
        end

        function AgentGraph_withNonNodeElement_throws(testCase)
            testCase.verifyError( ...
                @() agentgraph.AgentGraph("A", string.empty(0,2), Name="graph"), ...
                "MATLAB:validation:UnableToConvert");
        end

        %% Names are unique within a graph, while nested graph names may repeat

        function AgentGraph_withDuplicateNodeNames_throws(testCase)
            nodes = [agentgraph.FunctionNode("A", @(w) deal("a",w)); ...
                agentgraph.FunctionNode("A", @(w) deal("b",w))];

            testCase.verifyError( ...
                @() agentgraph.AgentGraph(nodes, string.empty(0,2), Name="graph"), ...
                "agentgraph:duplicateNodeName");
        end

        function AgentGraph_withDuplicateNodeNames_reportsName(testCase)
            nodes = [agentgraph.FunctionNode("A", @(w) deal("a",w)); ...
                agentgraph.FunctionNode("A", @(w) deal("b",w))];

            err = errorFrom(@() agentgraph.AgentGraph(nodes, string.empty(0,2), Name="graph"));

            testCase.verifySubstring(err.message, "'A'");
        end

        function AgentGraph_withRepeatedNestedGraphNames_constructs(testCase)
            left = agentgraph.AgentNode("left", ...
                agentgraph.taskmaster(twoStageGraph("same"), MockClient()), ...
                Description="Route left");
            right = agentgraph.AgentNode("right", ...
                agentgraph.taskmaster(twoStageGraph("same"), MockClient()), ...
                Description="Route right");

            g = agentgraph.AgentGraph([left; right], ["left","right"], Name="same");

            testCase.verifyEqual(g.Name, "same");
        end

        %% Error messages name the thing that was wrong


        function getNode_missingName_namesTheMissingNodeInTheMessage(testCase)
            g = agentgraph.AgentGraph(...
                agentgraph.FunctionNode("A", @(w) deal("a",w)), string.empty(0,2), Name="graph");

            err = errorFrom(@() g.getNode("Z"));

            testCase.assertNotEmpty(err);
            testCase.verifySubstring(err.message, "Z");
        end


        function AgentGraph_withMixedNodeTypes_constructs(testCase)
            % The Heterogeneous mixin on Node is what makes this array legal;
            % without it the concatenation fails with MATLAB:UnableToConvert.
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a",w))
                agentgraph.AgentNode("B", aisdk.AIAgent(MockClient()), ...
                    Description="judge something")
            ];
            g = agentgraph.AgentGraph(nodes, ["A","B"], Name="graph");

            testCase.verifyEqual(g.executionOrder(), ["A","B"]);
            testCase.verifyClass(g.getNode("B"), "agentgraph.AgentNode");
        end

        %% nodeTrace -- written during traversal, asserted where it lives

        function traverse_wholeGraph_recordsEveryNodeInNodeTraceInOrder(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a",w))
                agentgraph.FunctionNode("B", @(w) deal("b",w))
                agentgraph.FunctionNode("C", @(w) deal("c",w))
            ];
            g = agentgraph.AgentGraph(nodes, ["A","B"; "B","C"], Name="graph");

            [~, wsOut] = g.traverse("go", struct());

            testCase.verifyEqual(wsOut.agentgraph.graph.nodeTrace, ["A","B","C"]);
        end

        function traverse_withTargetNode_recordsOnlyGoalAndAncestors(testCase)
            % A partial traversal records what it RAN, not the whole graph --
            % the property that makes nodeTrace worth storing rather than
            % deriving from the graph.
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a",w))
                agentgraph.FunctionNode("B", @(w) deal("b",w))
                agentgraph.FunctionNode("C", @(w) deal("c",w))
            ];
            g = agentgraph.AgentGraph(nodes, ["A","B"; "B","C"], Name="graph");

            [~, wsOut] = g.traverse("go", struct(), TargetNode="B");

            testCase.verifyEqual(wsOut.agentgraph.graph.nodeTrace, ["A","B"]);
        end

        function traverse_calledTwice_appendsToExistingNodeTrace(testCase)
            % Traversal appends and never resets, so a workspace carried across
            % calls accumulates. This is what a resumed .mat depends on.
            g = agentgraph.AgentGraph(...
                agentgraph.FunctionNode("A", @(w) deal("a",w)), string.empty(0,2), Name="graph");

            [~, ws] = g.traverse("go", struct());
            [~, ws] = g.traverse("go again", ws);

            testCase.verifyEqual(ws.agentgraph.graph.nodeTrace, ["A","A"]);
        end

        function traverse_withExistingCache_executesFreshAndPreservesCache(testCase)
            nodes = [
                agentgraph.FunctionNode("A", ...
                    @(w) deal("freshA", appendExecution(w, "A")))
                agentgraph.FunctionNode("B", ...
                    @(w) deal("freshB", appendExecution(w, "B")))
            ];
            g = agentgraph.AgentGraph(nodes, ["A","B"], Name="g");
            ws.execution = strings(1,0);
            ws.agentgraph.g.graphName = "g";
            ws.agentgraph.g.cache = struct("A", "storedA", "B", "storedB");
            originalCache = ws.agentgraph.g.cache;

            [~, ws] = g.traverse("go", ws, TargetNode="B");

            testCase.verifyEqual(ws.execution, ["A","B"]);
            testCase.verifyEqual(ws.agentgraph.g.cache, originalCache);
        end

        %% executionOrder

        function executionOrder_linearChain_returnsSourceToSink(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a",w))
                agentgraph.FunctionNode("B", @(w) deal("b",w))
                agentgraph.FunctionNode("C", @(w) deal("c",w))
            ];
            edges = ["A","B"; "B","C"];
            g = agentgraph.AgentGraph(nodes, edges, Name="graph");

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
            g = agentgraph.AgentGraph(nodes, edges, Name="graph");

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
            g = agentgraph.AgentGraph(nodes, edges, Name="graph");

            testCase.verifyError(@() g.executionOrder(), "agentgraph:cyclicGraph");
        end

        function executionOrder_withTargetNode_returnsAncestorsAndGoal(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a",w))
                agentgraph.FunctionNode("B", @(w) deal("b",w))
                agentgraph.FunctionNode("C", @(w) deal("c",w))
            ];
            edges = ["A","B"; "B","C"];
            g = agentgraph.AgentGraph(nodes, edges, Name="graph");

            names = g.executionOrder("B");

            testCase.verifyEqual(sort(names), sort(["A","B"]));
            testCase.verifyLessThan(find(names == "A"), find(names == "B"));
        end

        function executionOrder_isolatedTargetNode_returnsOnlyTheGoal(testCase)
            % The digraph is built from edge endpoints, so Z has no vertex and
            % dfsearch would throw on it.
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a",w))
                agentgraph.FunctionNode("B", @(w) deal("b",w))
                agentgraph.FunctionNode("Z", @(w) deal("z",w))
            ];
            g = agentgraph.AgentGraph(nodes, ["A","B"], Name="g");

            names = g.executionOrder("Z");

            testCase.verifyEqual(names, "Z");
        end

        function executionOrder_goalWithNoAncestors_returnsSingleNode(testCase)
            nodes = [
                agentgraph.FunctionNode("A", @(w) deal("a",w))
                agentgraph.FunctionNode("B", @(w) deal("b",w))
            ];
            edges = ["A","B"];
            g = agentgraph.AgentGraph(nodes, edges, Name="graph");

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
            g = agentgraph.AgentGraph(nodes, edges, Name="graph");

            result = g.getNode("B");

            testCase.verifyEqual(result.Name, "B");
        end

        function getNode_missingName_throwsNodeNotFound(testCase)
            nodes = agentgraph.FunctionNode("A", @(w) deal("a",w));
            g = agentgraph.AgentGraph(nodes, string.empty(0,2), Name="graph");

            testCase.verifyError(@() g.getNode("Z"), "agentgraph:nodeNotFound");
        end

        %% describeNodes

        function describeNodes_withDescriptions_returnsBulletLines(testCase)
            nodes = [
                agentgraph.FunctionNode("build", @(w) deal("",w), ...
                    Description="Compile the project")
                agentgraph.FunctionNode("test", @(w) deal("",w), ...
                    Description="Run tests")
            ];
            edges = ["build","test"];
            g = agentgraph.AgentGraph(nodes, edges, Name="graph");

            text = g.describeNodes();

            testCase.verifySubstring(text, "- build: Compile the project");
            testCase.verifySubstring(text, "- test: Run tests");
        end

        function describeNodes_emptyDescription_omitsColon(testCase)
            nodes = agentgraph.FunctionNode("build", @(w) deal("",w));
            g = agentgraph.AgentGraph(nodes, string.empty(0,2), Name="graph");

            text = g.describeNodes();

            testCase.verifyEqual(text, "- build");
        end

        %% buildNodePrompt

        function buildNodePrompt_emptyHistory_returnsPromptOnly(testCase)
            g = agentgraph.AgentGraph(...
                agentgraph.FunctionNode("A", @(w) deal("",w)), ...
                string.empty(0,2), Name="graph");

            nodePrompt = g.buildNodePrompt("Do the thing", strings(1,0));

            testCase.verifyEqual(nodePrompt, "Do the thing");
        end

        function buildNodePrompt_withHistory_appendsTranscript(testCase)
            g = agentgraph.AgentGraph(...
                agentgraph.FunctionNode("A", @(w) deal("",w)), ...
                string.empty(0,2), Name="graph");
            history = ["nodeA: result1", "nodeB: result2"];

            nodePrompt = g.buildNodePrompt("Do the thing", history);

            testCase.verifySubstring(nodePrompt, "Do the thing");
            testCase.verifySubstring(nodePrompt, "Previous stages completed:");
            testCase.verifySubstring(nodePrompt, "nodeA: result1");
            testCase.verifySubstring(nodePrompt, "nodeB: result2");
        end
    end
end

function workspace = appendExecution(workspace, nodeName)
    workspace.execution(end+1) = nodeName;
end

function setEdges(graph)
    graph.Edges = ["A","B"];
end

