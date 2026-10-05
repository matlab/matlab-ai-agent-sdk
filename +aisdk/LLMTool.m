function tools = LLMTool(toolDefinition, varargin)
%LLMTool Create LLM tools from various specifications.
%
%   TOOLS = LLMTool(FCNHANDLE) creates a LocalLLMTool from a function
%   handle FCNHANDLE.
%
%   TOOLS = LLMTool(FCNHANDLE, Name=Value) passes additional name-value
%   arguments to the LocalLLMTool constructor.
%
%   TOOLS = LLMTool(MCPCLIENT) creates an array of MCPTool objects from an
%   mcpHTTPClient.
%
%   Example:
%       tool = LLMTool(@sin, Description="Compute sine")
%       tool = LLMTool(@(x) x+1, Name="increment", Description="Add one")
%
%   See also: aisdk.tool.LocalLLMTool, aisdk.tool.MCPTool

% Copyright 2026 The MathWorks, Inc.

arguments
    toolDefinition(1,:)
end
arguments (Repeating)
    varargin
end

if isa(toolDefinition, "function_handle")
    tools = aisdk.tool.LocalLLMTool(toolDefinition, varargin{1:end});
elseif isa(toolDefinition, "mcpHTTPClient") || isa(toolDefinition, "aisdk.MCPClient")
    tools = aisdk.tool.MCPTool(toolDefinition, varargin{1:end});
else
    error("aisdk:invalidFunctionDefinition", ...
        aisdk.internal.MessageCatalog.getMessage("aisdk:invalidFunctionDefinition"));
end
end
