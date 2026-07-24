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
            tool = aisdk.LLMTool(@addTwoNumbers);

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
            tool = aisdk.LLMTool(@alwaysError);

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
            tool = aisdk.LLMTool(@addTwoNumbers);

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
            tool = aisdk.LLMTool(@addTwoNumbers);

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
            tool1 = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="always");
            tool2 = aisdk.LLMTool(@addTwoNumbers, Name="addWithoutApproval", RequiresApproval="never");
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
            testCase.verifySubstring(toolResults(1).Result, "denied");
            expectedResult = string(jsonencode(struct("c", 5)));
            testCase.verifyEqual(toolResults(2).Result, expectedResult);
        end

        function approval_withDenialReason_includesReasonInToolResult(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="always");

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
            testCase.verifySubstring(toolResults(1).Result, reason);
        end

        function approval_withNeverMode_neverInvokesApprovalFcn(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="never");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), ToolCallID="call_1"), tokens}
                {"5.", aisdk.LLMTextMessage("5.", Role="assistant"), tokens}
            };

            errorFcn = @(~,~) error("ApprovalFcn should not be called");
            agent = aisdk.AIAgent(client, Tools=tool, ApprovalFcn=errorFcn, DisplayMode="off");
            response = agent.run("Add 2+3.");

            testCase.verifyEqual(response, "5.");
        end

        function approval_withAlwaysMode_asksOnEveryCall(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="always");

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
            tool = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="once");

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

        function approval_withOnceModeNotPermanent_asksAgainNextRound(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="once");

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

        function approval_withApprovedReason_insertsUserMessage(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="always");

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
            tool1 = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="always");
            tool2 = aisdk.LLMTool(@addTwoNumbers, Name="doubleNumber", ...
                RequiresApproval="always");
            tool3 = aisdk.LLMTool(@addTwoNumbers, Name="decrementNumber", ...
                RequiresApproval="always");
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
            tool = aisdk.LLMTool(@addTwoNumbers);

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
            tool = aisdk.LLMTool(@addTwoNumbers);

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
                "llms:invalidClientType");
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
            tool = aisdk.LLMTool(@addTwoNumbers);

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


        function toolChoice_withSpecificName_callsNamedToolAndCompletes(testCase)
            toolAdd = aisdk.LLMTool(@addTwoNumbers);
            toolGreet = aisdk.LLMTool(@greetUser);

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
