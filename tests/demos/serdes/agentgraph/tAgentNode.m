classdef tAgentNode < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addToPath(testCase)
            repoRoot = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'demos', 'serdes')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'helpers')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'demos', 'serdes', 'agentgraph', 'helpers')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'resources', 'functions')));
        end
    end

    methods (Test, TestTags = {'Unit'})

        function constructor_customProperties_stored(testCase)
            node = agentgraph.AgentNode("myNode", ...
                ToolNames=["toolA","toolB"], ...
                SystemPrompt="You are helpful.", ...
                MaxIterations=10);

            testCase.verifyEqual(node.Name, "myNode");
            testCase.verifyEqual(node.ToolNames, ["toolA","toolB"]);
            testCase.verifyEqual(node.SystemPrompt, "You are helpful.");
            testCase.verifyEqual(node.MaxIterations, 10);
        end

        function execute_textResponse_returnsAsString(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Hello!", aisdk.LLMTextMessage("Hello!", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            node = agentgraph.AgentNode("n", SystemPrompt="test");
            ws = struct();

            [result, ~] = node.execute("task", ws, aisdk.llms.tool.LLMTool.empty(1,0), client);

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

            node = agentgraph.AgentNode("n", SystemPrompt="test");
            ws = struct();

            [result, ~] = node.execute("task", ws, aisdk.llms.tool.LLMTool.empty(1,0), client);

            testCase.verifyEqual(result, string(jsonencode(response)));
        end

        function execute_filtersToolsByToolNames(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"done", aisdk.LLMTextMessage("done", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            toolA = aisdk.LLMTool(@addTwoNumbers, Name="toolA");
            toolB = aisdk.LLMTool(@addTwoNumbers, Name="toolB");
            toolC = aisdk.LLMTool(@addTwoNumbers, Name="toolC");
            allTools = [toolA, toolB, toolC];

            node = agentgraph.AgentNode("n", ToolNames=["toolA","toolC"], SystemPrompt="test");
            ws = struct();

            node.execute("task", ws, allTools, client);

            inputs = client.GenerateInputs;
            testCase.verifyNotEmpty(inputs);
        end

        function execute_initializesTokenUsage_whenMissing(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"ok", aisdk.LLMTextMessage("ok", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 100, "NumOutputTokens", 20, ...
                        "NumTotalTokens", 120, "NumCachedInputTokens", 10))}
            };

            node = agentgraph.AgentNode("n", SystemPrompt="test");
            ws = struct();

            [~, wsOut] = node.execute("task", ws, aisdk.llms.tool.LLMTool.empty(1,0), client);

            testCase.verifyEqual(wsOut.tokenUsage.input, 100);
            testCase.verifyEqual(wsOut.tokenUsage.output, 20);
            testCase.verifyEqual(wsOut.tokenUsage.total, 120);
            testCase.verifyEqual(wsOut.tokenUsage.cached, 10);
        end

        function execute_accumulatesTokenUsage_whenExisting(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"ok", aisdk.LLMTextMessage("ok", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 50, "NumOutputTokens", 10, ...
                        "NumTotalTokens", 60, "NumCachedInputTokens", 5))}
            };

            node = agentgraph.AgentNode("n", SystemPrompt="test");
            ws = struct();
            ws.tokenUsage = struct('input', 100, 'output', 20, 'total', 120, 'cached', 10);

            [~, wsOut] = node.execute("task", ws, aisdk.llms.tool.LLMTool.empty(1,0), client);

            testCase.verifyEqual(wsOut.tokenUsage.input, 150);
            testCase.verifyEqual(wsOut.tokenUsage.output, 30);
            testCase.verifyEqual(wsOut.tokenUsage.total, 180);
            testCase.verifyEqual(wsOut.tokenUsage.cached, 15);
        end

        function execute_withObserver_callsRunningAndDone(testCase)
            obs = MockObserver();
            client = MockClient();
            client.GenerateOutputs = {
                {"ok", aisdk.LLMTextMessage("ok", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            node = agentgraph.AgentNode("n", SystemPrompt="test");
            ws = struct();

            node.execute("task", ws, aisdk.llms.tool.LLMTool.empty(1,0), client, obs);

            testCase.verifyLength(obs.Log, 2);
            testCase.verifyEqual(obs.Log{1}{1}, 'nodeRunning');
            testCase.verifyEqual(obs.Log{2}{1}, 'nodeDone');
        end

        function execute_agentThrows_rethrowsError(testCase)
            client = MockClient();
            % Empty GenerateOutputs causes MockClient to error

            node = agentgraph.AgentNode("n", SystemPrompt="test");
            ws = struct();

            testCase.verifyError( ...
                @() node.execute("task", ws, aisdk.llms.tool.LLMTool.empty(1,0), client), ...
                "MATLAB:badsubscript");
        end

        function execute_agentThrows_withObserver_callsNodeError(testCase)
            obs = MockObserver();
            client = MockClient();

            node = agentgraph.AgentNode("n", SystemPrompt="test");
            ws = struct();

            try
                node.execute("task", ws, aisdk.llms.tool.LLMTool.empty(1,0), client, obs);
            catch
            end

            errorEntries = obs.Log(cellfun(@(x) strcmp(x{1}, 'nodeError'), obs.Log));
            testCase.verifyNotEmpty(errorEntries);
        end
    end
end
