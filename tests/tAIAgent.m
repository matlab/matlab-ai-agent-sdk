classdef tAIAgent < matlab.unittest.TestCase
% Tests for AIAgent token tracking properties.

%   Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addResourcesToPath(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(fileparts(mfilename("fullpath")), "helpers")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(fileparts(mfilename("fullpath")), "resources", "functions")));
        end
    end

    methods (Test)
        function tokenCountsZeroOnConstruction(testCase)
            client = MockClient();
            agent = aisdk.AIAgent(client, "You are helpful.");

            testCase.verifyEqual(agent.NumInputTokens, 0);
            testCase.verifyEqual(agent.NumOutputTokens, 0);
            testCase.verifyEqual(agent.NumTotalTokens, 0);
            testCase.verifyEqual(agent.NumCachedInputTokens, 0);
        end

        function tokenCountsAfterSingleRun(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Hello!", aisdk.llms.message.LLMTextMessage("Hello!", "assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 100, "NumOutputTokens", 20, ...
                        "NumTotalTokens", 120, "NumCachedInputTokens", 10))}
            };

            agent = aisdk.AIAgent(client, "You are helpful.");
            agent.run("Hi");

            testCase.verifyEqual(agent.NumInputTokens, 100);
            testCase.verifyEqual(agent.NumOutputTokens, 20);
            testCase.verifyEqual(agent.NumTotalTokens, 120);
            testCase.verifyEqual(agent.NumCachedInputTokens, 10);
        end

        function tokenCountsCumulativeAcrossRuns(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Reply 1", aisdk.llms.message.LLMTextMessage("Reply 1", "assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 50, "NumOutputTokens", 10, ...
                        "NumTotalTokens", 60, "NumCachedInputTokens", 5))}
                {"Reply 2", aisdk.llms.message.LLMTextMessage("Reply 2", "assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 80, "NumOutputTokens", 30, ...
                        "NumTotalTokens", 110, "NumCachedInputTokens", 15))}
            };

            agent = aisdk.AIAgent(client, "You are helpful.");
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
                {"Hello!", aisdk.llms.message.LLMTextMessage("Hello!", "assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, "You are helpful.");
            response = agent.run("Hi");

            testCase.verifyEqual(response, "Hello!");
        end

        function responseConcatenatesTextAcrossToolCallRounds(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers);

            client = MockClient();
            client.GenerateOutputs = {
                % Round 1: text + tool call
                {"Let me check.", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), "call_1"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
                % Round 2: empty text + tool call
                {"", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 1), "call_2"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
                % Round 3: text, no tool call
                {"The answer is 5.", aisdk.llms.message.LLMTextMessage("The answer is 5.", "assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, "You are helpful.", tool);
            response = agent.run("What is 2+3?");

            testCase.verifyEqual(response, "Let me check." + newline + "The answer is 5.");
        end

        function toolErrorReturnedAsObservation(testCase)
            tool = aisdk.LLMTool(@alwaysError);

            client = MockClient();
            client.GenerateOutputs = {
                % Round 1: model calls the broken tool
                {"", aisdk.llms.message.LLMToolCallMessage("alwaysError", struct("x", 42), "call_1"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
                % Round 2: model replies after seeing the error
                {"I see the error.", aisdk.llms.message.LLMTextMessage("I see the error.", "assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 20, "NumOutputTokens", 10, ...
                        "NumTotalTokens", 30, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, "You are helpful.", tool);
            response = agent.run("Try it");

            testCase.verifyEqual(response, "I see the error.");
            % The tool result message should contain the error text
            toolResults = agent.Messages([agent.Messages.Role] == "tool");
            testCase.verifySubstring(toolResults(1).Content, "something went wrong");
        end

        function structuredOutputReturnedDirectly(testCase)
            structResult = struct("name", "Alice", "age", 30);

            client = MockClient();
            client.GenerateOutputs = {
                {structResult, aisdk.llms.message.LLMTextMessage("", "assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, "You are helpful.");
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
                {"", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), "call_1"), ...
                 struct("Tokens", struct("NumInputTokens", 60, "NumOutputTokens", 15, ...
                        "NumTotalTokens", 75, "NumCachedInputTokens", 0))}
                % assistant message
                {"The answer is 5.", aisdk.llms.message.LLMTextMessage("The answer is 5.", "assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 90, "NumOutputTokens", 25, ...
                        "NumTotalTokens", 115, "NumCachedInputTokens", 8))}
            };

            agent = aisdk.AIAgent(client, "You are helpful.", tool);
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
                {"No tools used.", aisdk.llms.message.LLMTextMessage("No tools used.", "assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, "You are helpful.", tool);
            response = agent.run("Hi", ToolChoice="none");

            testCase.verifyEqual(response, "No tools used.");
            testCase.verifyFalse(any([agent.Messages.Role] == "tool"));
        end

        function toolChoice_withRequired_callsToolAndCompletes(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers);

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), "call_1"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
                {"The answer is 5.", aisdk.llms.message.LLMTextMessage("The answer is 5.", "assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, "You are helpful.", tool);
            response = agent.run("What is 2+3?", ToolChoice="required");

            testCase.verifyEqual(response, "The answer is 5.");
            testCase.verifyTrue(any([agent.Messages.Role] == "tool"));
        end

        function approval_withDeniedTool_executesRemainingToolsInRound(testCase)
            tool1 = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="always");
            tool2 = aisdk.LLMTool(@addTwoNumbers, "addWithoutApproval", RequiresApproval="never");
            tools = [tool1, tool2];

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", [aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), "call_1"), ...
                      aisdk.llms.message.LLMToolCallMessage("addWithoutApproval", struct("a", 2, "b", 3), "call_2")], ...
                 tokens}
                {"Done.", aisdk.llms.message.LLMTextMessage("Done.", "assistant"), tokens}
            };

            denyFcn = @(~,~) struct("Approved", false, "Permanent", false, "Reason", "");
            agent = aisdk.AIAgent(client, "You are helpful.", tools, ApprovalFcn=denyFcn);
            response = agent.run("Add some numbers.");

            testCase.verifyEqual(response, "Done.");

            msgs = agent.Messages;
            toolResults = msgs([msgs.Role] == "tool");
            testCase.verifyNumElements(toolResults, 2);
            testCase.verifySubstring(toolResults(1).Content, "denied");
            expectedResult = string(jsonencode(struct("c", 5)));
            testCase.verifyEqual(toolResults(2).Content, expectedResult);
        end

        function approval_withDenialReason_includesReasonInToolResult(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="always");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), "call_1"), tokens}
                {"OK.", aisdk.llms.message.LLMTextMessage("OK.", "assistant"), tokens}
            };

            reason = "I don't trust this tool";
            denyFcn = @(~,~) struct("Approved", false, "Permanent", false, "Reason", reason);
            agent = aisdk.AIAgent(client, "You are helpful.", tool, ApprovalFcn=denyFcn);
            agent.run("Add 2+3.");

            msgs = agent.Messages;
            toolResults = msgs([msgs.Role] == "tool");
            testCase.verifySubstring(toolResults(1).Content, reason);
        end

        function approval_withNeverMode_neverInvokesApprovalFcn(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="never");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), "call_1"), tokens}
                {"5.", aisdk.llms.message.LLMTextMessage("5.", "assistant"), tokens}
            };

            errorFcn = @(~,~) error("ApprovalFcn should not be called");
            agent = aisdk.AIAgent(client, "You are helpful.", tool, ApprovalFcn=errorFcn);
            response = agent.run("Add 2+3.");

            testCase.verifyEqual(response, "5.");
        end

        function approval_withAlwaysMode_asksOnEveryCall(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="always");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), "call_1"), tokens}
                {"", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 3, "b", 4), "call_2"), tokens}
                {"Done.", aisdk.llms.message.LLMTextMessage("Done.", "assistant"), tokens}
            };

            callCount = containers.Map("callCount", 0);
            countingFcn = @(~,~) countAndApprove(callCount);
            agent = aisdk.AIAgent(client, "You are helpful.", tool, ApprovalFcn=countingFcn);
            agent.run("Add numbers twice.");

            testCase.verifyEqual(callCount("callCount"), 2);
        end

        function approval_withOnceModeAndPermanent_skipsSubsequentCalls(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="once");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), "call_1"), tokens}
                {"", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 3, "b", 4), "call_2"), tokens}
                {"Done.", aisdk.llms.message.LLMTextMessage("Done.", "assistant"), tokens}
            };

            callCount = containers.Map("callCount", 0);
            permanentApproveFcn = @(~,~) countAndApprovePermanent(callCount);
            agent = aisdk.AIAgent(client, "You are helpful.", tool, ApprovalFcn=permanentApproveFcn);
            agent.run("Add numbers twice.");

            testCase.verifyEqual(callCount("callCount"), 1);
        end

        function approval_withOnceModeNotPermanent_asksAgainNextRound(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="once");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), "call_1"), tokens}
                {"", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 3, "b", 4), "call_2"), tokens}
                {"Done.", aisdk.llms.message.LLMTextMessage("Done.", "assistant"), tokens}
            };

            callCount = containers.Map("callCount", 0);
            nonPermanentFcn = @(~,~) countAndApprove(callCount);
            agent = aisdk.AIAgent(client, "You are helpful.", tool, ApprovalFcn=nonPermanentFcn);
            agent.run("Add numbers twice.");

            testCase.verifyEqual(callCount("callCount"), 2);
        end

        function approval_withApprovedReason_insertsUserMessage(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="always");

            tokens = struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                "NumTotalTokens", 15, "NumCachedInputTokens", 0));

            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 2, "b", 3), "call_1"), tokens}
                {"5.", aisdk.llms.message.LLMTextMessage("5.", "assistant"), tokens}
            };

            reason = "be careful with this";
            approveFcn = @(~,~) struct("Approved", true, "Permanent", false, "Reason", reason);
            agent = aisdk.AIAgent(client, "You are helpful.", tool, ApprovalFcn=approveFcn);
            agent.run("Add 2+3.");

            msgs = agent.Messages;
            userMsgs = msgs([msgs.Role] == "user");
            reasonMsgs = userMsgs(contains([userMsgs.Content], reason));
            testCase.verifyNumElements(reasonMsgs, 1);
        end

        function run_maxIterationsWithNoText_returnsEmptyString(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers);

            client = MockClient();
            client.GenerateOutputs = {
                % Round 1: no text, only tool call
                {"", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), "call_1"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
                % Round 2: no text, only tool call (hits MaxIterations)
                {"", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 3, "b", 4), "call_2"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, "You are helpful.", tool);
            response = testCase.verifyWarning( ...
                @() agent.run("Compute", MaxIterations=2), ...
                "aiAgent:MaxIterationsReached");

            testCase.verifyEqual(response, "");
            testCase.verifyFalse(ismissing(response));
        end

        function run_noToolCallsEmptyText_returnsEmptyText(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"", aisdk.llms.message.LLMTextMessage("", "assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, "You are helpful.");
            response = agent.run("Hi");

            testCase.verifyEqual(response, "");
        end

        function run_maxIterationsWithAccumulatedText_returnsJoinedText(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers);

            client = MockClient();
            client.GenerateOutputs = {
                {"Working...", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 1, "b", 2), "call_1"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
                {"Still going...", aisdk.llms.message.LLMToolCallMessage("addTwoNumbers", struct("a", 3, "b", 4), "call_2"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, "You are helpful.", tool);
            response = testCase.verifyWarning( ...
                @() agent.run("Compute", MaxIterations=2), ...
                "aiAgent:MaxIterationsReached");

            testCase.verifyEqual(response, "Working..." + newline + "Still going...");
        end

        function constructor_invalidClient_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.AIAgent("not a client", "prompt"), ...
                "llms:invalidClientType");
        end

        function run_withSystemPrompt_prependsSystemMessage(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Hi!", aisdk.llms.message.LLMTextMessage("Hi!", "assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, "Be concise.");
            agent.run("Hello");

            messagesPassedToGenerate = client.GenerateInputs{1};
            firstMsg = messagesPassedToGenerate(1);
            testCase.verifyEqual(firstMsg.Role, "system");
            testCase.verifyEqual(firstMsg.Content, "Be concise.");
        end

        function run_withoutSystemPrompt_doesNotPrependSystemMessage(testCase)
            client = MockClient();
            client.GenerateOutputs = {
                {"Hi!", aisdk.llms.message.LLMTextMessage("Hi!", "assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client);
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
                {"", aisdk.llms.message.LLMToolCallMessage("nonExistentTool", struct("a", 1), "call_1"), tokens}
                {"I couldn't find that tool.", aisdk.llms.message.LLMTextMessage("I couldn't find that tool.", "assistant"), tokens}
            };

            agent = aisdk.AIAgent(client, "You are helpful.", tool);
            response = agent.run("Do something.");

            testCase.verifyEqual(response, "I couldn't find that tool.");
            toolResults = agent.Messages([agent.Messages.Role] == "tool");
            testCase.verifySubstring(toolResults(1).Content, "Error");
        end

        function toolChoice_withSpecificName_callsNamedToolAndCompletes(testCase)
            toolAdd = aisdk.LLMTool(@addTwoNumbers);
            toolGreet = aisdk.LLMTool(@greetUser);

            client = MockClient();
            client.GenerateOutputs = {
                % Round 1: model calls greetUser (forced by ToolChoice="greetUser")
                {"", aisdk.llms.message.LLMToolCallMessage("greetUser", struct("name", "Alice", "greeting", "Hi"), "call_1"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
                % Round 2: text response (model is free to finish with "auto")
                {"Hi, Alice!", aisdk.llms.message.LLMTextMessage("Hi, Alice!", "assistant"), ...
                 struct("Tokens", struct("NumInputTokens", 10, "NumOutputTokens", 5, ...
                        "NumTotalTokens", 15, "NumCachedInputTokens", 0))}
            };

            agent = aisdk.AIAgent(client, "You are helpful.", [toolAdd, toolGreet]);
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
