classdef tSystem < matlab.unittest.TestCase
% tSystem - Tests verifying the high-level requirements of the SDK.

%   Copyright 2026 The MathWorks, Inc.

    properties
        Client = aisdk.LLMClient("openai", "gpt-4.1-mini", Temperature=0)
    end

    properties (TestParameter)
        Provider = struct( ...
            "openai", struct("api", "openai", "model", "gpt-4.1-mini"), ...
            "ollama", struct("api", "ollama", "model", "qwen3:0.6b"))
    end

    methods (TestClassSetup)
        function addToPath(testCase)
            % Functions with arguments blocks enable automatic input detection
            % by LLMTool. Local functions do not support this, so we use the
            % resources/functions folder instead.
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(fileparts(mfilename("fullpath")), "resources", "functions")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(fileparts(mfilename("fullpath")), "helpers")));
        end
    end

    methods (Test, TestTags = {'System'})
        %% Agents can call LLMs and manage conversation history

        function run_withSingleQuery_returnsResponseAndUpdatesHistory(testCase)
            agent = aisdk.AIAgent(testCase.Client, DisplayMode = "off");

            response = run(agent, "Say hello.");

            testCase.verifyNonEmptyResponse(response);
            testCase.verifyHasRole(agent.Messages, "user");
            testCase.verifyHasRole(agent.Messages, "assistant");
        end

        function run_withToolCall_returnsResponseAfterToolExecution(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers);
            agent = aisdk.AIAgent(testCase.Client, Tools=tool, DisplayMode = "off");

            response = run(agent, "What is 2 + 3?", ToolChoice="required");

            testCase.verifyNonEmptyResponse(response);
            testCase.verifyHasRole(agent.Messages, "user");
            testCase.verifyHasRole(agent.Messages, "tool");
            testCase.verifyHasRole(agent.Messages, "assistant");
        end

        %% SDK supports multiple LLM providers

        function LLMClient_withProvider_generatesResponse(testCase, Provider)
            client = aisdk.LLMClient(Provider.api, Provider.model, Temperature=0);

            response = generate(client, "Say hello.");

            testCase.verifyEqual(client.ModelName, Provider.model);
            testCase.verifyNonEmptyResponse(response);
        end

        %% Tools can wrap MATLAB functions

        function run_withNamedFunctionTool_returnsComputedResult(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers);
            agent = aisdk.AIAgent(testCase.Client, Tools=tool, DisplayMode = "off");

            run(agent, "Compute 7 + 11.", ToolChoice="required");

            toolResults = agent.Messages([agent.Messages.Role] == "tool");
            testCase.assertNotEmpty(toolResults, "Tool was not called");
            testCase.verifySubstring(toolResults(1).Result, "18");
        end

        function run_withAnonymousFunctionTool_returnsComputedResult(testCase)
            tool = aisdk.LLMTool(@(x) x^2, Name="squareNumber", ...
                Description="Square a number", ...
                InputArguments=struct(x=2), ...
                OutputArguments=struct(result=4));
            agent = aisdk.AIAgent(testCase.Client, Tools=tool, DisplayMode = "off");

            run(agent, "What is 5 squared?", ToolChoice="required");

            toolResults = agent.Messages([agent.Messages.Role] == "tool");
            testCase.assertNotEmpty(toolResults, "Tool was not called");
            testCase.verifySubstring(toolResults(1).Result, "25");
        end

        function run_withNamespacedFunctionTool_returnsComputedResult(testCase)
            tool = aisdk.LLMTool(@some.namespace.testFcn);
            agent = aisdk.AIAgent(testCase.Client, Tools=tool, DisplayMode = "off");

            run(agent, "Increment 6 by one.", ToolChoice="required");

            toolResults = agent.Messages([agent.Messages.Role] == "tool");
            testCase.assertNotEmpty(toolResults, "Tool was not called");
            testCase.verifySubstring(toolResults(1).Result, "7");
        end

        %% Agents can orchestrate multiple tools

        function run_withMultipleTools_returnsResponse(testCase)
            addTool = aisdk.LLMTool(@addTwoNumbers);
            greetTool = aisdk.LLMTool(@greetUser);
            agent = aisdk.AIAgent(testCase.Client, ...
                Tools=[addTool, greetTool], DisplayMode = "off");

            response = run(agent, "Add 4 and 5.");

            % This test uses a real client for higher fidelity. Since LLM output          
            % is non-deterministic, we only verify that a response is returned.
            testCase.verifyNonEmptyResponse(response);
        end

        %% Tools can be loaded from MCP servers

        function run_withMCPTools_callsToolAndReturnsResult(testCase)
            addDef = struct( ...
                "name", "add", ...
                "description", "Add two numbers", ...
                "inputSchema", struct( ...
                    "properties", struct("a", struct("type","integer"), "b", struct("type","integer")), ...
                    "required", {{"a","b"}}, ...
                    "type", "object"));
            multiplyDef = struct( ...
                "name", "multiply", ...
                "description", "Multiply two numbers", ...
                "inputSchema", struct( ...
                    "properties", struct("a", struct("type","integer"), "b", struct("type","integer")), ...
                    "required", {{"a","b"}}, ...
                    "type", "object"));

            mcpClient = mcpHTTPClientMock({addDef, multiplyDef}, @(~,varargin) "5");

            tools = aisdk.LLMTool(mcpClient);

            testCase.verifyNumElements(tools, 2);
            testCase.verifyClass(tools, "aisdk.llms.tool.MCPTool");
            testCase.verifyEqual(tools(1).Name, "add");
            testCase.verifyEqual(tools(2).Name, "multiply");

            agent = aisdk.AIAgent(testCase.Client, Tools=tools, DisplayMode = "off");

            run(agent, "Add 2 and 3.", ToolChoice="required");

            toolResults = agent.Messages([agent.Messages.Role] == "tool");
            testCase.assertNotEmpty(toolResults, "MCP tool should have been called");
            testCase.verifySubstring(toolResults(1).Result, "5");
        end

        %% Tools support human-in-the-loop approval

        function run_withApprovalRequired_callsApprovalFcn(testCase)
            approvalWasCalled = false;
            function result = approve(~, ~)
                approvalWasCalled = true;
                result.Approved = true;
                result.Permanent = false;
                result.Reason = "";
            end
            tool = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="always");
            agent = aisdk.AIAgent(testCase.Client, Tools=tool, ...
                ApprovalFcn=@approve, DisplayMode = "off");

            run(agent, "Add 3 and 4.", ToolChoice="required");

            testCase.verifyTrue(approvalWasCalled, ...
                "Approval function should have been called");
        end

        function run_withApprovalReasonAndRequiredTool_succeeds(testCase)
            function result = approveWithReason(~, ~)
                result.Approved = true;
                result.Permanent = false;
                result.Reason = "Approved by user.";
            end

            tool = aisdk.LLMTool(@addTwoNumbers, ...
                Description="Add two numbers", ...
                InputArguments=struct(a=1, b=2), ...
                RequiresApproval="always");
            agent = aisdk.AIAgent(testCase.Client, Tools=tool, ...
                ApprovalFcn=@approveWithReason, DisplayMode="off");

            response = run(agent, "Add 3 and 4.", ToolChoice="required");

            testCase.verifySubstring(response, "7");
        end

        function run_withApprovalDenied_recordsDenialInHistory(testCase)
            function result = denyApproval(~, ~)
                result.Approved = false;
                result.Permanent = false;
                result.Reason = "User denied this action.";
            end
            tool = aisdk.LLMTool(@addTwoNumbers, RequiresApproval="always");
            agent = aisdk.AIAgent(testCase.Client, Tools=tool, ...
                ApprovalFcn=@denyApproval, DisplayMode = "off");

            run(agent, "Add 3 and 4.", ToolChoice="required");

            toolResultMsgs = agent.Messages([agent.Messages.Role] == "tool");
            testCase.assertNotEmpty(toolResultMsgs, "Expected a tool result");
            testCase.verifySubstring(toolResultMsgs(1).Result, "User denied this action.");
        end

        %% Agents can delegate to subagents

        function run_withSubagentTool_delegatesAndReturnsResult(testCase)

            function [obs, workspace] = runMathSubagent(workspace, prompt)
                mathTool = aisdk.LLMTool(@addTwoNumbers);
                sub = aisdk.AIAgent(testCase.Client, Tools=mathTool);
                obs = run(sub, prompt, ToolChoice="required", DisplayMode = "off");
            end

            delegateTool = aisdk.LLMTool(@runMathSubagent, Name="runMathSubagent", ...
                Description="Delegate a math question to a math expert subagent", ...
                InputArguments=aisdk.LLMToolArgument("prompt", DataType="string", ...
                    Description="The math question"), ...
                OutputArguments=struct(obs=""), ...
                Workspace="agent");
            
            supervisor = aisdk.AIAgent(testCase.Client, ...
                SystemPrompt="You are a supervisor. Delegate math questions using the runMathSubagent tool.", ...
                Tools=delegateTool, DisplayMode = "off");

            run(supervisor, "What is 10 + 20?", ToolChoice="required");

            toolCalls = supervisor.Messages([supervisor.Messages.Type] == "tool-call");
            testCase.assertNotEmpty(toolCalls, "Expected a tool call");
            toolResults = supervisor.Messages([supervisor.Messages.Role] == "tool");
            testCase.assertNotEmpty(toolResults, "Expected a tool result");
            testCase.verifySubstring(toolResults(1).Result, "30");
        end

        %% Tools can share data through the agent workspace

        function run_withWorkspaceEnabledTool_modifiesWorkspace(testCase)

            function [obs, ws] = storeValue(ws, value)
                ws.storedValue = value;
                obs = "Stored " + value;
            end
            
            % Tools using the workspace require explicit inputs definition
            storeTool = aisdk.LLMTool(@storeValue, ...
                Description="Store a number in workspace", ...
                InputArguments=struct("value", 42), ...
                OutputArguments=struct(obs=""), ...
                Workspace="agent");

            agent = aisdk.AIAgent(testCase.Client, ...
                Tools=storeTool, Workspace=struct(), DisplayMode = "off");

            run(agent, "Store the number 42.", ToolChoice="required");

            testCase.verifyEqual(agent.Workspace.storedValue, 42);
        end

        %% Agents operate tools with configurable tool choice

        function run_withToolChoiceRequired_callsToolRegardlessly(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers);
            agent = aisdk.AIAgent(testCase.Client, Tools=tool, DisplayMode = "off");

            run(agent, "Hello, how are you?", ToolChoice="required");

            toolCalls = agent.Messages([agent.Messages.Type] == "tool-call");
            testCase.assertNotEmpty(toolCalls, "Expected a tool call");
            testCase.verifyEqual(toolCalls(1).Name, "addTwoNumbers");
        end

        function run_withToolChoiceNone_doesNotCallAnyTool(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers);
            agent = aisdk.AIAgent(testCase.Client, Tools=tool, DisplayMode = "off");

            run(agent, "What is 2 + 3?", ToolChoice="none");

            testCase.verifyEmpty( ...
                agent.Messages([agent.Messages.Type] == "tool-call"), ...
                "No tool should be called when ToolChoice is none");
        end

        function run_withMaxIterationsReached_warnsAndPreservesHistory(testCase)
            tool = aisdk.LLMTool(@()"Page loaded. More pages available.", Name="fetchNextPage", ...
                InputArguments=struct(), OutputArguments=struct(result=""));
            agent = aisdk.AIAgent(testCase.Client, ...
                SystemPrompt="Always fetch the next page.", Tools=tool, ...
                MaxIterations=3, DisplayMode = "off");

            testCase.verifyWarning( ...
                @() run(agent, "Fetch all pages.", ToolChoice="fetchNextPage"), ...
                "aiAgent:MaxIterationsReached");

            testCase.verifyHasRole(agent.Messages, "user");
            testCase.verifyHasRole(agent.Messages, "tool");
            % user + 3 iterations of (tool-call + tool-result) = at least 7 messages
            testCase.verifyGreaterThanOrEqual(numel(agent.Messages), 7, ...
                "Message history should contain all iterations");
        end

        %% Messages support image content for vision models

        function generate_withImageArray_returnsResponse(testCase)
            img = uint8(255 * ones(64, 64, 3));
            imageMessage = aisdk.LLMImageMessage(img);

            testCase.verifyEqual(imageMessage.Type, "image");
            testCase.verifyEqual(imageMessage.Role, "user");
            testCase.verifyEqual(size(imageMessage.Image), size(img));
            testCase.verifyClass(imageMessage.Image, "uint8");

            messages = [aisdk.LLMTextMessage("What color is this image?"), imageMessage];

            response = generate(testCase.Client, messages);

            testCase.verifyNonEmptyResponse(response);
        end

        %% SDK tracks token usage

        function run_afterCall_updatesTokenCounts(testCase)
            agent = aisdk.AIAgent(testCase.Client, DisplayMode = "off");

            run(agent, "Say hello.");

            testCase.verifyGreaterThan(agent.NumInputTokens, 0);
            testCase.verifyGreaterThan(agent.NumOutputTokens, 0);
            testCase.verifyEqual(agent.NumTotalTokens, ...
                agent.NumInputTokens + agent.NumOutputTokens);
        end

        function generate_afterCall_infoStructContainsTokenFields(testCase)
            [~, ~, info] = generate(testCase.Client, "Say hello.");

            testCase.verifyTrue(isfield(info, "Tokens"));
            testCase.verifyGreaterThan(info.Tokens.NumInputTokens, 0);
            testCase.verifyGreaterThan(info.Tokens.NumOutputTokens, 0);
            testCase.verifyGreaterThan(info.Tokens.NumTotalTokens, 0);
            testCase.verifyGreaterThanOrEqual(info.Tokens.NumCachedInputTokens, 0);
        end

        %% SDK traces tool calls in message history

        function run_afterToolUse_tracksCallAndArguments(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers);
            agent = aisdk.AIAgent(testCase.Client, Tools=tool, DisplayMode = "off");

            run(agent, "Add 5 and 9.", ToolChoice="required");

            toolCalls = agent.Messages([agent.Messages.Type] == "tool-call");
            testCase.assertNotEmpty(toolCalls, "Expected a tool call");
            testCase.verifyEqual(toolCalls(1).Name, "addTwoNumbers");
            testCase.verifyTrue(isfield(toolCalls(1).Arguments, "a"), ...
                "Tool call Arguments should contain field 'a'");
            testCase.verifyTrue(isfield(toolCalls(1).Arguments, "b"), ...
                "Tool call Arguments should contain field 'b'");

            toolResults = agent.Messages([agent.Messages.Role] == "tool");
            testCase.assertNotEmpty(toolResults, "Expected a tool result");
            testCase.verifyNotEqual(toolResults(1).Result, "", ...
                "Tool result should contain the computed output");
        end
    end

    methods (Access=private)
        function verifyNonEmptyResponse(testCase, response)
            testCase.verifyClass(response, "string");
            testCase.verifyNotEqual(response, "", "Expected a non-empty response");
        end

        function verifyHasRole(testCase, messages, role)
            testCase.verifyNotEmpty( ...
                messages([messages.Role] == role), ...
                "Message history should contain a """ + role + """ message");
        end

    end
end

