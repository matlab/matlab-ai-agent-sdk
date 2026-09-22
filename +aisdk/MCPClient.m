classdef MCPClient < handle
%MCPClient Client for connecting to MCP servers.
%
%   CLIENT = aisdk.MCPClient(ENDPOINT) connects to an MCP server. The
%   transport is auto-detected from ENDPOINT:
%
%     - If ENDPOINT starts with "http://" or "https://":
%         - Ending in "sse" or "sse/": uses SSE transport (deprecated)
%         - Otherwise: uses streamable HTTP transport
%     - Otherwise, ENDPOINT is interpreted as a command to launch (stdio):
%         - A scalar string is split at whitespace
%         - A string vector gives command and arguments pre-parsed
%
%   CLIENT = aisdk.MCPClient(__, Transport=T) overrides auto-detection.
%   T must be "auto", "streamable-http", "sse", or "stdio".
%   "streamable-http" and "sse" require a scalar ENDPOINT starting with
%   "http://" or "https://"; "stdio" requires a command, not a URL.
%
%   CLIENT = aisdk.MCPClient(__, ToolPrefix=PREFIX) prepends PREFIX
%   followed by an underscore to all tool names exposed to the LLM. This
%   disambiguates tools from multiple servers that share the same name.
%   PREFIX must start with a letter and contain only a-z, A-Z, 0-9, and
%   underscores.
%
%   CLIENT = aisdk.MCPClient(__, TimeOut=SECS) sets how long to wait for
%   the server, both for the connection handshake and for each subsequent
%   request. The default is 120 seconds. TimeOut is also settable after
%   construction, which affects later requests only.
%
%   After construction, the available tools are exposed as an array of
%   aisdk.llms.tool.MCPTool objects in the Tools property, ready to pass
%   to an aisdk.AIAgent or aisdk.LLMClient.
%
%   Note: Using stdio transport executes an external process. Only connect
%   to commands you trust.
%
%   Examples:
%       client = aisdk.MCPClient("https://server.example/mcp")
%       client = aisdk.MCPClient("https://server.example/sse")
%       client = aisdk.MCPClient("npx -y @modelcontextprotocol/server-everything")
%       client = aisdk.MCPClient(["npx" "-y" "@user/server" "--port" "8080"])
%       client = aisdk.MCPClient("http://localhost:8080", Transport="sse")
%
%   See also: aisdk.LLMTool

