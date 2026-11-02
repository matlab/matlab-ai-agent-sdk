classdef tSystem_OpenAIChatCompletions < hSystemOpenAICommon
% tSystem_OpenAIChatCompletions - Tests verifying the high-level requirements for the OpenAI Chat Completions API.
%   The provider is "openai", the name existing user code passes, so the
%   shared cases inherited from hSystemOpenAICommon guard the path that must
%   keep working. Running them here and in tSystem_OpenAIResponses puts the
%   two APIs side by side: a behavior one client gets right and the other
%   gets wrong shows up as the same case name passing in one suite and
%   failing in the other.

%   Copyright 2026 The MathWorks, Inc.

    properties (Constant)
        Provider = "openai"
        ModelName = "gpt-4.1"
        ClientClass = "aisdk.client.OpenAIClient"
        EndpointPath = "chat/completions"
    end

    methods (Test, TestTags = {'System'})
        %% Chat-Completions-only controls are kept by the client

        function construct_withChatCompletionsOnlyControls_retainsThem(testCase)
            % The three options exist only on the Chat Completions client;
            % the Responses client rejects them, which unit tests cover.
            % Here the point is that an existing script still gets them.
            client = testCase.legacyControlsClient();

            testCase.verifyEqual(client.StopSequences, "STOP");
            testCase.verifyEqual(client.PresencePenalty, 0.1);
            testCase.verifyEqual(client.FrequencyPenalty, 0.1);
        end

        %% Chat-Completions-only controls still reach the endpoint and work

        function generate_withChatCompletionsOnlyControls_returnsResponse(testCase)
            % All five legacy options together on one live call: the three
            % above at construction, and NumCompletions and Seed here.
            client = testCase.legacyControlsClient();

            text = generate(client, "Say hello.", NumCompletions=1, Seed=42);

            % Seed is as close to reproducible as the API offers, but the
            % model's prose still cannot be pinned, so we only verify that a
            % response is returned. What the case proves is that the five
            % options together are accepted by the endpoint.
            testCase.verifyNonEmptyResponse(text);
        end
    end

    methods (Access=private)
        function client = legacyControlsClient(testCase)
            %legacyControlsClient   Client carrying the Chat-Completions-only controls.
            %   The inherited liveClient helper sets none of them. "STOP" is
            %   upper case and is not a word a greeting contains, so it
            %   cannot truncate the reply to nothing.
            client = aisdk.LLMClient("openai", testCase.ModelName, ...
                StopSequences="STOP", ...
                PresencePenalty=0.1, FrequencyPenalty=0.1);
        end
    end
end
