classdef tAIAgent_ContextUsage < matlab.unittest.TestCase
% Tests for AIAgent.LastInputTokens and AIAgent.ContextUsage.

%   Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addResourcesToPath(testCase)
            testsRoot = fileparts(mfilename("fullpath"));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testsRoot, "helpers")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testsRoot, "resources", "functions")));
        end
    end

    %% LastInputTokens
    methods (Test, TestTags = {'Unit'})
        function lastInputTokens_beforeAnyRun_isZero(testCase)
            % A fresh agent starts with an empty context, so LastInputTokens
            % begins at 0 and only grows as generate calls are made.
            client = MockClient();
            agent = aisdk.AIAgent(client);
            testCase.verifyEqual(agent.LastInputTokens, 0);
        end

        function lastInputTokens_afterSingleRun_reflectsLatestCall(testCase)
            client = MockClient();
            numInputTokens = 100;
            client.GenerateOutputs = {
                {"Hello!", aisdk.LLMTextMessage("Hello!", Role="assistant"), ...
                 createTokenInfo(numInputTokens, 20, 120, 10)}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.run("Hi");

            testCase.verifyEqual(agent.LastInputTokens, numInputTokens);
        end

        function lastInputTokens_acrossMultipleRuns_isLatestValue(testCase)
            % Contrast with NumInputTokens, which is cumulative.
            client = MockClient();
            firstNumInputTokens = 50;
            lastNumInputTokens = 80;
            client.GenerateOutputs = {
                {"Reply 1", aisdk.LLMTextMessage("Reply 1", Role="assistant"), ...
                 createTokenInfo(firstNumInputTokens, 10, 60, 0)}
                {"Reply 2", aisdk.LLMTextMessage("Reply 2", Role="assistant"), ...
                 createTokenInfo(lastNumInputTokens, 30, 110, 0)}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.run("First");
            agent.run("Second");

            testCase.verifyEqual(agent.LastInputTokens, lastNumInputTokens, ...
                "LastInputTokens should reflect only the most recent call.");
            testCase.verifyEqual(agent.NumInputTokens, firstNumInputTokens + lastNumInputTokens, ...
                "NumInputTokens should still be cumulative across runs.");
        end

        function lastInputTokens_multiIterationRun_reflectsFinalGenerateCall(testCase)
            % A tool-calling run invokes generate twice; LastInputTokens
            % must reflect the second (final) call.
            tool = aisdk.LLMTool(@addTwoNumbers);
            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", ...
                        struct("a", 2, "b", 3), ToolCallID="call_1"), ...
                 createTokenInfo(60, 15, 75, 0)}
                {"The answer is 5.", ...
                 aisdk.LLMTextMessage("The answer is 5.", Role="assistant"), ...
                 createTokenInfo(90, 25, 115, 0)}
            };

            agent = aisdk.AIAgent(client, Tools=tool, DisplayMode="off");
            agent.run("What is 2+3?");

            testCase.verifyEqual(agent.LastInputTokens, 90);
        end

        function lastInputTokens_whenMessagesAppendedTo_isPreserved(testCase)
            % Externally mutating Messages does not reset LastInputTokens:
            % the previous count is a more helpful approximation of the
            % current context size than resetting to 0 (which would falsely
            % imply an empty context after an edit) or NaN (which would hide
            % ContextUsage entirely until the next generate call). Drift is
            % corrected on the next generate call.
            client = MockClient();
            client.GenerateOutputs = {
                {"Hi.", aisdk.LLMTextMessage("Hi.", Role="assistant"), ...
                 createTokenInfo(100, 20, 120, 0)}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.run("Hi");
            testCase.assertEqual(agent.LastInputTokens, 100);

            agent.Messages(end+1) = aisdk.LLMTextMessage("Extra note", Role="user");

            testCase.verifyEqual(agent.LastInputTokens, 100, ...
                "Appending to Messages should not reset LastInputTokens.");
        end

        function lastInputTokens_whenMessagesReplaced_isPreserved(testCase)
            % Wholesale replacement of Messages likewise does not reset the
            % stored token count. See preceding test for rationale.
            client = MockClient();
            client.GenerateOutputs = {
                {"Hi.", aisdk.LLMTextMessage("Hi.", Role="assistant"), ...
                 createTokenInfo(100, 20, 120, 0)}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.run("Hi");
            testCase.assertEqual(agent.LastInputTokens, 100);

            agent.Messages = aisdk.llms.message.LLMMessage.empty(1,0);

            testCase.verifyEqual(agent.LastInputTokens, 100, ...
                "Replacing Messages should not reset LastInputTokens.");
        end
    end

    %% ContextUsage — NaN paths
    methods (Test, TestTags = {'Unit'})
        function contextUsage_defaultClient_isNaN(testCase)
            % ContextSize defaults to NaN, so ContextUsage is NaN before any run.
            client = MockClient();
            agent = aisdk.AIAgent(client);
            testCase.verifyEqual(agent.ContextUsage, NaN);
        end

        function contextUsage_contextSizeUnset_afterRun_isNaN(testCase)
            % Running does not synthesize a ContextSize.
            client = MockClient();
            client.GenerateOutputs = {
                {"Hi.", aisdk.LLMTextMessage("Hi.", Role="assistant"), ...
                 createTokenInfo(500, 10, 510, 0)}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.run("Hi");

            testCase.verifyEqual(agent.ContextUsage, NaN);
        end

        function contextUsage_contextSizeSetButNoRunYet_isZero(testCase)
            % LastInputTokens starts at 0, so ContextUsage is 0 when the
            % ContextSize is known — a fresh agent starts with an empty
            % context.
            client = MockClient();
            client.ContextSize = 10000;
            agent = aisdk.AIAgent(client);
            testCase.verifyEqual(agent.ContextUsage, 0);
        end
    end

    %% ContextUsage — numeric paths
    methods (Test, TestTags = {'Unit'})
        function contextUsage_singleRun_isRatio(testCase)
            client = MockClient();
            client.ContextSize = 1000;
            client.GenerateOutputs = {
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), ...
                 createTokenInfo(610, 20, 630, 0)}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.run("Task");

            testCase.verifyEqual(agent.ContextUsage, 0.61, "AbsTol", eps);
        end

        function contextUsage_acrossMultipleRuns_reflectsLatestCall(testCase)
            client = MockClient();
            client.ContextSize = 1000;
            client.GenerateOutputs = {
                {"R1", aisdk.LLMTextMessage("R1", Role="assistant"), ...
                 createTokenInfo(200, 10, 210, 0)}
                {"R2", aisdk.LLMTextMessage("R2", Role="assistant"), ...
                 createTokenInfo(750, 15, 765, 0)}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.run("First");
            agent.run("Second");

            testCase.verifyEqual(agent.ContextUsage, 0.75, "AbsTol", eps);
        end

        function contextUsage_multiIterationRun_reflectsFinalGenerateCall(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers);
            client = MockClient();
            client.ContextSize = 1000;
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", ...
                        struct("a", 2, "b", 3), ToolCallID="call_1"), ...
                 createTokenInfo(300, 10, 310, 0)}
                {"5", aisdk.LLMTextMessage("5", Role="assistant"), ...
                 createTokenInfo(800, 5, 805, 0)}
            };

            agent = aisdk.AIAgent(client, Tools=tool, DisplayMode="off");
            agent.run("What is 2+3?");

            testCase.verifyEqual(agent.ContextUsage, 0.8, "AbsTol", eps);
        end

        function contextUsage_exceedsOne_whenInputExceedsContextSize(testCase)
            % ContextUsage is defined as a simple ratio, so >1 is valid
            % when the input token count exceeds the configured size.
            client = MockClient();
            client.ContextSize = 1000;
            client.GenerateOutputs = {
                {"ok", aisdk.LLMTextMessage("ok", Role="assistant"), ...
                 createTokenInfo(1200, 10, 1210, 0)}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.run("large input");

            testCase.verifyEqual(agent.ContextUsage, 1.2, "AbsTol", eps);
        end
    end

    %% Design Case 1b: swapping the Client
    methods (Test, TestTags = {'Unit'})
        function contextUsage_afterClientSwap_usesNewClientContextSize(testCase)
            % End User overrides Client on a received agent. ContextUsage
            % must reflect the new client's ContextSize, not the old one.
            client1 = MockClient();
            client1.ContextSize = 2000;
            client1.GenerateOutputs = {
                {"first", aisdk.LLMTextMessage("first", Role="assistant"), ...
                 createTokenInfo(400, 10, 410, 0)}
            };

            agent = aisdk.AIAgent(client1, DisplayMode="off");
            agent.run("Do something");
            testCase.verifyEqual(agent.ContextUsage, 0.2, "AbsTol", eps);

            client2 = MockClient();
            client2.ContextSize = 500;
            client2.GenerateOutputs = {
                {"second", aisdk.LLMTextMessage("second", Role="assistant"), ...
                 createTokenInfo(100, 5, 105, 0)}
            };

            agent.Client = client2;
            agent.run("Do something else");

            testCase.verifyEqual(agent.ContextUsage, 0.2, "AbsTol", eps);
        end

        function contextUsage_afterClientSwapToUnknownSize_isNaN(testCase)
            % Swapping in a client with no ContextSize (default NaN) makes
            % ContextUsage report NaN, even after a successful run.
            client1 = MockClient();
            client1.ContextSize = 1000;
            client1.GenerateOutputs = {
                {"first", aisdk.LLMTextMessage("first", Role="assistant"), ...
                 createTokenInfo(500, 10, 510, 0)}
            };

            agent = aisdk.AIAgent(client1, DisplayMode="off");
            agent.run("First");
            testCase.verifyEqual(agent.ContextUsage, 0.5, "AbsTol", eps);

            client2 = MockClient();   % ContextSize left at default NaN
            client2.GenerateOutputs = {
                {"second", aisdk.LLMTextMessage("second", Role="assistant"), ...
                 createTokenInfo(200, 5, 205, 0)}
            };

            agent.Client = client2;
            agent.run("Second");

            testCase.verifyEqual(agent.ContextUsage, NaN);
        end
    end

end

function info = createTokenInfo(numIn, numOut, numTotal, numCached)
    info = struct("Tokens", struct( ...
        "NumInputTokens", numIn, ...
        "NumOutputTokens", numOut, ...
        "NumTotalTokens", numTotal, ...
        "NumCachedInputTokens", numCached));
end
