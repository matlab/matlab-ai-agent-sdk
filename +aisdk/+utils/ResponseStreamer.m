classdef ResponseStreamer < matlab.net.http.io.BinaryConsumer
%ResponseStreamer Responsible for obtaining the streaming results from the
%API

%   Copyright 2026 The MathWorks, Inc.

    properties
        ResponseText
        StreamFcn
        % Incomplete holds the bytes after the last newline received, which
        % start a line that has not yet arrived in full.
        Incomplete = uint8.empty(0,1)
        Usage = struct.empty
        % StreamedOutputItems holds the message and function_call output
        % items reassembled from a streamed OpenAI Responses API call, in
        % their output order and in the wire format a non-streamed response
        % body uses.
        StreamedOutputItems = {}
        % StreamError holds the error message reported by a streamed OpenAI
        % Responses API call that failed.
        StreamError = string.empty
    end

    properties (Access=private)
        % Stream ids of the items in StreamedOutputItems, in the same order.
        OutputItemKeys = strings(1,0)
    end

    methods
        function this = ResponseStreamer(streamFcn)
            this.StreamFcn = streamFcn;
        end
    end

    methods (Access=protected)
        function length = start(this)
            if this.Response.StatusCode ~= matlab.net.http.StatusCode.OK
                length = 0;
            else
                length = this.start@matlab.net.http.io.BinaryConsumer;
            end
        end
    end

    methods
        function [len,stop] = putData(this, data)
            [len,stop] = this.putData@matlab.net.http.io.BinaryConsumer(data);
            stop = doPutData(this, data, stop);
        end
    end

    methods (Access=?tresponseStreamer)
        function stop = doPutData(this, data, stop)
            % Only complete lines are decoded. The bytes after the last
            % newline are held until the rest of their line arrives, which
            % also keeps a multi-byte UTF-8 character split across chunks
            % intact. Empty DATA marks the end of the stream, so the held
            % bytes are then decoded as a last line.
            bytes = [this.Incomplete; data(:)];
            this.Incomplete = uint8.empty(0,1);
            if ~isempty(data)
                lastNewline = find(bytes == 10, 1, "last");
                if isempty(lastNewline)
                    lastNewline = 0;
                end
                this.Incomplete = bytes(lastNewline+1:end);
                bytes = bytes(1:lastNewline);
            end
            str = split(string(native2unicode(bytes.', 'UTF-8')), newline);
            % Remove the carriage return of CRLF line endings.
            str = strip(str, "right", char(13));
            str = str(strlength(str)>0);
            str = erase(str,"data: ");
            % Drop SSE comment lines and the SSE fields other than "data:".
            str = str(~startsWith(str,[":","event:","id:","retry:"]));

            for i = 1:length(str)
                if strcmp(str{i},'[DONE]')
                    stop = true;
                    return
                else
                    try
                        json = jsondecode(str{i});
                    catch
                        aisdk.internal.throwError("aisdk:stream:responseStreamer:InvalidInput");
                    end
                    captureOpenAIUsage(this, json);
                    if isfield(json,'type') && (startsWith(string(json.type),"response.") ...
                            || string(json.type) == "error")
                        stop = handleResponsesEvent(this, json, stop);
                    elseif isfield(json,'choices')
                        if isempty(json.choices)
                            continue;
                        end
                        if ~(isfield(json.choices,'finish_reason') && ...
                                ischar(json.choices.finish_reason) && ismember(json.choices.finish_reason,["stop","tool_calls"]))
                            if isfield(json.choices,"delta") && ...
                                    isfield(json.choices.delta,"tool_calls")
                                if isfield(json.choices.delta.tool_calls,"id")
                                    id = json.choices.delta.tool_calls.id;
                                    type = json.choices.delta.tool_calls.type;
                                    fcn = json.choices.delta.tool_calls.function;
                                    s = struct('id',id,'type',type,'function',fcn);
                                    txt = jsonencode(s);
                                else
                                    s = jsondecode(this.ResponseText);
                                    args = json.choices.delta.tool_calls.function.arguments;
                                    s.function.arguments = [s.function.arguments args];
                                    txt = jsonencode(s);
                                end
                                this.StreamFcn('');
                                this.ResponseText = txt;
                            elseif isfield(json.choices,"delta") && ...
                                    isfield(json.choices.delta,"content")
                                txt = json.choices.delta.content;
                                this.StreamFcn(txt);
                                this.ResponseText = [this.ResponseText txt];
                            end
                        end
                    else
                        txt = json.message.content;
                        if strlength(txt) > 0
                            this.StreamFcn(txt);
                            this.ResponseText = [this.ResponseText txt];
                        end
                        if isfield(json.message,"tool_calls")
                            s = json.message.tool_calls;
                            txt = jsonencode(s);
                            this.StreamFcn('');
                            this.ResponseText = [this.ResponseText txt];
                        end
                        captureOllamaUsage(this, json);
                        if isfield(json,"done")
                            stop = json.done;
                        end
                    end
                end
            end
        end
    end

    methods (Access=private)
        function stop = handleResponsesEvent(this, json, stop)
            % Handle a streamed OpenAI Responses API event. Text is emitted
            % as incremental "response.output_text.delta" events and
            % collected into message items, function calls are assembled
            % from the output-item and argument events,
            % and token usage arrives on the terminal "response.completed"
            % event. A "response.failed" or "error" event records its message
            % in StreamError.
            switch string(json.type)
                case "response.output_text.delta"
                    if isfield(json,"delta")
                        txt = json.delta;
                        this.StreamFcn(txt);
                        this.ResponseText = [this.ResponseText txt];
                        appendMessageText(this, itemKey(json), txt);
                    end
                case {"response.output_item.added","response.output_item.done"}
                    if isfield(json,"item") && isstruct(json.item) && isfield(json.item,"type")
                        switch string(json.item.type)
                            case "function_call"
                                updateFunctionCall(this, itemKey(json), json.item);
                            case "message"
                                outputItemIndex(this, itemKey(json), emptyMessageItem());
                        end
                    end
                case "response.function_call_arguments.delta"
                    if isfield(json,"delta")
                        appendFunctionCallArguments(this, itemKey(json), json.delta);
                    end
                case "response.function_call_arguments.done"
                    if isfield(json,"arguments")
                        setFunctionCallArguments(this, itemKey(json), json.arguments);
                    end
                case {"response.completed","response.incomplete"}
                    if isfield(json,"response") && isfield(json.response,"usage") ...
                            && isstruct(json.response.usage) && ~isempty(fieldnames(json.response.usage))
                        this.Usage = struct("usage", json.response.usage);
                    end
                case "response.failed"
                    if isfield(json,"response") && isfield(json.response,"error") ...
                            && isstruct(json.response.error) && isfield(json.response.error,"message")
                        this.StreamError = string(json.response.error.message);
                    else
                        this.StreamError = string(jsonencode(json));
                    end
                    stop = true;
                case "error"
                    if isfield(json,"message")
                        this.StreamError = string(json.message);
                    else
                        this.StreamError = string(jsonencode(json));
                    end
                    stop = true;
            end
        end

        function idx = outputItemIndex(this, key, emptyItem)
            % Position of the item for KEY in StreamedOutputItems, appending
            % EMPTYITEM on the first event for that key.
            idx = find(this.OutputItemKeys == key, 1);
            if isempty(idx)
                idx = numel(this.StreamedOutputItems) + 1;
                this.OutputItemKeys(idx) = key;
                this.StreamedOutputItems{idx} = emptyItem;
            end
        end

        function idx = functionCallIndex(this, key)
            idx = outputItemIndex(this, key, struct("type", "function_call", ...
                "call_id", "", "name", "", "arguments", ""));
        end

        function appendMessageText(this, key, delta)
            idx = outputItemIndex(this, key, emptyMessageItem());
            this.StreamedOutputItems{idx}.content{1}.text = ...
                this.StreamedOutputItems{idx}.content{1}.text + string(delta);
        end

        function updateFunctionCall(this, key, item)
            % Fill in the fields the event carries, leaving the rest as
            % already accumulated. The "added" event reports empty arguments.
            idx = functionCallIndex(this, key);
            entry = this.StreamedOutputItems{idx};
            if isfield(item,"call_id") && strlength(string(item.call_id)) > 0
                entry.call_id = string(item.call_id);
            end
            if isfield(item,"name") && strlength(string(item.name)) > 0
                entry.name = string(item.name);
            end
            if isfield(item,"arguments") && strlength(string(item.arguments)) > 0
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
            % The "done" event carries the complete argument JSON, so it
            % replaces whatever the deltas accumulated.
            idx = functionCallIndex(this, key);
            this.StreamedOutputItems{idx}.arguments = string(arguments);
        end

        function captureOpenAIUsage(this, json)
            % With stream_options.include_usage=true, the server emits a
            % trailing chunk whose "choices" is empty and whose "usage"
            % carries prompt/completion/total counts (plus
            % prompt_tokens_details.cached_tokens).
            if isfield(json,'usage') && isstruct(json.usage) && ~isempty(fieldnames(json.usage))
                this.Usage = struct("usage", json.usage);
            end
        end

        function captureOllamaUsage(this, json)
            % Ollama reports token counts as top-level fields on the final
            % chunk (prompt_eval_count = input, eval_count = output). There
            % is no cache concept.
            u = struct();
            if isfield(json,"prompt_eval_count")
                u.prompt_eval_count = json.prompt_eval_count;
            end
            if isfield(json,"eval_count")
                u.eval_count = json.eval_count;
            end
            if ~isempty(fieldnames(u))
                this.Usage = u;
            end
        end
    end
end

function key = itemKey(json)
% Identify the output item an event refers to. Argument events name it with
% "item_id", output-item events carry the id on the item itself.

if isfield(json,"item_id")
    key = string(json.item_id);
elseif isfield(json,"item") && isstruct(json.item) && isfield(json.item,"id")
    key = string(json.item.id);
elseif isfield(json,"output_index")
    key = "output_index:" + string(json.output_index);
else
    key = "";
end
end

function item = emptyMessageItem()
item = struct("type", "message", "role", "assistant", ...
    "content", {{struct("type", "output_text", "text", "")}});
end
