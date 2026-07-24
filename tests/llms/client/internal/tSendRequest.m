classdef tSendRequest < matlab.unittest.TestCase
% Tests for aisdk.llms.client.internal.sendRequest.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        EmptyToken = {[], "", ''};
    end

    methods (Test, TestTags = {'Unit'})
        function sendRequest_withToken_includesAuthHeaders(testCase)
            captured = {};
            aisdk.llms.client.internal.sendRequest( ...
                struct("model", "test"), "my-token", ...
                "https://fake/v1", 10, [], @fakeSend);

            request = captured{1};
            headerNames = string({request.Header.Name});
            testCase.verifyTrue(ismember("Authorization", headerNames));
            testCase.verifyTrue(ismember("api-key", headerNames));

            authField = request.Header(headerNames == "Authorization");
            testCase.verifyEqual(authField.Value, "Bearer my-token");

            apiKeyField = request.Header(headerNames == "api-key");
            testCase.verifyEqual(apiKeyField.Value, "my-token");

            function response = fakeSend(request, ~, ~, ~)
                captured{1} = request;
                response = struct("StatusCode", "OK", ...
                    "Body", struct("Data", '{"ok":true}'));
            end
        end

        function sendRequest_emptyToken_omitsAuthHeaders(testCase, EmptyToken)
            captured = {};
            aisdk.llms.client.internal.sendRequest( ...
                struct("model", "test"), EmptyToken, ...
                "https://fake/v1", 10, [], @fakeSend);

            request = captured{1};
            headerNames = string({request.Header.Name});
            testCase.verifyFalse(ismember("Authorization", headerNames));
            testCase.verifyFalse(ismember("api-key", headerNames));

            function response = fakeSend(request, ~, ~, ~)
                captured{1} = request;
                response = struct("StatusCode", "OK", ...
                    "Body", struct("Data", '{"ok":true}'));
            end
        end

        function sendRequest_withStreamFcn_passesConsumerToSendFcn(testCase)
            captured = {};
            aisdk.llms.client.internal.sendRequest( ...
                struct("model", "test"), "tok", ...
                "https://fake/v1", 10, @(~) [], @fakeSend);

            testCase.verifyClass(captured{1}, ...
                "aisdk.llms.utils.ResponseStreamer");

            function response = fakeSend(~, ~, ~, consumer)
                captured{1} = consumer;
                response = struct("StatusCode", "OK", ...
                    "Body", struct("Data", '{"ok":true}'));
            end
        end

        function sendRequest_noStreamFcn_passesEmptyConsumer(testCase)
            captured = {};
            aisdk.llms.client.internal.sendRequest( ...
                struct("model", "test"), "tok", ...
                "https://fake/v1", 10, [], @fakeSend);

            testCase.verifyEmpty(captured{1});

            function response = fakeSend(~, ~, ~, consumer)
                captured{1} = consumer;
                response = struct("StatusCode", "OK", ...
                    "Body", struct("Data", '{"ok":true}'));
            end
        end

        function sendRequest_decodesResponseBody(testCase)
            [response, ~] = aisdk.llms.client.internal.sendRequest( ...
                struct("model", "test"), "tok", ...
                "https://fake/v1", 10, [], @fakeSend);

            testCase.verifyTrue(isstruct(response.Body.Data));
            testCase.verifyEqual(string(response.Body.Data.result), "hello");

            function response = fakeSend(~, ~, ~, ~)
                response = struct("StatusCode", "OK", ...
                    "Body", struct("Data", '{"result":"hello"}'));
            end
        end

        function sendRequest_noStreamFcn_returnsEmptyStreamedText(testCase)
            [~, streamedText] = aisdk.llms.client.internal.sendRequest( ...
                struct("model", "test"), "tok", ...
                "https://fake/v1", 10, [], @fakeSend);

            testCase.verifyEqual(streamedText, "");

            function response = fakeSend(~, ~, ~, ~)
                response = struct("StatusCode", "OK", ...
                    "Body", struct("Data", '{"ok":true}'));
            end
        end

        function sendRequest_setsTimeouts(testCase)
            captured = {};
            aisdk.llms.client.internal.sendRequest( ...
                struct("model", "test"), "tok", ...
                "https://fake/v1", 42, [], @fakeSend);

            testCase.verifyEqual(captured{1}.ConnectTimeout, 42);
            testCase.verifyEqual(captured{1}.ResponseTimeout, 42);

            function response = fakeSend(~, ~, httpOpts, ~)
                captured{1} = httpOpts;
                response = struct("StatusCode", "OK", ...
                    "Body", struct("Data", '{"ok":true}'));
            end
        end
    end
end
