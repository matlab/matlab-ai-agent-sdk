classdef tCallResponsesAPI < matlab.unittest.TestCase
%tCallResponsesAPI Tests for parameter building and output parsing in
%   callResponsesAPI.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        %% Basic parameter structure
        function buildParams_includesModelAndInput(testCase)
            params = callAPIAndCaptureRequest();
            testCase.verifyEqual(params.model, "gpt-4o");
            testCase.verifyEqual(params.input{1}.role, "user");
            testCase.verifyEqual(params.input{1}.content, "Hello");
        end

        function buildParams_storeIsFalse(testCase)
            params = callAPIAndCaptureRequest();
            testCase.verifyEqual(params.store, false);
        end

        function buildParams_streamTrue_whenStreamFcnSet(testCase)
            params = callAPIAndCaptureRequest(StreamFcn=@(x) disp(x));
            testCase.verifyTrue(params.stream);
        end

        function buildParams_streamFalse_whenNoStreamFcn(testCase)
            params = callAPIAndCaptureRequest();
            testCase.verifyFalse(params.stream);
        end

        function buildParams_toolsAdded_asFlatFunctions(testCase)
            import matlab.unittest.constraints.HasField
            tools = {struct("type","function","name","myTool","parameters",struct())};
            params = callAPIAndCaptureRequest(Tools=tools);
            testCase.verifyThat(params, HasField("tools"));
            testCase.verifyEqual(params.tools{1}.name, "myTool");
        end

        function buildParams_toolChoiceAdded_whenNonEmpty(testCase)
            params = callAPIAndCaptureRequest(ToolChoice="required");
            testCase.verifyEqual(params.tool_choice, "required");
        end

        function buildParams_maxTokensOmitted_whenInf(testCase)
            import matlab.unittest.constraints.HasField
            params = callAPIAndCaptureRequest(MaxNumTokens=inf);
            testCase.verifyThat(params, ~HasField("max_output_tokens"));
        end

        function buildParams_maxTokensIncluded_whenFinite(testCase)
            params = callAPIAndCaptureRequest(MaxNumTokens=100);
            testCase.verifyEqual(params.max_output_tokens, 100);
        end

        %% ReasoningEffort and Verbosity
        function buildParams_autoReasoningEffort_omitted(testCase)
            import matlab.unittest.constraints.HasField
            params = callAPIAndCaptureRequest(ReasoningEffort="auto");
            testCase.verifyThat(params, ~HasField("reasoning"));
        end

        function buildParams_reasoningEffort_nestedUnderReasoning(testCase)
            params = callAPIAndCaptureRequest(ReasoningEffort="high");
            testCase.verifyEqual(params.reasoning.effort, "high");
        end

        function buildParams_autoVerbosity_omitsVerbosity(testCase)
            import matlab.unittest.constraints.HasField
            params = callAPIAndCaptureRequest(Verbosity="auto");
            testCase.verifyThat(params, ~HasField("text"));
        end

        function buildParams_verbosity_nestedUnderText(testCase)
            params = callAPIAndCaptureRequest(Verbosity="low");
            testCase.verifyEqual(params.text.verbosity, "low");
        end

        %% ResponseFormat via text.format
        function buildParams_responseFormatJson_setsJsonObject(testCase)
            params = callAPIAndCaptureRequest(ResponseFormat="json");
            testCase.verifyEqual(params.text.format.type, 'json_object');
        end

        function buildParams_responseFormatStruct_setsJsonSchema(testCase)
            proto = struct("name", "", "score", 0.0);
            params = callAPIAndCaptureRequest(ResponseFormat=proto);
            testCase.verifyEqual(params.text.format.type, 'json_schema');
            testCase.verifyEqual(params.text.format.strict, true);
        end

        function buildParams_responseFormatText_omitsFormat(testCase)
            import matlab.unittest.constraints.HasField
            params = callAPIAndCaptureRequest(ResponseFormat="text");
            testCase.verifyThat(params, ~HasField("text"));
        end

        function buildParams_verbosityAndResponseFormat_sendsBothUnderText(testCase)
            params = callAPIAndCaptureRequest(Verbosity="low", ResponseFormat="json");
            testCase.verifyEqual(params.text.verbosity, "low");
            testCase.verifyEqual(params.text.format.type, 'json_object');
        end

        function buildParams_responseFormatJsonSchema_usesVerbatimJSON(testCase)
            rawSchema = '{"type":"object","properties":{"x":{"type":"number"}},"required":["x"],"additionalProperties":false}';
            params = callAPIAndCaptureRequest(ResponseFormat=rawSchema);
            testCase.verifyEqual(params.text.format.type, 'json_schema');
            testCase.verifyEqual(params.text.format.name, 'providedInCall');
            encoded = jsonencode(params.text.format.schema);
            testCase.verifyEqual(encoded, string(rawSchema));
        end

        %% Output items
        function parseOutput_message_returnsTextAndItem(testCase)
            msgItem = struct("type", "message", "role", "assistant", ...
                "content", {{struct("type", "output_text", "text", "Hello there")}});
            [text, items] = callWithOutput(testCase, {msgItem});
            testCase.verifyEqual(text, "Hello there");
            testCase.verifyEqual(items, {msgItem});
        end

        function parseOutput_functionCall_returnsEmptyTextAndItem(testCase)
            fcItem = struct("type", "function_call", "call_id", "call_9", ...
                "name", "getWeather", "arguments", '{"city":"Paris"}');
            [text, items] = callWithOutput(testCase, {fcItem});
            testCase.verifyEqual(text, "");
            testCase.verifyEqual(items, {fcItem});
        end

        function parseOutput_mixedItems_returnsItemsInOrder(testCase)
            reasoningItem = struct("type", "reasoning", "summary", {{}});
            fcItem = struct("type", "function_call", "call_id", "call_9", ...
                "name", "getWeather", "arguments", '{"city":"Paris"}');
            msgItem = struct("type", "message", "role", "assistant", ...
                "content", {{struct("type", "output_text", "text", "answer")}});
            [text, items] = callWithOutput(testCase, {reasoningItem, fcItem, msgItem});
            testCase.verifyEqual(text, "answer");
            testCase.verifyEqual(items, {reasoningItem, fcItem, msgItem});
        end

        function parseOutput_structArrayOutput_returnsRowCell(testCase)
            fcItems = struct("type", {"function_call", "function_call"}, ...
                "call_id", {"call_1", "call_2"}, "name", {"toolA", "toolB"}, ...
                "arguments", {'{}', '{}'});
            [~, items] = callWithOutput(testCase, fcItems');
            testCase.verifyEqual(items, num2cell(fcItems));
        end

        %% Streaming
        function streaming_textOnly_returnsStreamedText(testCase)
            msgItem = struct("type", "message", "role", "assistant", ...
                "content", {{struct("type", "output_text", "text", "Hello world")}});
            [text, items] = callStreamed(testCase, "Hello world", {msgItem});
            testCase.verifyEqual(text, "Hello world");
            testCase.verifyEqual(items, {msgItem});
        end

        function streaming_noStreamedText_returnsEmptyString(testCase)
            [text, items] = callStreamedWithoutItems(testCase, []);
            testCase.verifyEqual(text, "");
            testCase.verifyEqual(items, cell(1,0));
        end

        function streaming_reassembledItems_returnsItemsInOrder(testCase)
            % The streamer folds the items it reassembled into the response
            % body, in the same shape a non-streamed body carries.
            msgItem = struct("type", "message", "role", "assistant", ...
                "content", {{struct("type", "output_text", "text", "Let me check")}});
            fcItem = struct("type", "function_call", "call_id", "call_7", ...
                "name", "getWeather", "arguments", '{"city":"Oslo"}');
            [text, items] = callStreamed(testCase, "Let me check", {msgItem, fcItem});
            testCase.verifyEqual(text, "Let me check");
            testCase.verifyEqual(items, {msgItem, fcItem});
        end

        function nonOKStatus_returnsEmptyTextAndNoItems(testCase)
            [text, items] = callWithResponse(testCase, struct("StatusCode", "BadRequest", ...
                "Body", struct("Data", struct("error", struct("message", "bad")))));
            testCase.verifyEqual(text, "");
            testCase.verifyEqual(items, cell(1,0));
        end
    end

end

function params = callAPIAndCaptureRequest(nvp)
    arguments
        nvp.ReasoningEffort (1,1) string = "auto"
        nvp.Verbosity       (1,1) string = "auto"
        nvp.ResponseFormat               = "text"
        nvp.StreamFcn                    = []
        nvp.Tools                        = []
        nvp.ToolChoice                   = []
        nvp.MaxNumTokens    (1,1)        = inf
    end
    captured = {};
    messages = {struct("role", "user", "content", "Hello")};
    aisdk.client.internal.callResponsesAPI(messages, nvp.Tools, ...
        ModelName="gpt-4o", ToolChoice=nvp.ToolChoice, ...
        Temperature="auto", TopP="auto", MaxNumTokens=nvp.MaxNumTokens, ...
        ResponseFormat=nvp.ResponseFormat, ...
        ReasoningEffort=nvp.ReasoningEffort, Verbosity=nvp.Verbosity, ...
        APIKey="fake-key", TimeOut=10, StreamFcn=nvp.StreamFcn, ...
        sendRequestFcn=@fakeSendRequest, Endpoint="https://fake");

    params = captured{1};

    function [response, streamedText] = fakeSendRequest(parameters, ~, ~, ~, ~)
        captured{1} = parameters;
        msgItem = struct("type", "message", "role", "assistant", ...
            "content", {{struct("type", "output_text", "text", "fake")}});
        responseData = struct("output", {{msgItem}}, ...
            "usage", struct("input_tokens", 0, "output_tokens", 0, "total_tokens", 0));
        response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
        streamedText = "";
    end
end

function [text, items] = callStreamed(~, streamedText, outputItems)
% Call with a StreamFcn set, simulating what sendRequest returns after a
% streamed call: STREAMEDTEXT is the joined output_text deltas, and the
% body holds only the token usage and the OUTPUTITEMS the streamer
% reassembled.

    responseData = struct("output", {outputItems}, ...
        "usage", struct("input_tokens", 1, "output_tokens", 1, "total_tokens", 2));
    [text, items] = callStreamedWithBody(streamedText, responseData);
end

function [text, items] = callStreamedWithoutItems(~, streamedText)
% Call with a StreamFcn set, simulating what sendRequest returns after a
% streamed call in which the streamer reassembled no items: the body holds
% only the token usage, without an "output" field.

    responseData = struct("usage", struct("input_tokens", 1, "output_tokens", 1, "total_tokens", 2));
    [text, items] = callStreamedWithBody(streamedText, responseData);
end

function [text, items] = callStreamedWithBody(streamedText, responseData)
    messages = {struct("role", "user", "content", "Hi")};
    [text, items] = aisdk.client.internal.callResponsesAPI(messages, [], ...
        ModelName="gpt-4o", ToolChoice=[], ...
        Temperature="auto", TopP="auto", MaxNumTokens=inf, ...
        ResponseFormat="text", ReasoningEffort="auto", Verbosity="auto", ...
        APIKey="fake-key", TimeOut=10, StreamFcn=@(~) [], ...
        sendRequestFcn=@fakeSendRequest, Endpoint="https://fake");

    function [response, streamed] = fakeSendRequest(~, ~, ~, ~, ~)
        response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
        streamed = streamedText;
    end
end

function [text, items] = callWithOutput(testCase, outputItems)
    responseData = struct("output", {outputItems}, ...
        "usage", struct("input_tokens", 1, "output_tokens", 1, "total_tokens", 2));
    [text, items] = callWithResponse(testCase, ...
        struct("StatusCode", "OK", "Body", struct("Data", responseData)));
end

function [text, items] = callWithResponse(~, response)
    messages = {struct("role", "user", "content", "Hi")};
    [text, items] = aisdk.client.internal.callResponsesAPI(messages, [], ...
        ModelName="gpt-4o", ToolChoice=[], ...
        Temperature="auto", TopP="auto", MaxNumTokens=inf, ...
        ResponseFormat="text", ReasoningEffort="auto", Verbosity="auto", ...
        APIKey="fake-key", TimeOut=10, StreamFcn=[], ...
        sendRequestFcn=@(~,~,~,~,~) deal(response, ""), Endpoint="https://fake");
end
