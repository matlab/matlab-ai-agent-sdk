classdef tClientBase < matlab.unittest.TestCase
%tClientBase Tests for aisdk.llms.client.ClientBase utilities.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        function encodeToolSingleRequired(testCase)
            tool = aisdk.LLMTool(@(x) x, "myFcn", Description="A function", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="number", Description="Value"));
            schema = captureToolSchema(tool);
            testCase.verifyEqual(schema.type, "object");
            testCase.verifyTrue(isfield(schema.properties, "x"));
            testCase.verifyEqual(schema.properties.x.type, "number");
            testCase.verifyEqual(schema.properties.x.description, "Value");
            testCase.verifyEqual(schema.required, {"x"});
        end

        function encodeToolMultipleParams(testCase)
            tool = aisdk.LLMTool(@(x) x, "myFcn", Description="A function", ...
                InputArguments=[aisdk.LLMToolArgument("a", DataType="number"), ...
                        aisdk.LLMToolArgument("b", DataType="string")]);
            schema = captureToolSchema(tool);
            testCase.verifyTrue(isfield(schema.properties, "a"));
            testCase.verifyTrue(isfield(schema.properties, "b"));
            testCase.verifyEqual(schema.properties.a.type, "number");
            testCase.verifyEqual(schema.properties.b.type, "string");
        end

        function argumentsToSchema_withEmptyDataType_omitsTypeField(testCase)
            tool = aisdk.LLMTool(@(x) x, "myFcn", Description="A function", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="", Description="A param"));
            schema = captureToolSchema(tool);
            testCase.verifyFalse(isfield(schema.properties.x, "type"));
        end

        function argumentsToSchema_withEmptyDescription_omitsField(testCase)
            tool = aisdk.LLMTool(@(x) x, "myFcn", Description="A function", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="number", Description=""));
            schema = captureToolSchema(tool);
            testCase.verifyFalse(isfield(schema.properties.x, "description"));
        end

        function encodeToolOmitsRequiredWhenNoneRequired(testCase)
            tool = aisdk.LLMTool(@(x) x, "myFcn", Description="A function", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="number", Required=false));
            schema = captureToolSchema(tool);
            testCase.verifyFalse(isfield(schema, "required"));
        end

        function encodeToolMultipleRequired(testCase)
            tool = aisdk.LLMTool(@(x) x, "myFcn", Description="A function", ...
                InputArguments=[aisdk.LLMToolArgument("a", DataType="number"), ...
                        aisdk.LLMToolArgument("b", DataType="number")]);
            schema = captureToolSchema(tool);
            testCase.verifyEqual(sort(schema.required), sort(["a", "b"]));
        end

        %% normalizeMessages
        function stringWrapsAsTextMessage(testCase)
            msgs = aisdk.llms.client.ClientBase.normalizeMessages("hello");
            testCase.verifyClass(msgs, "aisdk.LLMTextMessage");
            testCase.verifyEqual(msgs.Content, "hello");
            testCase.verifyEqual(msgs.Role, "user");
        end

        function charWrapsAsTextMessage(testCase)
            msgs = aisdk.llms.client.ClientBase.normalizeMessages('hello');
            testCase.verifyClass(msgs, "aisdk.LLMTextMessage");
        end

        function messageArrayPassesThrough(testCase)
            m = aisdk.LLMTextMessage("hi");
            msgs = aisdk.llms.client.ClientBase.normalizeMessages(m);
            testCase.verifyEqual(msgs, m);
        end

        function rejectsNumericInput(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.client.ClientBase.normalizeMessages(42), ...
                "llms:client:InvalidMessageInput");
        end

        function rejectsCellInput(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.client.ClientBase.normalizeMessages({"hello"}), ...
                "llms:client:InvalidMessageInput");
        end

        %% ToolChoice validation
        function generate_namedToolChoiceWithNoTools_errors(testCase)
            client = aisdk.llms.client.OpenAIClient("gpt-4o", APIKey="fake-key");
            client.sendRequestFcn = @fakeOk;
            testCase.verifyError( ...
                @() generate(client, "hi", ToolChoice="myFunc"), ...
                "llms:mustSetFunctionsForCall");

            function [response, streamedText] = fakeOk(~, ~, ~, ~, ~)
                response = struct("StatusCode", "OK", "Body", struct("Data", ...
                    struct("choices", struct("message", struct("role","assistant","content","x")), ...
                    "usage", struct("prompt_tokens",0,"completion_tokens",0,"total_tokens",0))));
                streamedText = "";
            end
        end

        function generate_namedToolChoiceNotInList_errors(testCase)
            client = aisdk.llms.client.OpenAIClient("gpt-4o", APIKey="fake-key");
            client.sendRequestFcn = @fakeOk;
            tool = aisdk.LLMTool(@(x) x, "toolA", Description="A tool", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="number"));
            testCase.verifyError( ...
                @() generate(client, "hi", Tools=tool, ToolChoice="unknown"), ...
                "MATLAB:validators:mustBeMember");

            function [response, streamedText] = fakeOk(~, ~, ~, ~, ~)
                response = struct("StatusCode", "OK", "Body", struct("Data", ...
                    struct("choices", struct("message", struct("role","assistant","content","x")), ...
                    "usage", struct("prompt_tokens",0,"completion_tokens",0,"total_tokens",0))));
                streamedText = "";
            end
        end

        function generate_namedToolChoiceInList_passes(testCase)
            captured = {};
            client = aisdk.llms.client.OpenAIClient("gpt-4o", APIKey="fake-key");
            client.sendRequestFcn = @fakeSend;
            tool = aisdk.LLMTool(@(x) x, "toolA", Description="A tool", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="number"));
            generate(client, "hi", Tools=tool, ToolChoice="toolA");
            testCase.verifyTrue(~isempty(captured));

            function [response, streamedText] = fakeSend(parameters, ~, ~, ~, ~)
                captured{1} = parameters;
                response = struct("StatusCode", "OK", "Body", struct("Data", ...
                    struct("choices", struct("message", struct("role","assistant","content","x")), ...
                    "usage", struct("prompt_tokens",0,"completion_tokens",0,"total_tokens",0))));
                streamedText = "";
            end
        end

        %% ToolChoice parameter encoding
        function generate_emptyToolChoiceWithTools_requestsAuto(testCase)
            captured = {};
            client = aisdk.llms.client.OpenAIClient("gpt-4o", APIKey="fake-key");
            client.sendRequestFcn = @fakeSend;
            tool = aisdk.LLMTool(@(x) x, "funcA", Description="A tool", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="number"));
            generate(client, "hi", Tools=tool, ToolChoice=[]);
            testCase.verifyEqual(captured{1}.tool_choice, "auto");

            function [response, streamedText] = fakeSend(parameters, ~, ~, ~, ~)
                captured{1} = parameters;
                response = struct("StatusCode", "OK", "Body", struct("Data", ...
                    struct("choices", struct("message", struct("role","assistant","content","x")), ...
                    "usage", struct("prompt_tokens",0,"completion_tokens",0,"total_tokens",0))));
                streamedText = "";
            end
        end

        function generate_autoToolChoiceWithNoTools_omitsField(testCase)
            captured = {};
            client = aisdk.llms.client.OpenAIClient("gpt-4o", APIKey="fake-key");
            client.sendRequestFcn = @fakeSend;
            generate(client, "hi");
            testCase.verifyFalse(isfield(captured{1}, "tool_choice"));

            function [response, streamedText] = fakeSend(parameters, ~, ~, ~, ~)
                captured{1} = parameters;
                response = struct("StatusCode", "OK", "Body", struct("Data", ...
                    struct("choices", struct("message", struct("role","assistant","content","x")), ...
                    "usage", struct("prompt_tokens",0,"completion_tokens",0,"total_tokens",0))));
                streamedText = "";
            end
        end

        function generate_namedToolChoice_requestsStruct(testCase)
            captured = {};
            client = aisdk.llms.client.OpenAIClient("gpt-4o", APIKey="fake-key");
            client.sendRequestFcn = @fakeSend;
            tool = aisdk.LLMTool(@(x) x, "myFunc", Description="A tool", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="number"));
            generate(client, "hi", Tools=tool, ToolChoice="myFunc");
            testCase.verifyEqual(captured{1}.tool_choice.type, "function");
            testCase.verifyEqual(captured{1}.tool_choice.("function").name, "myFunc");

            function [response, streamedText] = fakeSend(parameters, ~, ~, ~, ~)
                captured{1} = parameters;
                response = struct("StatusCode", "OK", "Body", struct("Data", ...
                    struct("choices", struct("message", struct("role","assistant","content","x")), ...
                    "usage", struct("prompt_tokens",0,"completion_tokens",0,"total_tokens",0))));
                streamedText = "";
            end
        end

        function generate_requiredToolChoice_passesThrough(testCase)
            captured = {};
            client = aisdk.llms.client.OpenAIClient("gpt-4o", APIKey="fake-key");
            client.sendRequestFcn = @fakeSend;
            tool = aisdk.LLMTool(@(x) x, "toolA", Description="A tool", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="number"));
            generate(client, "hi", Tools=tool, ToolChoice="required");
            testCase.verifyEqual(captured{1}.tool_choice, "required");

            function [response, streamedText] = fakeSend(parameters, ~, ~, ~, ~)
                captured{1} = parameters;
                response = struct("StatusCode", "OK", "Body", struct("Data", ...
                    struct("choices", struct("message", struct("role","assistant","content","x")), ...
                    "usage", struct("prompt_tokens",0,"completion_tokens",0,"total_tokens",0))));
                streamedText = "";
            end
        end

        %% API key resolution
        function generate_explicitAPIKey_takesPriority(testCase)
            client = aisdk.llms.client.OpenAIClient("gpt-4o", APIKey="my-explicit-key");
            params = captureClientParams(client);
            testCase.verifyEqual(params.apiKey, "my-explicit-key");
        end

        %% API key security
        function apiKey_afterSaveAndLoad_isCleared(testCase)
            client = aisdk.llms.client.OpenAIClient("gpt-4o", APIKey="secret-key");
            file = [tempname, '.mat'];
            addTeardown(testCase, @() delete(file));
            save(file, "client");
            loaded = load(file);
            params = captureClientParams(loaded.client);
            testCase.verifyEqual(params.apiKey, "");
        end

        function apiKey_externalRead_errors(testCase)
            client = aisdk.llms.client.OpenAIClient("gpt-4o", APIKey="secret-key");
            testCase.verifyError( ...
                @() client.APIKey, ...
                "MATLAB:class:GetProhibited");
        end

        function apiKey_externalWrite_errors(testCase)
            client = aisdk.llms.client.OpenAIClient("gpt-4o", APIKey="secret-key");
            testCase.verifyError( ...
                @() setAPIKey(client), ...
                "MATLAB:class:SetProhibited");

            function setAPIKey(c)
                c.APIKey = "hacked";
            end
        end
    end

