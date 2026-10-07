classdef ttotalTokens < matlab.unittest.TestCase
%TTOTALTOKENS  Public token accounting view.

% Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addToPath(testCase)
            root = fileparts(fileparts(fileparts(fileparts( ...
                fileparts(fileparts(mfilename("fullpath")))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(root, "agentGallery", "taskmaster")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(root, "tests", "helpers")));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function withWorkspace_returnsRecordedTotal(testCase)
            workspace.tokenUsage.total = 17;

            testCase.verifyEqual(agentgraph.utils.totalTokens(workspace), 17);
        end
    end

    methods (Test, TestTags = {'Integration'})
        function withGraphDrive_addsRouterAndWorkspaceTokens(testCase)
            innerClient = MockClient();
            innerClient.GenerateOutputs = {answerRow("inner done")};
            innerNode = agentgraph.AgentNode("A", aisdk.AIAgent(innerClient, ...
                DisplayMode="off"), Description="Answer request");
            graph = agentgraph.AgentGraph(innerNode, ...
                string.empty(0,2), Name="inner");
            outerClient = MockClient();
            outerClient.GenerateOutputs = {toolRow(); answerRow("outer done")};
            router = agentgraph.taskmaster(graph, outerClient, DisplayMode="off");

            router.run("request");

            testCase.verifyEqual(agentgraph.utils.totalTokens(router), 45);
        end

        function withoutGraphDrive_returnsRouterTokens(testCase)
            graph = agentgraph.AgentGraph( ...
                agentgraph.FunctionNode("A", @(w) deal("ok",w), ...
                    Description="Answer request"), ...
                string.empty(0,2), Name="inner");
            client = MockClient();
            client.GenerateOutputs = {answerRow("direct answer")};
            router = agentgraph.taskmaster(graph, client, DisplayMode="off");

            router.run("question");

            testCase.verifyEqual(agentgraph.utils.totalTokens(router), 15);
        end
    end
end

function row = toolRow()
row = {"", aisdk.LLMToolCallMessage("runToTargetNode", ...
    struct("TargetNode", "A"), ToolCallID="call_1"), tokenInfo()};
end

function row = answerRow(answer)
row = {answer, aisdk.LLMTextMessage(answer, Role="assistant"), tokenInfo()};
end

function info = tokenInfo()
info = struct("Tokens", struct("NumInputTokens", 10, ...
    "NumOutputTokens", 5, "NumTotalTokens", 15, "NumCachedInputTokens", 0));
end
