classdef ChatCompletionsResponseStreamer < aisdk.client.internal.SSEResponseStreamer
%ChatCompletionsResponseStreamer Stream OpenAI Chat Completions responses.

%   Copyright 2026 The MathWorks, Inc.

    properties (Access=private)
        Role = 'assistant'
        ToolCalls = {}
        FinishReason = ''
    end

    methods
        function this = ChatCompletionsResponseStreamer(streamFcn)
            this@aisdk.client.internal.SSEResponseStreamer(streamFcn);
        end

        function data = mergeResponseData(this, data)
            if ~isstruct(data)
                data = struct();
            end

            message = struct( ...
                "role", this.Role, ...
                "content", this.ResponseText);
            if ~isempty(this.ToolCalls)
                message.tool_calls = ...
                    aisdk.client.internal.normalizeToolCallsShape(this.ToolCalls);
            end

            choice = struct("message", message);
            if ~isempty(this.FinishReason)
                choice.finish_reason = this.FinishReason;
            end
            data.choices = choice;
            if ~isempty(this.Usage)
                data.usage = this.Usage.usage;
            end
        end
    end

    methods (Access=protected)
        function stop = processData(this, data, stop)
            if data == "[DONE]"
                stop = true;
                return
            end
            stop = processData@aisdk.client.internal.SSEResponseStreamer( ...
                this, data, stop);
        end

        function stop = processEvent(this, event, stop)
            if isfield(event, "error")
                if isstruct(event.error) && isfield(event.error, "message")
                    this.StreamError = string(event.error.message);
                else
                    this.StreamError = string(jsonencode(event));
                end
                stop = true;
                return
            end

            captureUsage(this, event);
            if ~isfield(event, "choices") || isempty(event.choices)
                return
            end

            choice = event.choices(1);
            if isfield(choice, "finish_reason") && ~isempty(choice.finish_reason) ...
                    && strlength(string(choice.finish_reason)) > 0
                this.FinishReason = choice.finish_reason;
            end
            if ~isfield(choice, "delta")
                return
            end

            delta = choice.delta;
            if isfield(delta, "role") && ~isempty(delta.role) ...
                    && strlength(string(delta.role)) > 0
                this.Role = delta.role;
            end
            if isfield(delta, "content") && ~isempty(delta.content) ...
                    && strlength(string(delta.content)) > 0
                text = delta.content;
                this.StreamFcn(text);
                this.ResponseText = [this.ResponseText text];
            end
            if isfield(delta, "tool_calls")
                appendToolCalls(this, delta.tool_calls);
                this.StreamFcn('');
            end
        end
    end

    methods (Access=private)
        function appendToolCalls(this, toolCalls)
            toolCalls = aisdk.client.internal.normalizeToolCallsShape(toolCalls);
            for k = 1:numel(toolCalls)
                delta = toolCalls{k};
                if isfield(delta, "index")
                    idx = double(delta.index) + 1;
                else
                    % A truly OpenAI-compatible API will never get here,
                    % but we'll tolerate missing index fields for at least 
                    % single tool calls.
                    idx = 1;
                end
                if numel(this.ToolCalls) < idx
                    this.ToolCalls = [this.ToolCalls, ...
                        repmat({emptyToolCall()},1,idx-numel(this.ToolCalls))] ; %#ok<AGROW>
                end

                toolCall = this.ToolCalls{idx};
                if isfield(delta, "id") && strlength(string(delta.id)) > 0
                    toolCall.id = delta.id;
                end
                if isfield(delta, "type") && strlength(string(delta.type)) > 0
                    toolCall.type = delta.type;
                end
                if isfield(delta, "function")
                    functionDelta = delta.function;
                    if isfield(functionDelta, "name") ...
                            && strlength(string(functionDelta.name)) > 0
                        toolCall.function.name = functionDelta.name;
                    end
                    if isfield(functionDelta, "arguments")
                        toolCall.function.arguments = [ ...
                            toolCall.function.arguments ...
                            functionDelta.arguments];
                    end
                end
                this.ToolCalls{idx} = toolCall;
            end
        end

        function captureUsage(this, event)
            if isfield(event, "usage") && isstruct(event.usage) ...
                    && ~isempty(fieldnames(event.usage))
                this.Usage = struct("usage", event.usage);
            end
        end
    end
end

function toolCall = emptyToolCall()
toolCall = struct( ...
    "id", '', ...
    "type", 'function', ...
    "function", struct("name", '', "arguments", ''));
end
