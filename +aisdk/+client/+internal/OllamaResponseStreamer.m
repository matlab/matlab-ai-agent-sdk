classdef OllamaResponseStreamer < aisdk.client.internal.ResponseStreamer
%OllamaResponseStreamer Stream Ollama newline-delimited JSON responses.

%   Copyright 2026 The MathWorks, Inc.

    properties (Access=private)
        LastEvent = struct.empty
        Role = 'assistant'
        ToolCalls = cell(0,1)
    end

    methods
        function this = OllamaResponseStreamer(streamFcn)
            this@aisdk.client.internal.ResponseStreamer(streamFcn);
        end

        function data = mergeResponseData(this, data)
            if ~isempty(this.LastEvent)
                data = this.LastEvent;
            elseif ~isstruct(data)
                data = struct();
            end

            message = struct( ...
                "role", this.Role, ...
                "content", this.ResponseText);
            if ~isempty(this.ToolCalls)
                message.tool_calls = ...
                    aisdk.client.internal.normalizeToolCallsShape(this.ToolCalls);
            end
            data.message = message;

            if isfield(this.Usage, "prompt_eval_count")
                data.prompt_eval_count = this.Usage.prompt_eval_count;
            end
            if isfield(this.Usage, "eval_count")
                data.eval_count = this.Usage.eval_count;
            end
        end
    end

    methods (Access=protected)
        function stop = processLines(this, lines, stop)
            for k = 1:numel(lines)
                event = this.decodeJSON(lines(k));
                this.LastEvent = event;

                if isfield(event, "error")
                    if ischar(event.error) || isstring(event.error)
                        this.StreamError = string(event.error);
                    else
                        this.StreamError = string(jsonencode(event));
                    end
                    stop = true;
                    return
                end

                if isfield(event.message, "role") ...
                        && ~isempty(event.message.role) ...
                        && strlength(string(event.message.role)) > 0
                    this.Role = event.message.role;
                end
                text = event.message.content;
                if ~isempty(text) && strlength(string(text)) > 0
                    this.StreamFcn(text);
                    this.ResponseText = [this.ResponseText text];
                end
                if isfield(event.message, "tool_calls")
                    toolCalls = aisdk.client.internal.normalizeToolCallsShape( ...
                        event.message.tool_calls);
                    this.ToolCalls = [this.ToolCalls; toolCalls]; %#ok<AGROW>
                    this.StreamFcn('');
                end
                captureUsage(this, event);
                if isfield(event, "done")
                    stop = event.done;
                end
                if stop
                    return
                end
            end
        end
    end

    methods (Access=private)
        function captureUsage(this, event)
            usage = struct();
            if isfield(event, "prompt_eval_count")
                usage.prompt_eval_count = event.prompt_eval_count;
            end
            if isfield(event, "eval_count")
                usage.eval_count = event.eval_count;
            end
            if ~isempty(fieldnames(usage))
                this.Usage = usage;
            end
        end
    end
end
