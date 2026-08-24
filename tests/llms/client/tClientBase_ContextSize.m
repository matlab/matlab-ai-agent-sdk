classdef tClientBase_ContextSize < matlab.unittest.TestCase
% Tests for the ContextSize property on aisdk.llms.client.ClientBase.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        ClientClass = struct( ...
            "OpenAI", @aisdk.llms.client.OpenAIClient, ...
            "Ollama", @aisdk.llms.client.OllamaClient)
    end

    methods (Test, TestTags = {'Unit'})
        %% Defaults
        function defaultContextSize_isNaN(testCase, ClientClass)
            client = ClientClass("any-model");
            testCase.verifyEqual(client.ContextSize, NaN);
        end

        %% Name-value construction
        function customContextSize_isStored(testCase, ClientClass)
            client = ClientClass("any-model", ContextSize=128000);
            testCase.verifyEqual(client.ContextSize, 128000);
        end

        %% Post-construction assignment
        function contextSize_setAfterConstruction_isStored(testCase, ClientClass)
            client = ClientClass("any-model");
            client.ContextSize = 32000;
            testCase.verifyEqual(client.ContextSize, 32000);
        end
    end

end
