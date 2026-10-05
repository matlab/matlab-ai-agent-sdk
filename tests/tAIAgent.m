classdef tAIAgent < matlab.unittest.TestCase
% Tests for AIAgent token tracking properties.

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

    methods (Test, TestTags = {'Unit'})
        function tokenCountsZeroOnConstruction(testCase)
            client = MockClient();
            agent = aisdk.AIAgent(client, DisplayMode="off");

            testCase.verifyEqual(agent.NumInputTokens, 0);
            testCase.verifyEqual(agent.NumOutputTokens, 0);
            testCase.verifyEqual(agent.NumTotalTokens, 0);
            testCase.verifyEqual(agent.NumCachedInputTokens, 0);
        end

        function tokenCountsAfterSingleRun(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Hello!", aisdk.LLMTextMessage("Hello!", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 100, "NumOutputTokens", 20, ...
                        "NumTotalTokens", 120, "NumCachedInputTokens", 10))}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.run("Hi");

            testCase.verifyEqual(agent.NumInputTokens, 100);
            testCase.verifyEqual(agent.NumOutputTokens, 20);
            testCase.verifyEqual(agent.NumTotalTokens, 120);
            testCase.verifyEqual(agent.NumCachedInputTokens, 10);
        end

        function tokenCountsCumulativeAcrossRuns(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Reply 1", aisdk.LLMTextMessage("Reply 1", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 50, "NumOutputTokens", 10, ...
                        "NumTotalTokens", 60, "NumCachedInputTokens", 5))}
                {"Reply 2", aisdk.LLMTextMessage("Reply 2", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 80, "NumOutputTokens", 30, ...
                        "NumTotalTokens", 110, "NumCachedInputTokens", 15))}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.run("First");
            agent.run("Second");

            testCase.verifyEqual(agent.NumInputTokens, 130);
            testCase.verifyEqual(agent.NumOutputTokens, 40);
            testCase.verifyEqual(agent.NumTotalTokens, 170);
            testCase.verifyEqual(agent.NumCachedInputTokens, 20);
        end

        function responseSingleRoundNoTools(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Hello!", aisdk.LLMTextMessage("Hello!", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off");
            response = agent.run("Hi");

            testCase.verifyEqual(response, "Hello!");
        end

        function responseConcatenatesTextAcrossToolCallRounds(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="never");

            client = MockClient();
            client.GenerateOutputs = {
                % Round 1: text + tool call
                {"Let me check.", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
                % Round 2: empty text + tool call
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 1), ToolCallID="call_2"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
                % Round 3: text, no tool call
                {"The answer is 5.", aisdk.LLMTextMessage("The answer is 5.", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, Tools=tool, DisplayMode="off");
            response = agent.run("What is 2+3?");

            testCase.verifyEqual(response, "Let me check." + newline + "The answer is 5.");
        end

        function toolErrorReturnedAsObservation(testCase)
            tool = aisdk.LLMTool(@alwaysError, ApprovalRequest="never");

            client = MockClient();
            client.GenerateOutputs = {
                % Round 1: model calls the broken tool
                {"", aisdk.LLMToolCallMessage("alwaysError", struct("x", 42), ToolCallID="call_1"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
                % Round 2: model replies after seeing the error
                {"I see the error.", aisdk.LLMTextMessage("I see the error.", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 20, "NumOutputTokens", 10, ...
                        "NumTotalTokens", 30, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, Tools=tool, DisplayMode="off");
            response = agent.run("Try it");

            testCase.verifyEqual(response, "I see the error.");
            % The tool result message should contain the error text
            toolResults = agent.Messages([agent.Messages.Role] == "tool");
            testCase.verifySubstring(toolResults(1).Result, "something went wrong");
        end

        function structuredOutputReturnedDirectly(testCase)
            structResult = struct("name", "Alice", "age", 30);

            client = MockClient();
            client.GenerateOutputs = {
                {structResult, aisdk.LLMTextMessage("", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off");
            response = agent.run("Get info");

            testCase.verifyTrue(isstruct(response));
            testCase.verifyEqual(response, structResult);
        end

        function tokenCountsCumulativeAcrossRunsWithToolCalls(testCase)
            %   generate call 1: model returns tool call
            %   AIAgent executes tool, appends tool result
            %   generate call 2: model returns assistant message
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="never");

            client = MockClient();
            client.GenerateOutputs = {
                % tool call
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), ...
                 struct("Tokens", struct("NumInputTokens", 60, "NumOutputTokens", 15, ...
                        "NumTotalTokens", 75, "NumCachedInputTokens", 0))}
                % assistant message
                {"The answer is 5.", aisdk.LLMTextMessage("The answer is 5.", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 90, "NumOutputTokens", 25, ...
                        "NumTotalTokens", 115, "NumCachedInputTokens", 8))}
            };

            agent = aisdk.AIAgent(client, Tools=tool, DisplayMode="off");
            agent.run("What is 2+3?");

            testCase.verifyEqual(agent.NumInputTokens, 150);
            testCase.verifyEqual(agent.NumOutputTokens, 40);
            testCase.verifyEqual(agent.NumTotalTokens, 190);
            testCase.verifyEqual(agent.NumCachedInputTokens, 8);
        end

        function toolChoice_withNone_doesNotCallTools(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers);

            client = MockClient();
            client.GenerateOutputs = {
                {"No tools used.", aisdk.LLMTextMessage("No tools used.", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, Tools=tool, DisplayMode="off");
            response = agent.run("Hi", ToolChoice="none");

            testCase.verifyEqual(response, "No tools used.");
            testCase.verifyFalse(any([agent.Messages.Role] == "tool"));
        end

        function toolChoice_withRequired_callsToolAndCompletes(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="never");

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
                {"The answer is 5.", aisdk.LLMTextMessage("The answer is 5.", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, Tools=tool, DisplayMode="off");
            response = agent.run("What is 2+3?", ToolChoice="required");

            testCase.verifyEqual(response, "The answer is 5.");
            testCase.verifyTrue(any([agent.Messages.Role] == "tool"));
        end

        function approval_withDeniedTool_executesRemainingToolsInRound(testCase)
            tool1 = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="always");
            tool2 = aisdk.LLMTool(@addTwoNumbers, Name="addWithoutApproval", ApprovalRequest="never");
            tools = [tool1, tool2];

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", [aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), ...
                      aisdk.LLMToolCallMessage("addWithoutApproval", struct("a", 2, "b", 3), ToolCallID="call_2")], ...
                 tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
            };

            denyFcn = @(~,~) struct("Approved", false, "Permanent", false, "Reason", "");
            agent = aisdk.AIAgent(client, Tools=tools, ApprovalFcn=denyFcn, DisplayMode="off");
            response = agent.run("Add some numbers.");

            testCase.verifyEqual(response, "Done.");

            msgs = agent.Messages;
            toolResults = msgs([msgs.Role] == "tool");
            testCase.verifyNumElements(toolResults, 2);
            denied = jsondecode(toolResults(1).Result);
            testCase.verifyEqual(string(denied.error), "user canceled");
            testCase.verifyEqual(string(denied.message), "");
            expectedResult = string(jsonencode(struct("c", 5)));
            testCase.verifyEqual(toolResults(2).Result, expectedResult);
        end

        function approval_withDenialReason_includesReasonInToolResult(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="always");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), tokens}
                {"OK.", aisdk.LLMTextMessage("OK.", Role="assistant"), tokens}
            };

            reason = "I don't trust this tool";
            denyFcn = @(~,~) struct("Approved", false, "Permanent", false, "Reason", reason);
            agent = aisdk.AIAgent(client, Tools=tool, ApprovalFcn=denyFcn, DisplayMode="off");
            agent.run("Add 2+3.");

            msgs = agent.Messages;
            toolResults = msgs([msgs.Role] == "tool");
            decoded = jsondecode(toolResults(1).Result);
            testCase.verifyEqual(string(decoded.error), "user canceled");
            testCase.verifyEqual(string(decoded.message), reason);
        end

        function approval_deniedWithRequiredToolChoice_recordsDenialAndCompletes(testCase)
            % MockClient stand-in for tSystem.m::run_withApprovalDenied_recordsDenialInHistory:
            % a fast unit-level guard that a denial is recorded as the JSON tool result and
            % the run completes, without needing a live model.
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="always");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 3, "b", 4), ToolCallID="call_1"), tokens}
                {"Understood.", aisdk.LLMTextMessage("Understood.", Role="assistant"), tokens}
            };

            reason = "User denied this action.";
            denyFcn = @(~,~) struct("Approved", false, "Permanent", false, "Reason", reason);
            agent = aisdk.AIAgent(client, Tools=tool, ApprovalFcn=denyFcn, DisplayMode="off");
            response = agent.run("Add 3 and 4.", ToolChoice="required");

            testCase.verifyEqual(response, "Understood.");

            msgs = agent.Messages;
            toolResults = msgs([msgs.Role] == "tool");
            testCase.assertNotEmpty(toolResults, "Expected a synthesized denial tool result");
            decoded = jsondecode(toolResults(1).Result);
            testCase.verifyEqual(string(decoded.error), "user canceled");
            testCase.verifyEqual(string(decoded.message), reason);
        end

        function approval_withNeverMode_neverInvokesApprovalFcn(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="never");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), tokens}
                {"5.", aisdk.LLMTextMessage("5.", Role="assistant"), tokens}
            };

            callCount = containers.Map("callCount", 0);
            countingFcn = @(~,~) countAndApprove(callCount);
            agent = aisdk.AIAgent(client, Tools=tool, ApprovalFcn=countingFcn, DisplayMode="off");
            response = agent.run("Add 2+3.");

            testCase.verifyEqual(callCount("callCount"), 0, ...
                "A never tool must not consult the approval callback.");
            testCase.verifyEqual(response, "5.");
        end

        function approval_withThrowingApprovalFcn_deniesAndCompletesRun(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="once");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
            };

            agent = aisdk.AIAgent(client, Tools=tool, ApprovalFcn=@failToApprove, DisplayMode="off");

            response = agent.run("Add 2 and 3.");

            testCase.verifyEqual(response, "Done.");

            msgs = agent.Messages;
            toolResults = msgs([msgs.Role] == "tool");
            testCase.assertNumElements(toolResults, 1);
            decoded = jsondecode(toolResults(1).Result);
            testCase.verifyEqual(string(decoded.error), "approval unavailable", ...
                "A callback failure is not a human decision.");
            testCase.verifySubstring(string(decoded.message), "callback exploded");

            testCase.verifyEmpty(agent.UserApprovedTools, ...
                "A failed approval must not accumulate standing approval.");
        end

        function approval_withThrowingApprovalFcn_answersEveryToolCallInRound(testCase)
            tool1 = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="always");
            tool2 = aisdk.LLMTool(@addTwoNumbers, Name="addAgain", ApprovalRequest="always");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", [aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), ...
                      aisdk.LLMToolCallMessage("addAgain", struct("a", 4, "b", 5), ToolCallID="call_2")], ...
                 tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
            };

            agent = aisdk.AIAgent(client, Tools=[tool1, tool2], ...
                ApprovalFcn=@failToApprove, DisplayMode="off");

            agent.run("Add some numbers.");

            % Every tool call must have a matching tool result, or the
            % history cannot be replayed to the model.
            msgs = agent.Messages;
            toolCallIDs = [msgs([msgs.Type] == "tool-call").ToolCallID];
            toolResultIDs = [msgs([msgs.Role] == "tool").ToolCallID];
            testCase.verifyEqual(sort(toolResultIDs), sort(toolCallIDs));
        end

        function approval_withThrowingApprovalFcnAndNoMessage_stillDenies(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="always");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
            };

            agent = aisdk.AIAgent(client, Tools=tool, ...
                ApprovalFcn=@failToApproveSilently, DisplayMode="off");

            response = agent.run("Add 2 and 3.");

            testCase.verifyEqual(response, "Done.");
            msgs = agent.Messages;
            toolResults = msgs([msgs.Role] == "tool");
            testCase.assertNumElements(toolResults, 1);
            decoded = jsondecode(toolResults(1).Result);
            testCase.verifyEqual(string(decoded.error), "approval unavailable");
            testCase.verifyGreaterThan(strlength(string(decoded.message)), 0, ...
                "A denial synthesized from a failure must carry a reason.");
        end

        function approval_withMalformedApprovalFcn_terminatesRun(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="once");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
            };

            agent = aisdk.AIAgent(client, Tools=tool, ...
                ApprovalFcn=@approveWithoutReasonField, DisplayMode="off");

            testCase.verifyError(@() agent.run("Add 2 and 3."), ...
                "aisdk:agent:approvalDecisionMissingField");

            % A throwing callback denies and the run continues; a malformed
            % return is an authoring error and stops the run instead.
            msgs = agent.Messages;
            testCase.verifyEmpty(msgs([msgs.Role] == "tool"), ...
                "A malformed decision must not be materialized as a denial.");
            testCase.verifyEmpty(agent.UserApprovedTools);
        end

        function approval_withNonStructApprovalFcn_terminatesRun(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="always");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), tokens}
            };

            agent = aisdk.AIAgent(client, Tools=tool, ...
                ApprovalFcn=@(~,~) true, DisplayMode="off");

            testCase.verifyError(@() agent.run("Add 2 and 3."), ...
                "aisdk:agent:approvalDecisionNotStruct");
        end

        function approval_inBatchModeWithDefaultFcn_deniesAndCompletesRun(testCase)
            % The headless fail-safe spans two files: the default callback
            % raises, this loop converts. Neither half shows the run
            % completes, so assert the pair.
            import matlab.unittest.fixtures.PathFixture
            import matlab.unittest.fixtures.SuppressedWarningsFixture

            testCase.applyFixture( ...
                SuppressedWarningsFixture("MATLAB:dispatcher:nameConflict"));
            doublesDir = fullfile(fileparts(mfilename("fullpath")), ...
                "private", "batch-doubles");
            testCase.applyFixture(PathFixture(doublesDir));

            % Aborts before the run: without the double, uiconfirm would
            % open a modal dialog and block waiting for a human.
            testCase.assertTrue(batchStartupOptionUsed, ...
                "Test double for batchStartupOptionUsed not picked up.");

            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="always");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
            };

            agent = aisdk.AIAgent(client, Tools=tool, DisplayMode="off");

            response = agent.run("Add 2 and 3.");

            testCase.verifyEqual(response, "Done.", ...
                "A headless run must complete rather than hang or error.");

            msgs = agent.Messages;
            toolResults = msgs([msgs.Role] == "tool");
            testCase.assertNumElements(toolResults, 1);
            decoded = jsondecode(toolResults(1).Result);
            testCase.verifyEqual(string(decoded.error), "approval unavailable", ...
                "No human was reachable, so the model must not be told a user canceled.");
            testCase.verifySubstring(string(decoded.message), ...
                aisdk.internal.MessageCatalog.getMessage( ...
                    "aisdk:uiconfirm:noUserAvailable"));
        end

        function approval_withAlwaysMode_asksOnEveryCall(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="always");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), ToolCallID="call_1"), tokens}
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 3, "b", 4), ToolCallID="call_2"), tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
            };

            callCount = containers.Map("callCount", 0);
            countingFcn = @(~,~) countAndApprove(callCount);
            agent = aisdk.AIAgent(client, Tools=tool, ApprovalFcn=countingFcn, DisplayMode="off");
            agent.run("Add numbers twice.");

            testCase.verifyEqual(callCount("callCount"), 2);
        end

        function approval_withOnceModeAndPermanent_skipsSubsequentCalls(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="once");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), ToolCallID="call_1"), tokens}
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 3, "b", 4), ToolCallID="call_2"), tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
            };

            callCount = containers.Map("callCount", 0);
            permanentApproveFcn = @(~,~) countAndApprovePermanent(callCount);
            agent = aisdk.AIAgent(client, Tools=tool, ApprovalFcn=permanentApproveFcn, DisplayMode="off");
            agent.run("Add numbers twice.");

            testCase.verifyEqual(callCount("callCount"), 1);
        end

        function approval_withOnceModeAndPermanent_parallelCallsInOneRound_autoApprovesRest(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="once");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            % A single assistant response with two parallel tool calls to
            % the same tool. Approving the first permanently must
            % auto-approve the second within the same round, so the
            % ApprovalFcn is invoked exactly once.
            client = MockClient();
            client.GenerateOutputs = {
                {"", [ ...
                    aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), ToolCallID="call_1"), ...
                    aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 3, "b", 4), ToolCallID="call_2")], tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
            };

            callCount = containers.Map("callCount", 0);
            permanentApproveFcn = @(~,~) countAndApprovePermanent(callCount);
            agent = aisdk.AIAgent(client, Tools=tool, ApprovalFcn=permanentApproveFcn, DisplayMode="off");
            agent.run("Add numbers twice in parallel.");

            testCase.verifyEqual(callCount("callCount"), 1);
            testCase.verifyEqual(agent.UserApprovedTools, "addTwoNumbers");
        end

        function approval_withAlwaysModeAndPermanent_reAsksAndNeverEntersUserApprovedTools(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="always");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), ToolCallID="call_1"), tokens}
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 3, "b", 4), ToolCallID="call_2"), tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
            };

            callCount = containers.Map("callCount", 0);
            permanentApproveFcn = @(~,~) countAndApprovePermanent(callCount);
            agent = aisdk.AIAgent(client, Tools=tool, ApprovalFcn=permanentApproveFcn, DisplayMode="off");
            agent.run("Add numbers twice.");

            testCase.verifyEqual(callCount("callCount"), 2);
            testCase.verifyEmpty(agent.UserApprovedTools);
        end

        function approval_alwaysTool_withNameAlreadyInUserApprovedTools_stillPrompts(testCase)
            % Approve a "once" tool permanently, then run again with a
            % same-named "always" tool supplied for that call only. The
            % accumulated name matches but the effective policy does not.
            onceTool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="once");
            alwaysTool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="always");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), ToolCallID="call_1"), tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 3, "b", 4), ToolCallID="call_2"), tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
            };

            callCount = containers.Map("callCount", 0);
            permanentApproveFcn = @(~,~) countAndApprovePermanent(callCount);
            agent = aisdk.AIAgent(client, Tools=onceTool, ...
                ApprovalFcn=permanentApproveFcn, DisplayMode="off");

            agent.run("Add 1 and 2.");
            testCase.assertEqual(callCount("callCount"), 1);
            testCase.assertEqual(agent.UserApprovedTools, "addTwoNumbers");

            agent.run("Add 3 and 4.", Tools=alwaysTool);

            testCase.verifyEqual(callCount("callCount"), 2, ...
                "An always tool must prompt even when its name is already approved.");
            testCase.verifyEqual(agent.UserApprovedTools, "addTwoNumbers");
        end

        function approval_withOnceModeNotPermanent_asksAgainNextRound(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="once");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), ToolCallID="call_1"), tokens}
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 3, "b", 4), ToolCallID="call_2"), tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
            };

            callCount = containers.Map("callCount", 0);
            nonPermanentFcn = @(~,~) countAndApprove(callCount);
            agent = aisdk.AIAgent(client, Tools=tool, ApprovalFcn=nonPermanentFcn, DisplayMode="off");
            agent.run("Add numbers twice.");

            testCase.verifyEqual(callCount("callCount"), 2);
        end

        function approval_savedAndLoadedAgent_hasEmptyUserApprovedTools(testCase)
            % UserApprovedTools is Transient: approval state does not persist
            % across save/load, so a loaded agent prompts again.
            import matlab.unittest.fixtures.TemporaryFolderFixture
            tempFixture = testCase.applyFixture(TemporaryFolderFixture);

            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="once");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), ToolCallID="call_1"), tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
            };

            permanentApproveFcn = @(~,~) struct("Approved", true, "Permanent", true, "Reason", "");
            agent = aisdk.AIAgent(client, Tools=tool, ApprovalFcn=permanentApproveFcn, DisplayMode="off");
            agent.run("Add 1+2.");

            % Precondition: the once-mode tool accumulated into UserApprovedTools.
            testCase.assertEqual(agent.UserApprovedTools, "addTwoNumbers");

            matFile = fullfile(tempFixture.Folder, "agent.mat");
            save(matFile, "agent");
            loaded = load(matFile, "agent");

            testCase.verifyEmpty(loaded.agent.UserApprovedTools);
        end

        function resetApproval_clearAll_emptiesUserApprovedTools(testCase)
            agent = agentWithTwoUserApprovedTools();
            testCase.assertNumElements(agent.UserApprovedTools, 2);

            agent.resetApproval();

            testCase.verifyEmpty(agent.UserApprovedTools);
        end

        function resetApproval_byName_removesOnlyNamed(testCase)
            agent = agentWithTwoUserApprovedTools();

            agent.resetApproval("addTwoNumbers");

            testCase.verifyEqual(agent.UserApprovedTools, "doubleNumber");
        end

        function resetApproval_unknownName_throws(testCase)
            agent = agentWithTwoUserApprovedTools();

            testCase.verifyError(@() agent.resetApproval("noSuchTool"), ...
                "aisdk:agent:noApprovalToReset");
            testCase.verifyEqual(sort(agent.UserApprovedTools), ...
                sort(["addTwoNumbers", "doubleNumber"]));
        end

        function resetApproval_vectorMixedNames_throwsAndClearsNothing(testCase)
            agent = agentWithTwoUserApprovedTools();

            testCase.verifyError( ...
                @() agent.resetApproval(["addTwoNumbers", "noSuchTool"]), ...
                "aisdk:agent:noApprovalToReset");
            testCase.verifyEqual(sort(agent.UserApprovedTools), ...
                sort(["addTwoNumbers", "doubleNumber"]));
        end

        function resetApproval_sameNameTwice_throwsOnSecondCall(testCase)
            agent = agentWithTwoUserApprovedTools();
            agent.resetApproval("addTwoNumbers");

            testCase.verifyError(@() agent.resetApproval("addTwoNumbers"), ...
                "aisdk:agent:noApprovalToReset");
            testCase.verifyEqual(agent.UserApprovedTools, "doubleNumber");
        end

        function resetApproval_toolThatNeverPrompts_throws(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="never");
            client = MockClient();
            agent = aisdk.AIAgent(client, Tools=tool, DisplayMode="off");

            testCase.verifyError(@() agent.resetApproval("addTwoNumbers"), ...
                "aisdk:agent:noApprovalToReset");
        end

        function resetApproval_emptyNames_clearsNothing(testCase)
            agent = agentWithTwoUserApprovedTools();

            agent.resetApproval(string.empty(1,0));

            testCase.verifyEqual(sort(agent.UserApprovedTools), ...
                sort(["addTwoNumbers", "doubleNumber"]));
        end

        function resetApproval_thenRun_promptsAgainForResetToolOnly(testCase)
            % The observable point of a reset is that the tool prompts on
            % its next call, so drive the agent across the reset rather
            % than inspecting UserApprovedTools.
            tool1 = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="once");
            tool2 = aisdk.LLMTool(@addTwoNumbers, Name="doubleNumber", ...
                ApprovalRequest="once");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));
            callBothTools = {"", [ ...
                aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), ToolCallID="call_1"), ...
                aisdk.LLMToolCallMessage("doubleNumber", struct("a", 3, "b", 4), ToolCallID="call_2")], ...
                tokens};
            finish = {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens};

            client = MockClient();
            client.GenerateOutputs = {
                callBothTools; finish      % run 1: both tools prompt
                callBothTools; finish      % run 2: both stand approved
                callBothTools; finish      % run 3: after resetting one
            };

            counts = containers.Map(["addTwoNumbers", "doubleNumber"], [0, 0]);
            countingFcn = @(tool,~) countApprovalByName(counts, tool);
            agent = aisdk.AIAgent(client, Tools=[tool1, tool2], ...
                ApprovalFcn=countingFcn, DisplayMode="off");

            agent.run("Do both.");
            agent.run("Do both again.");
            testCase.assertEqual([counts("addTwoNumbers"), counts("doubleNumber")], ...
                [1, 1], "Permanent approval must silence the second run.");

            agent.resetApproval("addTwoNumbers");
            agent.run("Do both once more.");

            testCase.verifyEqual(counts("addTwoNumbers"), 2, ...
                "A reset tool must prompt again on its next call.");
            testCase.verifyEqual(counts("doubleNumber"), 1, ...
                "A tool that was not reset must stay approved.");
        end

        function tamperProofing_directWriteToUserApprovedTools_throws(testCase)
            client = MockClient();
            agent = aisdk.AIAgent(client, DisplayMode="off");

            testCase.verifyError(@writeUserApprovedTools, "MATLAB:class:SetProhibited");

            function writeUserApprovedTools()
                agent.UserApprovedTools = "sneaky";
            end
        end

        function approvalFcn_default_isUiconfirm(testCase)
            client = MockClient();
            agent = aisdk.AIAgent(client, DisplayMode="off");
            testCase.verifyEqual(string(func2str(agent.ApprovalFcn)), ...
                "aisdk.utils.uiconfirm");
        end

        function approvalFcn_setAfterConstruction_isUsedByRun(testCase)
            % Supports handing a configured agent to an app author who must
            % re-point approval at their own surface.
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="always");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", ...
                        struct("a", 1, "b", 2), ToolCallID="call_1"), tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
            };

            agent = aisdk.AIAgent(client, Tools=tool, DisplayMode="off");

            called = false;
            function result = denyFcn(~, ~)
                called = true;
                result = struct("Approved", false, "Permanent", false, ...
                    "Reason", "app surface said no");
            end
            agent.ApprovalFcn = @denyFcn;

            agent.run("Add 1 and 2.");

            testCase.verifyTrue(called, ...
                "The post-construction ApprovalFcn should be the one the run uses.");
            toolResults = agent.Messages([agent.Messages.Role] == "tool");
            testCase.verifySubstring(toolResults(1).Result, "app surface said no");
        end

        function approvalFcn_setToNonFunctionHandle_throws(testCase)
            client = MockClient();
            agent = aisdk.AIAgent(client, DisplayMode="off");

            testCase.verifyError(@writeBadApprovalFcn, ...
                "MATLAB:validation:UnableToConvert");

            function writeBadApprovalFcn()
                agent.ApprovalFcn = 42;
            end
        end

        function approval_withApprovedReason_insertsUserMessage(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="always");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), tokens}
                {"5.", aisdk.LLMTextMessage("5.", Role="assistant"), tokens}
            };

            reason = "be careful with this";
            approveFcn = @(~,~) struct("Approved", true, "Permanent", false, "Reason", reason);
            agent = aisdk.AIAgent(client, Tools=tool, ApprovalFcn=approveFcn, DisplayMode="off");
            agent.run("Add 2+3.");

            msgs = agent.Messages;
            userMsgs = msgs([msgs.Role] == "user");
            reasonMsgs = userMsgs(contains([userMsgs.Text], reason));
            testCase.verifyNumElements(reasonMsgs, 1);

            toolResultIdx = find([msgs.Role] == "tool", 1, "last");
            reasonIdx = find(arrayfun(@(m) m.Role == "user" && contains(m.Text, reason), msgs));
            testCase.verifyGreaterThan(reasonIdx, toolResultIdx, ...
                "Approval reason must appear after tool results");
        end

        function approval_multipleToolswithPartialReasons_emitsOnlyForNonEmpty(testCase)
            tool1 = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="always");
            tool2 = aisdk.LLMTool(@addTwoNumbers, Name="doubleNumber", ...
                ApprovalRequest="always");
            tool3 = aisdk.LLMTool(@addTwoNumbers, Name="decrementNumber", ...
                ApprovalRequest="always");
            tools = [tool1, tool2, tool3];

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", [aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), ToolCallID="call_1"), ...
                      aisdk.LLMToolCallMessage("doubleNumber", struct("x", 5), ToolCallID="call_2"), ...
                      aisdk.LLMToolCallMessage("decrementNumber", struct("x", 10), ToolCallID="call_3")], tokens}
                {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
            };

            callIdx = 0;
            reasons = ["User approved addition", "", "User approved decrement"];
            function result = approvalFcn(~, ~)
                callIdx = callIdx + 1;
                result.Approved = true;
                result.Permanent = false;
                result.Reason = reasons(callIdx);
            end

            agent = aisdk.AIAgent(client, Tools=tools, ApprovalFcn=@approvalFcn, ...
                DisplayMode="off");
            agent.run("Do three things.");

            msgs = agent.Messages;

            testCase.verifySubstring(msgs(end-2).Text, "addTwoNumbers");
            testCase.verifySubstring(msgs(end-1).Text, "decrementNumber");
            testCase.verifyEqual(msgs(end).Text, "Done.");
        end

        function run_maxIterationsWithNoText_returnsEmptyString(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="never");

            client = MockClient();
            client.GenerateOutputs = {
                % Round 1: no text, only tool call
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), ToolCallID="call_1"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
                % Round 2: no text, only tool call (hits MaxIterations)
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 3, "b", 4), ToolCallID="call_2"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, Tools=tool, ...
                DisplayMode="off");
            response = testCase.verifyWarning( ...
                @() agent.run("Compute", MaxIterations=2), ...
                "aiAgent:MaxIterationsReached");

            testCase.verifyEqual(response, "");
            testCase.verifyFalse(ismissing(response));
        end

        function run_noToolCallsEmptyText_returnsEmptyText(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMTextMessage("", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off");
            response = agent.run("Hi");

            testCase.verifyEqual(response, "");
        end

        function run_maxIterationsWithAccumulatedText_returnsJoinedText(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="never");

            client = MockClient();
            client.GenerateOutputs = {
                {"Working...", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), ToolCallID="call_1"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
                {"Still going...", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 3, "b", 4), ToolCallID="call_2"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, Tools=tool, DisplayMode="off");
            response = testCase.verifyWarning( ...
                @() agent.run("Compute", MaxIterations=2), ...
                "aiAgent:MaxIterationsReached");

            testCase.verifyEqual(response, "Working..." + newline + "Still going...");
        end

        function constructor_invalidClient_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.AIAgent("not a client"), ...
                "aisdk:invalidClientType");
        end

        function run_withSystemPrompt_prependsSystemMessage(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Hi!", aisdk.LLMTextMessage("Hi!", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, SystemPrompt="Be concise.", DisplayMode="off");
            agent.run("Hello");

            messagesPassedToGenerate = client.GenerateInputs{1};
            firstMsg = messagesPassedToGenerate(1);
            testCase.verifyEqual(firstMsg.Role, "system");
            testCase.verifyEqual(firstMsg.Text, "Be concise.");
        end

        function run_withoutSystemPrompt_doesNotPrependSystemMessage(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Hi!", aisdk.LLMTextMessage("Hi!", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.run("Hello");

            messagesPassedToGenerate = client.GenerateInputs{1};
            firstMsg = messagesPassedToGenerate(1);
            testCase.verifyNotEqual(firstMsg.Role, "system");
        end

        function toolErrorReturnedAsObservation_forMCPTool(testCase)
            throwingMock = mcpHTTPClientMock({ ...
                struct("name", "failingTool", "description", "Always fails", ...
                    "inputSchema", struct())}, ...
                @(~, varargin) error("mcp:serverError", "server error"));
            tool = aisdk.LLMTool(throwingMock);
            tool.ApprovalRequest = "never";

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("failingTool", struct(), ToolCallID="call_1"), tokens}
                {"I see the error.", aisdk.LLMTextMessage("I see the error.", Role="assistant"), tokens}
            };

            agent = aisdk.AIAgent(client, Tools=tool, DisplayMode="off");
            response = agent.run("Use the failing tool.");

            testCase.verifyEqual(response, "I see the error.");
            toolResults = agent.Messages([agent.Messages.Role] == "tool");
            testCase.verifySubstring(toolResults(1).Result, "Error");
        end

        function run_hallucinatedToolName_returnsErrorAsObservation(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers);

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("nonExistentTool", struct("a", 1), ToolCallID="call_1"), tokens}
                {"I couldn't find that tool.", aisdk.LLMTextMessage("I couldn't find that tool.", Role="assistant"), tokens}
            };

            agent = aisdk.AIAgent(client, Tools=tool, DisplayMode="off");
            response = agent.run("Do something.");

            testCase.verifyEqual(response, "I couldn't find that tool.");
            toolResults = agent.Messages([agent.Messages.Role] == "tool");
            testCase.verifySubstring(toolResults(1).Result, "Error");
        end

        function displayMode_default_isDetailed(testCase)
            client = MockClient();
            agent = aisdk.AIAgent(client);

            testCase.verifyEqual(agent.DisplayMode, "detailed");
        end

        function displayMode_withDetailed_printsOutput(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Hello!", aisdk.LLMTextMessage("Hello!", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, DisplayMode="detailed"); %#ok<NASGU>
            output = evalc('agent.run("Hi");');

            testCase.verifyNotEmpty(output);
            testCase.verifySubstring(output, "Hello!");
        end

        function displayMode_withOff_suppressesOutput(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Hello!", aisdk.LLMTextMessage("Hello!", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off"); %#ok<NASGU>
            output = evalc('agent.run("Hi");');

            testCase.verifyEmpty(output);
        end

        function displayMode_withInvalidValue_throwsError(testCase)
            client = MockClient();
            testCase.verifyError( ...
                @() aisdk.AIAgent(client, DisplayMode="someNonExistentMode"), ...
                "MATLAB:validators:mustBeMember");
        end

        function displayMode_withDetailed_printsToolCallInfo(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="never");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), tokens}
                {"5.", aisdk.LLMTextMessage("5.", Role="assistant"), tokens}
            };

            agent = aisdk.AIAgent(client, Tools=tool, DisplayMode="detailed"); %#ok<NASGU>
            output = evalc('agent.run("Add 2+3.");');

            testCase.verifySubstring(output, "addTwoNumbers");
        end

        function run_displayModeDetailed_overridesAgentOff(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Hello!", aisdk.LLMTextMessage("Hello!", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off"); %#ok<NASGU>
            output = evalc('agent.run("Hi", DisplayMode="detailed");');

            testCase.verifySubstring(output, "Hello!");
        end

        function run_displayModeOff_overridesAgentDetailed(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Hello!", aisdk.LLMTextMessage("Hello!", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, DisplayMode="detailed"); %#ok<NASGU>
            output = evalc('agent.run("Hi", DisplayMode="off");');

            testCase.verifyEmpty(output);
        end

        function run_displayModeOverride_restoresAfterRun(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Hello!", aisdk.LLMTextMessage("Hello!", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, DisplayMode="off");
            evalc('agent.run("Hi", DisplayMode="detailed");');

            testCase.verifyEqual(agent.DisplayMode, "off");
        end

        function displayMode_withDeniedCallAndMessage_printsDeniedWithMessage(testCase)
            agent = agentWithGatedTool( ...
                @(~,~) struct("Approved", false, "Permanent", false, ...
                    "Reason", "not safe")); %#ok<NASGU>

            output = evalc('agent.run("Add 2+3.");');

            expected = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:agent:approvalDisplayDeniedWithMessage", ...
                "addTwoNumbers", "not safe");
            testCase.verifySubstring(output, expected);
        end

        function displayMode_withDeniedCallAndNoMessage_printsDeniedAlone(testCase)
            agent = agentWithGatedTool( ...
                @(~,~) struct("Approved", false, "Permanent", false, ...
                    "Reason", "")); %#ok<NASGU>

            output = evalc('agent.run("Add 2+3.");');

            expected = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:agent:approvalDisplayDenied", "addTwoNumbers");
            testCase.verifySubstring(output, expected);
        end

        function displayMode_withApprovedCallAndMessage_printsApprovedWithMessage(testCase)
            agent = agentWithGatedTool( ...
                @(~,~) struct("Approved", true, "Permanent", false, ...
                    "Reason", "looks fine")); %#ok<NASGU>

            output = evalc('agent.run("Add 2+3.");');

            expected = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:agent:approvalDisplayApprovedWithMessage", ...
                "addTwoNumbers", "looks fine");
            testCase.verifySubstring(output, expected);
        end

        function displayMode_withApprovedCallAndNoMessage_printsApprovedAlone(testCase)
            agent = agentWithGatedTool( ...
                @(~,~) struct("Approved", true, "Permanent", false, ...
                    "Reason", "")); %#ok<NASGU>

            output = evalc('agent.run("Add 2+3.");');

            expected = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:agent:approvalDisplayApproved", "addTwoNumbers");
            testCase.verifySubstring(output, expected);
        end

        function displayMode_withPermanentApproval_printsPermanently(testCase)
            agent = agentWithGatedTool( ...
                @(~,~) struct("Approved", true, "Permanent", true, ...
                    "Reason", "trusted"), "once"); %#ok<NASGU>

            output = evalc('agent.run("Add 2+3.");');

            expected = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:agent:approvalDisplayApprovedPermanentlyWithMessage", ...
                "addTwoNumbers", "trusted");
            testCase.verifySubstring(output, expected);
        end

        function displayMode_withPermanentApprovalOfAlwaysTool_omitsPermanently(testCase)
            agent = agentWithGatedTool( ...
                @(~,~) struct("Approved", true, "Permanent", true, ...
                    "Reason", ""), "always"); %#ok<NASGU>

            output = evalc('agent.run("Add 2+3.");');

            expected = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:agent:approvalDisplayApproved", "addTwoNumbers");
            testCase.verifySubstring(output, expected);

            permanentLine = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:agent:approvalDisplayApprovedPermanently", "addTwoNumbers");
            testCase.verifyThat(output, ...
                ~matlab.unittest.constraints.ContainsSubstring(permanentLine));
        end

        function displayMode_withThrowingCallback_printsApprovalUnavailable(testCase)
            agent = agentWithGatedTool(@failToApprove); %#ok<NASGU>

            output = evalc('agent.run("Add 2+3.");');

            reason = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:agent:approvalFcnFailed", "callback exploded");
            expected = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:agent:approvalDisplayUnavailableWithMessage", ...
                "addTwoNumbers", reason);
            testCase.verifySubstring(output, expected);

            deniedLine = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:agent:approvalDisplayDeniedWithMessage", "addTwoNumbers", reason);
            testCase.verifyThat(output, ...
                ~matlab.unittest.constraints.ContainsSubstring(deniedLine));
        end


        function toolChoice_withSpecificName_callsNamedToolAndCompletes(testCase)
            toolAdd = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="never");
            toolGreet = aisdk.LLMTool(@greetUser, ApprovalRequest="never");

            client = MockClient();
            client.GenerateOutputs = {
                % Round 1: model calls greetUser (forced by ToolChoice="greetUser")
                {"", aisdk.LLMToolCallMessage("greetUser", struct("name", "Alice", "greeting", "Hi"), ToolCallID="call_1"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
                % Round 2: text response (model is free to finish with "auto")
                {"Hi, Alice!", aisdk.LLMTextMessage("Hi, Alice!", Role="assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, Tools=[toolAdd, toolGreet], DisplayMode="off");
            response = agent.run("Greet Alice", ToolChoice="greetUser");

            testCase.verifyEqual(response, "Hi, Alice!");

            log = client.getToolChoiceLog();
            testCase.verifyEqual(log{1}, "greetUser");
            testCase.verifyEqual(log{2}, "auto");
        end
    end

end

function result = countAndApprove(callCount)
    callCount("callCount") = callCount("callCount") + 1;
    result = struct("Approved", true, "Permanent", false, "Reason", "");
end

function result = countAndApprovePermanent(callCount)
    callCount("callCount") = callCount("callCount") + 1;
    result = struct("Approved", true, "Permanent", true, "Reason", "");
end

function result = countApprovalByName(counts, tool)
    % Counts prompts per tool, so one callback can serve several tools.
    counts(tool.Name) = counts(tool.Name) + 1;
    result = struct("Approved", true, "Permanent", true, "Reason", "");
end

function result = failToApprove(~, ~) %#ok<STOUT>
    % A named function is needed: an anonymous @(~,~) error(...) raises an
    % output-count error rather than this one, because the body of an
    % anonymous function must be an expression that produces a value.
    error("test:approvalFailed", "callback exploded");
end

function result = failToApproveSilently(~, ~) %#ok<STOUT>
    % Throws with an empty message.
    throw(MException("test:silentFailure", ""));
end

function result = approveWithoutReasonField(~, ~)
    result = struct("Approved", true, "Permanent", false);
end

function agent = agentWithGatedTool(approvalFcn, approvalRequest)
    % An agent with one approval-gated tool call followed by a final text
    % response, with the detailed display on.
    arguments
        approvalFcn     (1,1) function_handle
        approvalRequest (1,1) string = "always"
    end

    tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest=approvalRequest);

    tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
        "NumTotalTokens", 15, "NumCachedInputTokens", 0));

    client = MockClient();
    client.GenerateOutputs = {
        {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), tokens}
        {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
    };

    agent = aisdk.AIAgent(client, Tools=tool, ApprovalFcn=approvalFcn, ...
        DisplayMode="detailed");
end

function agent = agentWithTwoUserApprovedTools()
    % Build an agent whose UserApprovedTools has accumulated two once-mode
    % tools ("addTwoNumbers", "doubleNumber") via permanent approval.
    tool1 = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="once");
    tool2 = aisdk.LLMTool(@addTwoNumbers, Name="doubleNumber", ApprovalRequest="once");

    tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
        "NumTotalTokens", 15, "NumCachedInputTokens", 0));

    client = MockClient();
    client.GenerateOutputs = {
        {"", [aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), ToolCallID="call_1"), ...
              aisdk.LLMToolCallMessage("doubleNumber", struct("a", 3, "b", 4), ToolCallID="call_2")], tokens}
        {"Done.", aisdk.LLMTextMessage("Done.", Role="assistant"), tokens}
    };

    permanentApproveFcn = @(~,~) struct("Approved", true, "Permanent", true, "Reason", "");
    agent = aisdk.AIAgent(client, Tools=[tool1, tool2], ...
        ApprovalFcn=permanentApproveFcn, DisplayMode="off");
    agent.run("Do both.");
end

