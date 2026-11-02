classdef (Abstract) hSystemOpenAICommon < matlab.unittest.TestCase
% hSystemOpenAICommon - Live tests verifying the high-level requirements shared by the OpenAI APIs.

%   Copyright 2026 The MathWorks, Inc.

    properties (Abstract, Constant)
        %Provider   API name passed to aisdk.LLMClient.
        Provider

        %ModelName   Model the live calls run against.
        ModelName

        %ClientClass   Class name of the client under test.
        ClientClass

        %EndpointPath   Path the client appends to its base URL.
        EndpointPath
    end

    properties (Access=protected)
        %Client   Live client shared by the tests below.
        Client
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

        function createLiveClient(testCase)
            % The client cannot be a property default: provider and model
            % come from abstract Constant properties, which a property
            % default expression cannot reach.
            testCase.Client = testCase.liveClient();
        end
    end

    methods (Test, TestTags = {'System'})
        %% The provider name resolves to this suite's client and endpoint

        function construct_withProviderName_resolvesToClientAndEndpoint(testCase)
            % Guards the subclass constants against the client they describe:
            % a wrong constant would otherwise let a whole suite pass against
            % the wrong API. No call is made, so this costs nothing.
            testCase.verifyClass(testCase.Client, testCase.ClientClass);
            testCase.verifyTrue(endsWith(testCase.Client.BaseURL, testCase.EndpointPath), ...
                "BaseURL should end with """ + testCase.EndpointPath + """");
        end

        %% Both OpenAI APIs answer a text prompt

        function generate_withTextPrompt_returnsAssistantMessage(testCase)
            [text, messages] = generate(testCase.Client, "Say hello.");

            % This test uses a real client for higher fidelity. Since LLM output
            % is non-deterministic, we only verify that a response is returned;
            % every other assertion here is structural.
            testCase.verifyNonEmptyResponse(text);
            testCase.assertClass(messages, "aisdk.LLMTextMessage");
            testCase.assertNumElements(messages, 1);
            testCase.verifyEqual(messages.Role, "assistant");
            testCase.verifyEqual(messages.Text, text);
        end

        %% Both OpenAI APIs report token usage the same way

        function generate_withTextPrompt_reportsTokenUsage(testCase)
            % The two APIs report usage in different wire shapes, so the
            % counters are what must agree, whichever client answered.
            [~, ~, info] = generate(testCase.Client, "Say hello.");

            testCase.verifyGreaterThan(info.Tokens.NumInputTokens, 0);
            testCase.verifyGreaterThan(info.Tokens.NumOutputTokens, 0);
            testCase.verifyEqual(info.Tokens.NumTotalTokens, ...
                info.Tokens.NumInputTokens + info.Tokens.NumOutputTokens);
            testCase.verifyGreaterThanOrEqual(info.Tokens.NumCachedInputTokens, 0);
        end

        %% Both APIs carry a system prompt, a tool call and its result through an agent run

        function run_withSystemPromptAndTool_executesToolAndAnswers(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="never");
            agent = aisdk.AIAgent(testCase.Client, ...
                SystemPrompt="You are a calculator. Use the provided tool for arithmetic.", ...
                Tools=tool, DisplayMode="off");

            response = run(agent, "What is 17 + 25?", ToolChoice="required");

            testCase.verifyHasRole(agent.Messages, "user");
            testCase.verifyHasRole(agent.Messages, "assistant");
            toolResults = testCase.verifyHasRole(agent.Messages, "tool");
            testCase.assertNotEmpty(toolResults, "Tool was not called");
            testCase.verifySubstring(toolResults(1).Result, "42");

            % The model's phrasing of the final answer is not deterministic,
            % so we only verify that a response is returned; the computed
            % value is asserted on the tool result above.
            testCase.verifyNonEmptyResponse(response);
        end

        %% Both APIs accept a structured-output schema and return the requested struct

        function generate_withStructuredOutput_returnsStructMatchingPrototype(testCase)
            import matlab.unittest.constraints.IsSameSetAs
            prototype = struct("city", "", "population", 0);

            text = generate(testCase.Client, ...
                "What is the capital of France, and what is its population?", ...
                ResponseFormat=prototype);

            testCase.assertClass(text, "struct");
            testCase.assertThat(fieldnames(text), IsSameSetAs(fieldnames(prototype)));
            testCase.verifySubstring(text.city, "Paris");
            testCase.assertClass(text.population, "double");
            testCase.verifyGreaterThan(text.population, 0);
        end

        %% Both APIs stream text losslessly and report final token counts

        function generate_withStreamFcn_deltasConcatenateToReturnedText(testCase)
            deltas = strings(1, 0);
            function collectDelta(delta)
                deltas(end+1) = string(delta);
            end
            client = testCase.streamingClient(@collectDelta);

            [text, ~, info] = generate(client, "Count from 1 to 20, separated by commas.");

            % The identity between the callback stream and the return value
            % holds whatever the model says.
            testCase.verifyGreaterThan(numel(deltas), 1);
            testCase.verifyEqual(strjoin(deltas, ""), text);
            testCase.verifyGreaterThan(info.Tokens.NumOutputTokens, 0);
        end

        %% Both APIs rebuild a tool call from their streamed events

        function generate_withStreamFcnAndTool_returnsToolCallMessageWithID(testCase)
            import matlab.unittest.constraints.HasField
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="never");
            client = testCase.streamingClient(@(~) []);

            [~, messages] = generate(client, "Add 2 and 3.", ...
                Tools=tool, ToolChoice="required");

            testCase.assertClass(messages, "aisdk.LLMToolCallMessage");
            testCase.assertNotEmpty(messages, "Expected a streamed tool call");
            testCase.verifyEqual(messages(1).Name, "addTwoNumbers");
            testCase.verifyNotEqual(messages(1).ToolCallID, "", ...
                "A streamed tool call should carry its ID");

            % The arguments the model chose are not pinned, only their fields.
            testCase.verifyThat(messages(1).Arguments, HasField("a"));
            testCase.verifyThat(messages(1).Arguments, HasField("b"));
        end
    end

    methods (Access=protected)
        % verifyNonEmptyResponse and verifyHasRole must be protected: the
        % concrete subclasses call them from live cases of their own, and
        % MATLAB resolves a private member by its defining class. The rest
        % are used only in here and would work as private; they stay
        % protected so a subclass can build its own client when the shared
        % one does not fit, as the reasoning case has to.

        function client = liveClient(testCase)
            %liveClient   Live client for the subclass's API.
            %   Temperature is left at its default. Every case below is
            %   either structural or pinned by its prompt or by
            %   ToolChoice="required", so none of them needs narrowed
            %   sampling, and leaving it unset keeps this helper usable
            %   whatever ModelName becomes: a reasoning model would reject a
            %   non-default value.
            client = aisdk.LLMClient(testCase.Provider, testCase.ModelName);
        end

        function client = streamingClient(testCase, streamFcn)
            %streamingClient   Live client reporting its deltas to STREAMFCN.
            %   Both generate signatures accept StreamFcn, but AIAgent calls
            %   generate without one, so the callback belongs on the client.
            client = aisdk.LLMClient(testCase.Provider, testCase.ModelName, ...
                StreamFcn=streamFcn);
        end

        function verifyNonEmptyResponse(testCase, response)
            testCase.verifyClass(response, "string");
            testCase.verifyNotEqual(response, "", "Expected a non-empty response");
        end

        function filtered = verifyHasRole(testCase, messages, role)
            filtered = messages([messages.Role] == role);
            testCase.verifyNotEmpty(filtered, ...
                "Message history should contain a """ + role + """ message");
        end

    end
end
