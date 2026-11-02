classdef hClientTestUtils
% Shared behavioral checks for concrete LLM clients.

%   Copyright 2026 The MathWorks, Inc.

    methods (Static)
        function verifyStreamedParallelToolCalls(testCase, client, responseData)
            body = struct();
            body.Data = responseData;
            response = struct("StatusCode", "OK", "Body", body);
            client.sendRequestFcn = @(~,~,~,~,~,~) response;

            [~, messages] = generate(client, "Call both tools.");

            testCase.verifyNumElements(messages, 2);
            testCase.verifyClass(messages(1), "aisdk.LLMToolCallMessage");
            testCase.verifyClass(messages(2), "aisdk.LLMToolCallMessage");
            testCase.verifyEqual([messages.Name], ["toolA" "toolB"]);
            testCase.verifyEqual([messages.ToolCallID], ["call_1" "call_2"]);
            testCase.verifyEqual(messages(1).Arguments, struct("x", 1));
            testCase.verifyEqual(messages(2).Arguments, struct("y", 2));
        end

        function verifyToolCallsNoText(testCase, client, nvp)
            arguments
                testCase
                client
                nvp.ResponseFormat
            end
            generateArgs = namedargs2cell(nvp);
            [text, messages] = generate(client, "Call a tool.", generateArgs{:});

            testCase.verifyEqual(text, "");
            testCase.verifyNumElements(messages, 1);
            testCase.verifyClass(messages, "aisdk.LLMToolCallMessage");
        end

        function verifyStreamedTextOnly(testCase, client, responseData, expectedText)
            body = struct();
            body.Data = responseData;
            response = struct("StatusCode", "OK", "Body", body);
            client.sendRequestFcn = @(~,~,~,~,~,~) response;

            [text, messages] = generate(client, "Say hello.");

            testCase.verifyEqual(text, expectedText);
            testCase.verifyNumElements(messages, 1);
            testCase.verifyClass(messages, "aisdk.LLMTextMessage");
            testCase.verifyEqual(messages.Role, "assistant");
            testCase.verifyEqual(messages.Text, expectedText);
        end

        function verifyStreamedStructuredOutput(testCase, client, responseData, prototype, expected)
            response = hClientTestUtils.okResponse(responseData);
            client.sendRequestFcn = @(~,~,~,~,~,~) response;

            text = generate(client, "Answer in JSON.", ResponseFormat=prototype);

            testCase.verifyEqual(text, expected);
        end

        function response = okResponse(responseData)
            body = struct();
            body.Data = responseData;
            response = struct("StatusCode", "OK", "Body", body);
        end

        function data = streamEventsAndMergeResponse(streamer, events, format)
            arguments
                streamer
                events
                format (1,1) string {mustBeMember(format, ["sse","ndjson"])}
            end
            events = reshape(string(events), 1, []);
            if format == "sse"
                prefix = "data: ";
            else
                prefix = "";
            end
            for event = events
                bytes = unicode2native( ...
                    char(prefix + event + newline), "UTF-8")';
                streamer.doPutData(bytes, false);
            end
            data = streamer.mergeResponseData("");
        end

        function text = escapeJSONText(text)
            text = strrep(char(text), '\', '\\');
            text = strrep(text, '"', '\"');
            text = strrep(text, char(8), '\b');
            text = strrep(text, char(9), '\t');
            text = strrep(text, newline, '\n');
            text = strrep(text, char(12), '\f');
            text = strrep(text, char(13), '\r');
        end
    end
end
