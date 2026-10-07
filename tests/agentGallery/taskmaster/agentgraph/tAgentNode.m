classdef tAgentNode < matlab.unittest.TestCase

% Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addToPath(testCase)
            repoRoot = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'agentGallery', 'taskmaster')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'helpers')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'agentGallery', 'taskmaster', 'agentgraph', 'helpers')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'resources', 'functions')));
        end
    end

    methods (Test, TestTags = {'Unit'})

        function AgentNode_withNonIdentifierName_throws(testCase)
            testCase.verifyError(@() agentgraph.AgentNode( ...
                "not a name", aisdk.AIAgent(MockClient())), ...
                "MATLAB:validators:mustBeValidVariableName");
        end

        function constructor_suppliedAgentAndOptions_stored(testCase)
            toolA = aisdk.LLMTool(@addTwoNumbers, Name="toolA");
            toolB = aisdk.LLMTool(@addTwoNumbers, Name="toolB");
            client = MockClient();
            agent = aisdk.AIAgent(client, ...
                Tools=[toolA,toolB], ...
                SystemPrompt="You are helpful.", ...
                MaxIterations=10);
            node = agentgraph.AgentNode("myNode", agent);

            testCase.verifyEqual(node.Name, "myNode");
            testCase.verifyTrue(node.Agent == agent);
            testCase.verifyEqual([node.Agent.Tools.Name], ["toolA","toolB"]);
            testCase.verifyEqual(node.Agent.SystemPrompt, "You are helpful.");
            testCase.verifyEqual(node.Agent.MaxIterations, 10);
            testCase.verifyTrue(node.ClearHistory);
        end

        function execute_textResponse_returnsAsString(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Hello!", aisdk.LLMTextMessage("Hello!", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            node = agentgraph.AgentNode("n", aisdk.AIAgent(client, SystemPrompt="test", DisplayMode="off"));
            ws = struct();

            [result, ~] = node.execute(ws, NodePrompt="task", ParentWorkspacePath="graph");

            testCase.verifyEqual(result, "Hello!");
        end

        function execute_nonStringResponse_jsonEncoded(testCase)
            response = struct("key", "value");
            client = MockClient();
            client.GenerateOutputs = {
                {response, aisdk.LLMTextMessage(jsonencode(response), Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            node = agentgraph.AgentNode("n", aisdk.AIAgent(client, SystemPrompt="test", DisplayMode="off"));
            ws = struct();

            [result, ~] = node.execute(ws, NodePrompt="task", ParentWorkspacePath="graph");

            testCase.verifyEqual(result, string(jsonencode(response)));
        end

        function execute_usesSuppliedToolObjects(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("stampWorkspace", struct(), ToolCallID="call_1"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
                {"done", aisdk.LLMTextMessage("done", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            tool = aisdk.LLMTool(@stampWorkspace, ...
                Workspace="agent", ApprovalRequest="never");
            node = agentgraph.AgentNode("n", aisdk.AIAgent(client, Tools=tool, DisplayMode="off"));
            [~, ws] = node.execute(struct(), NodePrompt="task", ParentWorkspacePath="graph");

            testCase.verifyEqual(ws.stamps, "stamped");
        end

        function execute_usesSuppliedAgentClient_whenGraphClientDiffers(testCase)
            agentClient = MockClient();
            agentClient.GenerateOutputs = {responseRow()};
            graphClient = MockClient();
            node = agentgraph.AgentNode("n", aisdk.AIAgent(agentClient, DisplayMode="off"));

            [result, ~] = node.execute(struct(), NodePrompt="task", ParentWorkspacePath="graph");

            testCase.verifyEqual(result, "ok");
            testCase.verifyLength(agentClient.GenerateInputs, 1);
            testCase.verifyEmpty(graphClient.GenerateInputs);
        end

        function constructor_nonAgent_rejectsAtConstruction(testCase)
            testCase.verifyError( ...
                @() agentgraph.AgentNode("n", struct()), ...
                "MATLAB:validation:UnableToConvert");
        end

        function execute_defaultClearHistory_startsSecondRunFresh(testCase)
            client = MockClient();
            client.GenerateOutputs = {responseRow(); responseRow()};
            node = agentgraph.AgentNode("n", aisdk.AIAgent(client, DisplayMode="off"));

            [~, ws] = node.execute(struct(), NodePrompt="first", ParentWorkspacePath="graph");
            node.execute(ws, NodePrompt="second", ParentWorkspacePath="graph");

            inputs = client.GenerateInputs;
            testCase.verifyEqual(numel(inputs{2}), numel(inputs{1}));
        end

        function execute_defaultClearHistory_preservesInitialMessages(testCase)
            client = MockClient();
            client.GenerateOutputs = {responseRow(); responseRow()};
            seed = aisdk.LLMTextMessage("starting context", Role="user");
            node = agentgraph.AgentNode("n", aisdk.AIAgent(client, Messages=seed, DisplayMode="off"));

            [~, ws] = node.execute(struct(), NodePrompt="first", ParentWorkspacePath="graph");
            node.execute(ws, NodePrompt="second", ParentWorkspacePath="graph");

            inputs = client.GenerateInputs;
            testCase.verifyEqual(inputs{2}(1).Text, "starting context");
            testCase.verifyEqual(numel(inputs{2}), numel(inputs{1}));
        end

        function execute_defaultClearHistory_chargesOnlyNewTokens(testCase)
            client = MockClient();
            client.GenerateOutputs = {responseRow(); responseRow()};
            node = agentgraph.AgentNode("n", aisdk.AIAgent(client, DisplayMode="off"));

            [~, ws] = node.execute(struct(), NodePrompt="first", ParentWorkspacePath="graph");
            [~, ws] = node.execute(ws, NodePrompt="second", ParentWorkspacePath="graph");

            testCase.verifyEqual(ws.tokenUsage.total, 30);
        end

        function execute_clearHistoryFalse_retainsPreviousMessages(testCase)
            client = MockClient();
            client.GenerateOutputs = {responseRow(); responseRow()};
            node = agentgraph.AgentNode("n", aisdk.AIAgent(client, DisplayMode="off"), ClearHistory=false);

            [~, ws] = node.execute(struct(), NodePrompt="first", ParentWorkspacePath="graph");
            node.execute(ws, NodePrompt="second", ParentWorkspacePath="graph");

            inputs = client.GenerateInputs;
            testCase.verifyGreaterThan(numel(inputs{2}), numel(inputs{1}));
        end

        function execute_clearHistoryFalse_chargesOnlyNewTokens(testCase)
            client = MockClient();
            client.GenerateOutputs = {responseRow(); responseRow()};
            node = agentgraph.AgentNode("n", aisdk.AIAgent(client, DisplayMode="off"), ClearHistory=false);

            [~, ws] = node.execute(struct(), NodePrompt="first", ParentWorkspacePath="graph");
            [~, ws] = node.execute(ws, NodePrompt="second", ParentWorkspacePath="graph");

            testCase.verifyEqual(ws.tokenUsage.total, 30);
        end

        function execute_secondRun_transfersWorkspaceToSuppliedAgent(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("stampWorkspace", struct(), ToolCallID="call_1"), tokenInfo()}
                responseRow()
                {"", aisdk.LLMToolCallMessage("stampWorkspace", struct(), ToolCallID="call_2"), tokenInfo()}
                responseRow()
            };
            tool = aisdk.LLMTool(@stampWorkspace, ...
                Workspace="agent", ApprovalRequest="never");
            node = agentgraph.AgentNode("n", aisdk.AIAgent(client, Tools=tool, DisplayMode="off"));

            [~, ws] = node.execute(struct(), NodePrompt="first", ParentWorkspacePath="graph");
            ws.external = "retained";
            [~, ws] = node.execute(ws, NodePrompt="second", ParentWorkspacePath="graph");

            testCase.verifyEqual(ws.stamps, ["stamped", "stamped"]);
            testCase.verifyEqual(ws.external, "retained");
        end

        function execute_initializesTokenUsage_whenMissing(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"ok", aisdk.LLMTextMessage("ok", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 100, "NumOutputTokens", 20, ...
                        "NumTotalTokens", 120, "NumCachedInputTokens", 10))}
            };

            node = agentgraph.AgentNode("n", aisdk.AIAgent(client, SystemPrompt="test", DisplayMode="off"));
            ws = struct();

            [~, wsOut] = node.execute(ws, NodePrompt="task", ParentWorkspacePath="graph");

            testCase.verifyEqual(wsOut.tokenUsage.input, 100);
            testCase.verifyEqual(wsOut.tokenUsage.output, 20);
            testCase.verifyEqual(wsOut.tokenUsage.total, 120);
            testCase.verifyEqual(wsOut.tokenUsage.cachedInput, 10);
        end

        function execute_accumulatesTokenUsage_whenExisting(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"ok", aisdk.LLMTextMessage("ok", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 50, "NumOutputTokens", 10, ...
                        "NumTotalTokens", 60, "NumCachedInputTokens", 5))}
            };

            node = agentgraph.AgentNode("n", aisdk.AIAgent(client, SystemPrompt="test", DisplayMode="off"));
            ws = struct();
            ws.tokenUsage = struct('input', 100, 'output', 20, 'total', 120, 'cachedInput', 10);

            [~, wsOut] = node.execute(ws, NodePrompt="task", ParentWorkspacePath="graph");

            testCase.verifyEqual(wsOut.tokenUsage.input, 150);
            testCase.verifyEqual(wsOut.tokenUsage.output, 30);
            testCase.verifyEqual(wsOut.tokenUsage.total, 180);
            testCase.verifyEqual(wsOut.tokenUsage.cachedInput, 15);
        end

        function execute_withObserver_callsRunningAndDone(testCase)
            obs = MockObserver();
            client = MockClient();
            client.GenerateOutputs = {
                {"ok", aisdk.LLMTextMessage("ok", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            node = agentgraph.AgentNode("n", aisdk.AIAgent(client, SystemPrompt="test", DisplayMode="off"));
            ws = struct();

            node.execute(ws, NodePrompt="task", ParentWorkspacePath="graph", Observer=obs);

            testCase.verifyLength(obs.Log, 2);
            testCase.verifyEqual(obs.Log{1}{1}, 'nodeRunning');
            testCase.verifyEqual(obs.Log{2}{1}, 'nodeDone');
        end

        function execute_agentThrows_rethrowsError(testCase)
            client = MockClient();
            % Empty GenerateOutputs causes MockClient to error

            node = agentgraph.AgentNode("n", aisdk.AIAgent(client, SystemPrompt="test", DisplayMode="off"));
            ws = struct();

            testCase.verifyError( ...
                @() node.execute(ws, NodePrompt="task", ParentWorkspacePath="graph"), ...
                "MATLAB:badsubscript");
        end

        function execute_agentThrows_withObserver_callsNodeError(testCase)
            obs = MockObserver();
            client = MockClient();

            node = agentgraph.AgentNode("n", aisdk.AIAgent(client, SystemPrompt="test", DisplayMode="off"));
            ws = struct();

            try
                node.execute(ws, NodePrompt="task", ParentWorkspacePath="graph", Observer=obs);
            catch
            end

            errorEntries = obs.Log(cellfun(@(x) strcmp(x{1}, 'nodeError'), obs.Log));
            testCase.verifyNotEmpty(errorEntries);
        end
    end

    methods (Test, TestTags = {'Integration'})
        function nestedRouter_writesAtOwningPath(testCase)
            [outer, ~, nodeClient] = nestedRouterFixture();

            [~, workspace] = outer.traverse("nested request", struct());

            testCase.verifyEqual(agentgraph.utils.graphLevels(workspace), ...
                ["outer", "outer.inner"]);
            testCase.verifyEqual(agentgraph.utils.nodeTrace( ...
                workspace, "outer.inner"), "A");
            messages = nodeClient.GenerateInputs{1};
            testCase.verifyEqual(messages(end).Text, "nested request");
        end

        function afterNestedRun_preservesOriginalToolPath(testCase)
            [outer, router, nodeClient] = nestedRouterFixture();
            [~, workspace] = outer.traverse("nested request", struct());
            router.Workspace = workspace;

            router.run("direct request");

            testCase.verifyEqual(agentgraph.utils.graphLevels(router.Workspace), ...
                ["outer", "outer.inner", "inner"]);
            testCase.verifyEqual(agentgraph.utils.nodeTrace( ...
                router.Workspace, "outer.inner"), "A");
            testCase.verifyEqual(agentgraph.utils.nodeTrace( ...
                router.Workspace, "inner"), "A");
            messages = nodeClient.GenerateInputs{end};
            testCase.verifyEqual(messages(end).Text, "direct request");
        end
    end
end

function [outer, router, nodeClient] = nestedRouterFixture()
    [node, nodeClient] = createAgentNodeWithMockClient("A", 2);
    graph = agentgraph.AgentGraph(node, ...
        string.empty(0,2), Name="inner");
    client = MockClient();
    client.GenerateOutputs = {graphCallRow("call_1"); responseRow(); ...
        graphCallRow("call_2"); responseRow()};
    router = agentgraph.taskmaster(graph, client, DisplayMode="off");
    node = agentgraph.AgentNode("inner", router, ...
        Description="Run the inner graph", ClearHistory=false);
    outer = agentgraph.AgentGraph(node, string.empty(0,2), Name="outer");
end

function row = graphCallRow(id)
    row = {"", aisdk.LLMToolCallMessage("runToTargetNode", ...
        struct("TargetNode", "A"), ToolCallID=id), tokenInfo()};
end

function row = responseRow()
    row = {"ok", aisdk.LLMTextMessage("ok", Role="assistant"), ...
        struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
        "NumTotalTokens", 15, "NumCachedInputTokens", 0))};
end

function info = tokenInfo()
    info = struct("Tokens", struct("NumInputTokens", 10, ...
        "NumOutputTokens", 5, "NumTotalTokens", 15, "NumCachedInputTokens", 0));
end
