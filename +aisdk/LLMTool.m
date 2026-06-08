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
%       tool = LLMTool(@(x) x+1, "increment", Description="Add one")
%
%   See also: aisdk.llms.tool.LocalLLMTool, aisdk.llms.tool.MCPTool

% Copyright 2026 The MathWorks, Inc.

arguments
    toolDefinition(1,:)
end
arguments (Repeating)
    varargin
end

if isa(toolDefinition, "function_handle")
    tools = aisdk.llms.tool.LocalLLMTool(toolDefinition, varargin{1:end});
elseif isa(toolDefinition, "mcpHTTPClient") % eventually "mcpClient"
    tools = aisdk.llms.tool.MCPTool(toolDefinition);
else
    error("llms:invalidFunctionDefinition", ...
        aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:invalidFunctionDefinition"));
end
end
