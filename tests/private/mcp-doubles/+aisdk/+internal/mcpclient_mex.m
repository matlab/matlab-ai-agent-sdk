function responseJson = mcpclient_mex(command, varargin)
% Test double that shadows the mcpclient_mex MEX gateway with an
% in-process math server.
%
% CallMCPClientUsingAIAgent needs an MCP server to connect to. Standing
% one up would make the example test depend on a second live service, so
% this double answers the gateway protocol instead. Everything above the
% gateway - aisdk.MCPClient and aisdk.tool.MCPTool - is the real code, so
% the test still covers tool discovery, name resolution and argument
% marshalling, in the same way the sendRequestWrapper double leaves the
% LLM clients themselves under test.
%
% Only the commands aisdk.MCPClient issues are supported. An unexpected
% command or argument count errors rather than returning a plausible
% response, so a change to the gateway protocol shows up here instead of
% as an obscure failure in the example.

%   Copyright 2026 The MathWorks, Inc.

    arguments
        command (1,1) string
    end
    arguments (Repeating)
        varargin
    end

    switch command
        case "connect"
            % connect(url, connectionType, stdioArgs, timeOut)
            iAssertArgumentCount(command, varargin, 4);
            response.result.connectionId = "mock-connection";

        case "listTools"
            % listTools(connectionID, timeOut)
            iAssertArgumentCount(command, varargin, 2);
            response.result.tools = iServerTools();

        case "callTool"
            % callTool(connectionID, toolName, paramsJson, timeOut)
            iAssertArgumentCount(command, varargin, 4);
            toolName = string(varargin{2});
            args = jsondecode(char(varargin{3}));
            response.result.content = struct( ...
                "type", "text", ...
                "text", iCallTool(toolName, args));

        case "disconnect"
            % disconnect(connectionID)
            iAssertArgumentCount(command, varargin, 1);
            response.result = struct;

        otherwise
            error("mcpclient_mex:badCommand", ...
                "Unsupported command ""%s"".", command);
    end

    responseJson = jsonencode(response);
end

function tools = iServerTools()
% The two arithmetic tools the example narrative refers to. The example
% asks the agent to add two numbers, and mentions that a server offering
% more than one tool yields an array of MCPTool objects, so offer two.
    tools = { ...
        iToolDescription("addTwoNumbers", "Add two numbers together"), ...
        iToolDescription("multiplyTwoNumbers", "Multiply two numbers together")};
end

function tool = iToolDescription(name, description)
    schema.type = "object";
    schema.title = name + "Arguments";
    schema.properties.a = struct("type", "integer", "title", "A");
    schema.properties.b = struct("type", "integer", "title", "B");
    schema.required = ["a" "b"];

    tool.name = name;
    tool.description = description;
    tool.inputSchema = schema;
end

function text = iCallTool(toolName, args)
    switch toolName
        case "addTwoNumbers"
            text = string(args.a + args.b);
        case "multiplyTwoNumbers"
            text = string(args.a * args.b);
        otherwise
            error("mcpclient_mex:internalError", ...
                "Unknown tool ""%s"".", toolName);
    end
end

function iAssertArgumentCount(command, args, expected)
    if numel(args) ~= expected
        error("mcpclient_mex:badInput", ...
            "Command ""%s"" expects %d arguments, got %d.", ...
            command, expected, numel(args));
    end
end
