classdef ResponsesResponseStreamer < aisdk.client.internal.SSEResponseStreamer
%ResponsesResponseStreamer Stream OpenAI Responses API events.

%   Copyright 2026 The MathWorks, Inc.

    properties (Access=private)
        OutputItemKeys = strings(1,0)
        HasUnreadableEvent = false
    end

    methods
        function this = ResponsesResponseStreamer(streamFcn)
            this@aisdk.client.internal.SSEResponseStreamer(streamFcn);
        end

        function data = mergeResponseData(this, data)
            % Throw after the HTTP transfer, so MATLAB does not wrap this
            % validation error in an HTTPException from the consumer callback.
            if this.HasUnreadableEvent
                aisdk.internal.throwError("aisdk:unreadableResponse", char(this.URI));
            end

            if ~isstruct(data)
                data = struct();
            end
            if ~isempty(this.Usage)
                data.usage = this.Usage.usage;
            end
            if ~isempty(this.StreamedOutputItems)
                data.output = this.StreamedOutputItems;
            end
        end
    end

    methods (Access=protected)
        function stop = processEvent(this, event, stop)
            if ~isfield(event, "type")
                this.HasUnreadableEvent = true;
                stop = true;
                return
            end

            switch string(event.type)
                case "response.output_text.delta"
                    if isfield(event, "delta")
                        text = event.delta;
                        this.StreamFcn(text);
                        this.ResponseText = [this.ResponseText text];
                        appendMessageText(this, itemKey(event), text);
                    end
                case {"response.output_item.added","response.output_item.done"}
                    if isfield(event, "item") && isstruct(event.item) ...
                            && isfield(event.item, "type")
                        switch string(event.item.type)
                            case "function_call"
                                updateFunctionCall(this, itemKey(event), event.item);
                            case "message"
                                outputItemIndex(this, itemKey(event), emptyMessageItem());
                        end
                    end
                case "response.function_call_arguments.delta"
                    if isfield(event, "delta")
                        appendFunctionCallArguments(this, itemKey(event), event.delta);
                    end
                case "response.function_call_arguments.done"
                    if isfield(event, "arguments")
                        setFunctionCallArguments(this, itemKey(event), event.arguments);
                    end
                case {"response.completed","response.incomplete"}
                    if isfield(event, "response") ...
                            && isfield(event.response, "usage") ...
                            && isstruct(event.response.usage) ...
                            && ~isempty(fieldnames(event.response.usage))
                        this.Usage = struct("usage", event.response.usage);
                    end
                case "response.failed"
                    if isfield(event, "response") ...
                            && isfield(event.response, "error") ...
                            && isstruct(event.response.error) ...
                            && isfield(event.response.error, "message")
                        this.StreamError = string(event.response.error.message);
                    else
                        this.StreamError = string(jsonencode(event));
                    end
                    stop = true;
                case "error"
                    if isfield(event, "message")
                        this.StreamError = string(event.message);
                    else
                        this.StreamError = string(jsonencode(event));
                    end
                    stop = true;
            end
        end
    end

    methods (Access=private)
        function idx = outputItemIndex(this, key, emptyItem)
            idx = find(this.OutputItemKeys == key, 1);
            if isempty(idx)
                idx = numel(this.StreamedOutputItems) + 1;
                this.OutputItemKeys(idx) = key;
                this.StreamedOutputItems{idx} = emptyItem;
            end
        end

        function idx = functionCallIndex(this, key)
            idx = outputItemIndex(this, key, struct( ...
                "type", "function_call", ...
                "call_id", "", ...
                "name", "", ...
                "arguments", ""));
        end

        function appendMessageText(this, key, delta)
            idx = outputItemIndex(this, key, emptyMessageItem());
            this.StreamedOutputItems{idx}.content{1}.text = ...
                this.StreamedOutputItems{idx}.content{1}.text + string(delta);
        end

        function updateFunctionCall(this, key, item)
            idx = functionCallIndex(this, key);
            entry = this.StreamedOutputItems{idx};
            if isfield(item, "call_id") && strlength(string(item.call_id)) > 0
                entry.call_id = string(item.call_id);
            end
            if isfield(item, "name") && strlength(string(item.name)) > 0
                entry.name = string(item.name);
            end
            if isfield(item, "arguments") && strlength(string(item.arguments)) > 0
                entry.arguments = string(item.arguments);
            end
            this.StreamedOutputItems{idx} = entry;
        end

        function appendFunctionCallArguments(this, key, delta)
            idx = functionCallIndex(this, key);
            this.StreamedOutputItems{idx}.arguments = ...
                this.StreamedOutputItems{idx}.arguments + string(delta);
        end

        function setFunctionCallArguments(this, key, arguments)
            idx = functionCallIndex(this, key);
            this.StreamedOutputItems{idx}.arguments = string(arguments);
        end
    end
end

function key = itemKey(event)
if isfield(event, "item_id")
    key = string(event.item_id);
elseif isfield(event, "item") && isstruct(event.item) && isfield(event.item, "id")
    key = string(event.item.id);
elseif isfield(event, "output_index")
    key = "output_index:" + string(event.output_index);
else
    key = "";
end
end

function item = emptyMessageItem()
item = struct( ...
    "type", "message", ...
    "role", "assistant", ...
    "content", {{struct("type", "output_text", "text", "")}});
end
