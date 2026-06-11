classdef MockClient < aisdk.llms.client.ClientBase
%MockClient A test double for LLM clients that returns scripted responses.
%
%   Set the GenerateOutputs property to a cell array of {text, messages, info}
%   rows. Each call to generate consumes the next row.

%   Copyright 2026 The MathWorks, Inc.

    properties (Constant)
        API = "mock"
    end

    properties
        %GenerateOutputs   Cell array of scripted outputs.
        %   Each row is {text, messages, info} returned by successive
        %   calls to generate.
        GenerateOutputs cell = {}
    end

    properties (Access=private)
        % Counter tracks which scripted response to return next.  Needed
        % because AIAgent.run calls generate multiple times internally
        % (e.g. tool-call then assistant reply) within a single run call,
        % so each generate call advances to the next scripted row
        % automatically.  Uses containers.Map (a handle object) so the
        % counter survives value-class copying into AIAgent.
        CallCounter
    end

    methods
        function this = MockClient()
            this.ModelName = "mock-model";
            this.BaseURL = "https://mock.endpoint";
            this.APIKey = "mock-key";
            this.CallCounter = containers.Map('KeyType','char','ValueType','double');
            this.CallCounter('n') = 0;
        end

        function [text, messages, info] = generate(this, ~, nvp)
            arguments
                this
                ~
                nvp.Tools = []
                nvp.ToolChoice = "auto"
                nvp.ResponseFormat = "text"
                nvp.SystemPrompt = []
            end
            this.CallCounter('n') = this.CallCounter('n') + 1;
            row = this.GenerateOutputs{this.CallCounter('n')};
            text = row{1};
            messages = row{2};
            info = row{3};
        end
    end

    methods (Access=protected)
        function messagesOut = convertMessages(~, ~)
            messagesOut = {};
        end

        function endpoint = parseEndpoint(~, ~)
            endpoint = "https://mock.endpoint";
        end

        function err = extractErrorMessage(~, ~)
            err = string.empty;
        end
    end

end
