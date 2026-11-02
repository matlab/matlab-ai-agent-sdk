classdef tSystem_OpenAIResponses < hSystemOpenAICommon
% tSystem_OpenAIResponses - Tests verifying the high-level requirements for the OpenAI Responses API.

%   Copyright 2026 The MathWorks, Inc.

    properties (Constant)
        Provider = "openai-responses"
        ModelName = "gpt-4.1"
        ClientClass = "aisdk.client.OpenAIResponsesClient"
        EndpointPath = "responses"
    end

    properties (Constant, Access=private)
        %ReasoningModel   Reasoning model the case below runs against.
        %   Kept as a constant rather than written inline so that retargeting
        %   the case at a newer reasoning model is a one-line change.
        ReasoningModel = "gpt-5.4-mini"
    end

    methods (Test, TestTags = {'System'})

        %% The Responses API reaches a reasoning model and completes a tool loop

        function run_withReasoningModelAndTools_completesToolLoop(testCase)
            % The base's liveClient helper does not fit: this case needs a
            % different model and ReasoningEffort on top of it.
            client = aisdk.LLMClient(testCase.Provider, testCase.ReasoningModel, ...
                ReasoningEffort="low");
            tool = aisdk.LLMTool(@addTwoNumbers, ApprovalRequest="never");
            agent = aisdk.AIAgent(client, Tools=tool, DisplayMode="off");

            % Nothing is tolerated here. If the provider stops serving this
            % model the case fails with its message, and ReasoningModel above
            % is the one line to change.
            response = run(agent, "What is 17 + 25?", ToolChoice="required");

            toolResults = testCase.verifyHasRole(agent.Messages, "tool");
            testCase.assertNotEmpty(toolResults, "Tool was not called");
            testCase.verifySubstring(toolResults(1).Result, "42");

            % ToolChoice="required" pins the tool call and the assertion above
            % pins its computed value, but the model's phrasing of the final
            % answer is not deterministic, so that is only verified non-empty.
            testCase.verifyNonEmptyResponse(response);
        end
    end
end