% Copyright 2026 The MathWorks, Inc.

    properties (SetAccess=private, Transient)
        Tools (1,:) aisdk.llms.tool.MCPTool
    end

    properties (SetAccess=private)
        ToolPrefix (1,1) string = ""
    end

    properties (Access = {?aisdk.llms.tool.MCPTool}, Transient)
        % ServerTools Raw tool descriptions returned by the server.
        %   Consumed by the MCPTool constructor to build the public Tools
        %   array. Not part of the public API.
        ServerTools (1,:) cell
    end

    properties
        TimeOut (1,1) double {mustBeNonnegative} = 120
    end

    properties (Access=private, Transient)
        ConnectionID string
    end

    properties (Access=private)
        Endpoint (1,:) string
        Transport (1,1) string = "auto"
    end

    methods
        function obj = MCPClient(endpoint, options)
            arguments
                endpoint (1,:) string
                options.Transport (1,1) string {mustBeMember(options.Transport, ...
                    ["auto", "streamable-http", "sse", "stdio", "mock"])} = "auto"
                options.ToolPrefix (1,1) string {mustBeValidToolPrefixOrEmpty} = ""
                options.TimeOut (1,1) double {mustBeNonnegative} = 120
            end

            obj.ToolPrefix = options.ToolPrefix;
            obj.Endpoint = endpoint;
            obj.Transport = options.Transport;
            % Assign before connecting: the connect handshake and the first
            % listTools both happen below, so a value set by the caller
            % afterwards would arrive too late to govern them.
            obj.TimeOut = options.TimeOut;

            try
                obj.connect();
                obj.ServerTools = obj.retrieveTools();
            catch err
                % Endpoint and transport problems are for the caller to
                % fix, so report them against the constructor call rather
                % than against an internal MCPClient helper.
                throwAsCaller(err);
            end
            obj.Tools = aisdk.llms.tool.MCPTool(obj);
        end

        function delete(obj)
            if ~isempty(obj.ConnectionID)
                try
                    obj.request("disconnect", obj.ConnectionID);
                catch
                end
            end
        end
    end

    % prefixedToolName is applied by the MCPTool constructor when building
    % the public Tools array; it is not part of the public API.
    methods (Access = {?aisdk.llms.tool.MCPTool})
        function prefixed = prefixedToolName(obj, rawName)
            if obj.ToolPrefix == ""
                prefixed = string(rawName);
            else
                prefixed = obj.ToolPrefix + "_" + string(rawName);
            end
        end
    end

    % callTool is invoked by the MCPTool objects built in the constructor;
    % it is not part of the public API. tMCPClient exercises the
    % name-resolution and argument-marshalling paths that are not otherwise
    % reachable through the public Tools array.
    methods (Access = {?aisdk.llms.tool.MCPTool, ?tMCPClient})
        function result = callTool(obj, tool, varargin)
            arguments
                obj (1,1) aisdk.MCPClient
                tool
            end
            arguments (Repeating)
                varargin
            end

            if isstruct(tool)
                toolName = string(tool.name);
                if isfield(tool, "arguments")
                    args = tool.arguments;
                    if isstruct(args)
                        paramsJson = jsonencode(args);
                    else
                        paramsJson = string(args);
                    end
                else
                    paramsJson = "{}";
                end
            else
                toolName = string(tool);
                if mod(numel(varargin), 2) ~= 0
                    error("aisdk:MCPClient:oddNameValuePairs", ...
                        aisdk.llms.internal.MessageCatalog.getMessage( ...
                        "llms:mcpClient:oddNameValuePairs"));
                end
                args = struct();
                for i = 1:2:numel(varargin)
                    args.(varargin{i}) = varargin{i+1};
                end
                paramsJson = jsonencode(args);
            end

            toolName = obj.resolveToolName(toolName);

            response = obj.request("callTool", ...
                obj.ConnectionID, toolName, paramsJson, obj.TimeOut);
            result = response.result;
        end
    end

    methods (Static)
        function obj = loadobj(obj)
            obj.connect();
            obj.ServerTools = obj.retrieveTools();
            obj.Tools = aisdk.llms.tool.MCPTool(obj);
        end
    end

    methods (Access=private)
        function connect(obj)
            [connectionType, connectUrl, stdioArgs] = ...
                aisdk.MCPClient.resolveTransport(obj.Endpoint, obj.Transport);

            % stdioArgs is passed even when empty so that the timeout keeps a
            % fixed argument position.
            response = obj.request("connect", connectUrl, connectionType, ...
                stdioArgs, obj.TimeOut);

            obj.ConnectionID = response.result.connectionId;
        end

        function rawName = resolveToolName(obj, toolName)
            % If the name matches a raw server tool name exactly, use it.
            % Otherwise, strip the ToolPrefix prefix and use the raw name.
            rawNames = cellfun(@(t) string(t.name), obj.ServerTools);
            if ismember(toolName, rawNames)
                rawName = toolName;
            elseif obj.ToolPrefix ~= "" && startsWith(toolName, obj.ToolPrefix + "_")
                rawName = extractAfter(toolName, strlength(obj.ToolPrefix) + 1);
            else
                rawName = toolName;
            end
        end

        function tools = retrieveTools(obj)
            response = obj.request("listTools", obj.ConnectionID, obj.TimeOut);
            toolList = response.result;
            if isstruct(toolList) && isfield(toolList, "tools")
                toolList = toolList.tools;
            end
            if isstruct(toolList)
                tools = arrayfun(@(t) t, toolList, UniformOutput=false);
            elseif iscell(toolList)
                tools = toolList(:)';
            else
                tools = {};
            end
        end

        function response = request(~, varargin)
            try
                responseJson = aisdk.internal.mcpclient_mex(varargin{:});
            catch mexErr
                aisdk.MCPClient.throwMexError(mexErr);
            end
            response = jsondecode(responseJson);
            if isfield(response, "error")
                if isfield(response.error, "code")
                    code = response.error.code;
                else
                    code = 1999;
                end
                aisdk.MCPClient.throwServerError(code, response.error.message);
            end
        end
    end

    methods (Static, Access = {?tMCPClient})
        function throwMexError(mexErr)
            %throwMexError Report an error raised by the MEX gateway.
            % Faults in how the MEX was called, or inside it, are local
            % problems; reporting them as server errors points the user at
            % the wrong end of the connection. The MEX message carries the
            % detail (such as which argument was wrong), so keep it.
            switch string(mexErr.identifier)
                case {"mcpclient_mex:badInput", "mcpclient_mex:badCommand", ...
                        "mcpclient_mex:internalError"}
                    error("aisdk:MCPClient:internalError", "%s", mexErr.message);
                case "mcpclient_mex:timeout"
                    aisdk.MCPClient.throwServerError(1005, mexErr.message);
                otherwise
                    aisdk.MCPClient.throwServerError(1999, mexErr.message);
            end
        end

        function throwServerError(code, rawMessage)
            catalog = @aisdk.llms.internal.MessageCatalog.getMessage;
            switch code
                case 400
                    error("aisdk:MCPClient:badRequest", "%s", ...
                        catalog("llms:mcpClient:badRequest"));
                case 401
                    error("aisdk:MCPClient:unauthorized", "%s", ...
                        catalog("llms:mcpClient:unauthorized"));
                case 403
                    error("aisdk:MCPClient:forbidden", "%s", ...
                        catalog("llms:mcpClient:forbidden"));
                case 404
                    error("aisdk:MCPClient:notFound", "%s", ...
                        catalog("llms:mcpClient:notFound"));
                case 405
                    error("aisdk:MCPClient:methodNotAllowed", "%s", ...
                        catalog("llms:mcpClient:methodNotAllowed"));
                case 502
                    error("aisdk:MCPClient:badGateway", "%s", ...
                        catalog("llms:mcpClient:badGateway"));
                case 1003
                    error("aisdk:MCPClient:hostNotFound", "%s", ...
                        catalog("llms:mcpClient:hostNotFound"));
                case 1004
                    error("aisdk:MCPClient:connectionRefused", "%s", ...
                        catalog("llms:mcpClient:connectionRefused"));
                case 1005
                    error("aisdk:MCPClient:connectionTimeout", "%s", ...
                        catalog("llms:mcpClient:connectionTimeout"));
                case 1100
                    error("aisdk:MCPClient:stdioNotFound", "%s", ...
                        catalog("llms:mcpClient:stdioNotFound"));
                case 1101
                    error("aisdk:MCPClient:stdioPermission", "%s", ...
                        catalog("llms:mcpClient:stdioPermission"));
                otherwise
                    error("aisdk:MCPClient:serverError", "%s", rawMessage);
            end
        end

        function [connectionType, connectUrl, stdioArgs] = resolveTransport(endpoint, transport)
            isUrl = isscalar(endpoint) && ...
                (startsWith(endpoint, "http://") || startsWith(endpoint, "https://"));

            if transport == "auto"
                if isUrl
                    if endsWith(endpoint, "/sse") || endsWith(endpoint, "/sse/")
                        connectionType = "sse";
                    else
                        connectionType = "http";
                    end
                else
                    connectionType = "stdio";
                end
            elseif transport == "streamable-http"
                connectionType = "http";
            else
                connectionType = transport;
            end

            catalog = @aisdk.llms.internal.MessageCatalog.getMessage;
            if connectionType == "stdio"
                if isUrl
                    % Handing a URL to the process launcher fails deep
                    % inside the middleware with an unhelpful "no such
                    % file or directory"; reject it here instead.
                    error("aisdk:MCPClient:urlEndpointRequiresHttpTransport", ...
                        "%s", catalog("llms:mcpClient:urlEndpointRequiresHttpTransport"));
                end
                if isscalar(endpoint)
                    parts = split(endpoint);
                else
                    parts = endpoint;
                end
                connectUrl = parts(1);
                stdioArgs = parts(2:end);
            elseif connectionType == "mock"
                connectUrl = endpoint;
                stdioArgs = string.empty;
            else
                if ~isscalar(endpoint)
                    error("aisdk:MCPClient:nonScalarURL", ...
                        "%s", catalog("llms:mcpClient:nonScalarURL"));
                end
                if ~isUrl
                    error("aisdk:MCPClient:httpTransportRequiresUrl", ...
                        "%s", catalog("llms:mcpClient:httpTransportRequiresUrl", ...
                        transport));
                end
                connectUrl = endpoint;
                stdioArgs = string.empty;
            end
        end
    end
end

function mustBeValidToolPrefixOrEmpty(name)
    if name ~= "" && ~isvarname(char(name))
        error("aisdk:MCPClient:invalidToolPrefix", ...
            aisdk.llms.internal.MessageCatalog.getMessage( ...
            "llms:mcpClient:invalidToolPrefix"));
    end
end