end

function params = captureClientParams(client)
    captured = struct();
    client.sendRequestFcn = @fakeSendRequest;
    generate(client, "hi");
    params = captured;

    function [response, streamedText] = fakeSendRequest(~, apiKey, ~, ~, ~)
        captured.apiKey = apiKey;
        responseData = struct( ...
            "choices", struct( ...
                "message", struct("role", "assistant", "content", "fake")), ...
            "usage", struct( ...
                "prompt_tokens", 0, "completion_tokens", 0, "total_tokens", 0));
        response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
        streamedText = "";
    end
end

function schema = captureToolSchema(tool)
    captured = {};
    client = aisdk.llms.client.OpenAIClient("gpt-4o", APIKey="fake-key");
    client.sendRequestFcn = @fakeSendRequest;
    generate(client, "Hello", Tools=tool);
    funcStruct = captured{1}.tools{1}.("function");
    schema = funcStruct.parameters;

    function [response, streamedText] = fakeSendRequest(parameters, ~, ~, ~, ~)
        captured{1} = parameters;
        responseData = struct( ...
            "choices", struct( ...
                "message", struct("role", "assistant", "content", "fake")), ...
            "usage", struct( ...
                "prompt_tokens", 0, "completion_tokens", 0, "total_tokens", 0));
        response = struct("StatusCode", "OK", "Body", struct("Data", responseData));
        streamedText = "";
    end
end
