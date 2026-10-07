classdef ttaskmaster < matlab.unittest.TestCase
%TTASKMASTER  Contract of the graph router factory and graph tool.

% Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addToPath(testCase)
            root = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(root, "agentGallery", "taskmaster")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(root, "tests", "helpers")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(root, "tests", "agentGallery", "taskmaster", "agentgraph", "helpers")));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function withUndescribedNode_throwsMissingDescription(testCase)
            graph = agentgraph.AgentGraph( ...
                agentgraph.FunctionNode("A", @(w) deal("ok", w)), ...
                string.empty(0,2), Name="inner");

            testCase.verifyError(@() agentgraph.taskmaster(graph, MockClient()), ...
                "agentgraph:missingNodeDescription");
        end

        function withDescribedNodes_exposesRolesInToolDescription(testCase)
            nodes = [describedNode("A", "Prepare input"); ...
                describedNode("B", "Verify output")];
            graph = agentgraph.AgentGraph(nodes, ["A", "B"], Name="inner");

            router = agentgraph.taskmaster(graph, MockClient());
            tool = router.Tools([router.Tools.Name] == "runToTargetNode");

            testCase.verifySubstring(tool.Description, "Prepare input");
            testCase.verifySubstring(tool.Description, "Verify output");
        end

        function graphTool_schemaRequiresTargetNode(testCase)
            graph = threeStageGraph();
            tool = graph.asTool();

            schema = tool.inputSchema();

            testCase.verifyEqual(schema.properties.TargetNode.type, "string");
            testCase.verifyEqual(schema.required, {"TargetNode"});
        end

        function graphTool_displayShowsAgentWorkspace(testCase)
            tool = threeStageGraph().asTool();

            output = evalc("disp([tool, tool])");

            testCase.verifySubstring(output, '"agent"');
        end

        function graphTool_withoutTargetNode_throwsRequiredArgument(testCase)
            graph = threeStageGraph();
            tool = graph.asTool();

            testCase.verifyError(@() tool.evaluate(struct(), struct()), ...
                "aisdk:requiredArgumentNotFound");
        end
    end

    methods (Test, TestTags = {'Integration'})
        function targetB_runsAncestorsAndTarget(testCase)
            graph = threeStageGraph();
            router = routerFor(graph, {toolRow("B", "call_1"); answerRow("Done")});

            response = router.run("Run through B");

            testCase.verifyEqual(response, "Done");
            testCase.verifyEqual(agentgraph.utils.nodeTrace(router.Workspace, "inner"), ...
                ["A", "B"]);
            testCase.verifyEqual(router.Workspace.executed, ["A", "B"]);
        end

        function unknownTarget_allowsValidRetry(testCase)
            graph = threeStageGraph();
            client = MockClient();
            client.GenerateOutputs = {toolRow("missing", "call_1"); ...
                toolRow("B", "call_2"); answerRow("Done")};
            router = agentgraph.taskmaster(graph, client, DisplayMode="off");

            response = router.run("Run B");

            testCase.verifyEqual(response, "Done");
            testCase.verifyEqual(agentgraph.utils.nodeTrace(router.Workspace, "inner"), ...
                ["A", "B"]);
            testCase.verifySubstring(string(jsonencode(client.GenerateInputs{2})), ...
                "missing");
        end

        function secondRun_passesLatestRequestToGraph(testCase)
            [node, nodeClient] = createAgentNodeWithMockClient("A", 2);
            graph = agentgraph.AgentGraph(node, ...
                string.empty(0,2), Name="inner");
            router = routerFor(graph, {toolRow("A", "call_1"); ...
                answerRow("First done"); toolRow("A", "call_2"); ...
                answerRow("Second done")});

            router.run("first request");
            router.Workspace = graph.clearCache(router.Workspace);
            router.run("second request");

            messages = nodeClient.GenerateInputs{end};
            testCase.verifyEqual(messages(end).Text, "second request");
        end

        function withoutGraphToolCall_leavesGraphUndriven(testCase)
            node = describedNode("A", "Record the request");
            graph = agentgraph.AgentGraph(node, ...
                string.empty(0,2), Name="inner");
            router = routerFor(graph, {answerRow("No drive")});

            response = router.run("Just answer");

            testCase.verifyEqual(response, "No drive");
            testCase.verifyFalse(isfield(router.Workspace, "executed"));
        end

        function withAdditionalTool_keepsBothToolsCallable(testCase)
            node = describedNode("A", "Record the request");
            graph = agentgraph.AgentGraph(node, ...
                string.empty(0,2), Name="inner");
            client = MockClient();
            client.GenerateOutputs = {ordinaryToolRow(); ...
                toolRow("A", "call_2"); answerRow("Done")};
            tool = aisdk.LLMTool(@stampWorkspace, ...
                Workspace="agent", ApprovalRequest="never");
            router = agentgraph.taskmaster(graph, client, ...
                Tools=tool, DisplayMode="off");

            router.run("Run both");

            testCase.verifyEqual(router.Workspace.stamps, "stamped");
            testCase.verifyEqual(router.Workspace.executed, "A");
        end
    end
end

function node = describedNode(name, description)
node = agentgraph.FunctionNode(name, @(w) recordRun(w, name), ...
    Description=description);
end

function [result, workspace] = recordRun(workspace, name)
if ~isfield(workspace, "executed")
    workspace.executed = strings(1,0);
end
workspace.executed(end+1) = name;
result = name;
end

function graph = threeStageGraph()
nodes = [describedNode("A", "Prepare"); ...
    describedNode("B", "Measure"); describedNode("C", "Report")];
graph = agentgraph.AgentGraph(nodes, ["A", "B"; "B", "C"], Name="inner");
end

function router = routerFor(graph, outputs)
client = MockClient();
client.GenerateOutputs = outputs;
router = agentgraph.taskmaster(graph, client, DisplayMode="off");
end

function row = toolRow(target, id)
row = {"", aisdk.LLMToolCallMessage("runToTargetNode", ...
    struct("TargetNode", target), ToolCallID=id), tokenInfo()};
end

function row = ordinaryToolRow()
row = {"", aisdk.LLMToolCallMessage("stampWorkspace", ...
    struct(), ToolCallID="call_1"), tokenInfo()};
end

function row = answerRow(answer)
row = {answer, aisdk.LLMTextMessage(answer, Role="assistant"), tokenInfo()};
end

function info = tokenInfo()
info = struct("Tokens", struct("NumInputTokens", 10, ...
    "NumOutputTokens", 5, "NumTotalTokens", 15, "NumCachedInputTokens", 0));
end
