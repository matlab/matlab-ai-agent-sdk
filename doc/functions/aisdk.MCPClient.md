# aisdk.MCPClient
<a id="aisdkmcpclient"></a>

Connect to MCP server
## Description
<a id="description"></a>

Use an `aisdk.MCPClient` object to let an AI agent use tools provided by
an MCP server.
## Creation
<a id="creation"></a>
### Description
<a id="description-1"></a>

`client = aisdk.MCPClient(mcpServer)`
creates an `aisdk.MCPClient` object from the MCP server
`mcpServer`.

`client = aisdk.MCPClient(stdioCommand)`
creates an `aisdk.MCPClient` object from the stdio command
`stdioCommand`.

> [!NOTE]
> Security Considerations: Before calling `aisdk.MCPClient` with untrusted user input, validate the input to avoid unexpected code execution. Examples of untrusted user input are data from a user you might not know or from a source you have no control over.

`client = aisdk.MCPClient(___,Name=Value)`
specifies additional options using one or more name-value arguments. For example, to
specify the timeout as 10 seconds, set `TimeOut` to
`10`.
### `mcpServer` — Endpoint URI of MCP server
<a id="mcpserver"></a>

string scalar | character vector

Endpoint URI of MCP server, specified as a string scalar or character
vector.

The URI string must start with `"https://"` or
`"http://"`. If it does not, then the  software interprets the
input as an `stdioCommand` argument instead.

If the URI string ends with `"sse"` or `"sse/"`,
then the software uses the SSE protocol to communicate with the MCP server.

If the URI string does not end with `"sse"` or
`"sse/"`, then the software uses streamable HTTP to communicate
with the MCP server.

This argument sets the `Endpoint` and
`Transport` properties.

Example: `"http://server.example/mcp"`

Example: `"https://server.example/sse"`
### `stdioCommand` — Stdio command
<a id="stdiocommand"></a>

string scalar | string array

Stdio command, specified as a string scalar or string array.

When you specify the `stdioCommand` argument, the software
opens an stdio client by evaluating the stdio command. When communicating with an MCP
server, the software uses the stdio transport protocol.

If you specify the stdio command as a string scalar, then the software splits the
string at each whitespace. To specify arguments that contain spaces or that the
software computes at runtime, specify the stdio command as a string array.

> [!NOTE]
> Security Considerations: Before calling `aisdk.MCPClient` with untrusted user input, validate the input to avoid unexpected code execution. Examples of untrusted user input are data from a user you might not know or from a source you have no control over.

This argument sets the `Endpoint` and
`Transport` properties.

Example: `"npx -y @user/server --additional args"`

Example: `["npx" "-y" "@user/server" "--additional"
"args"]`
### Name-Value Arguments
<a id="name-value-arguments"></a>

Specify optional pairs of arguments as
`Name1=Value1,...,NameN=ValueN`, where `Name` is
the argument name and `Value` is the corresponding value.
Name-value arguments must appear after other arguments, but the order of the
pairs does not matter.

Example: `aisdk.MCPClient(mcpServer,TimeOut=10)` specifies the connection
timeout as 10 seconds.

#### Client Properties
<a id="client-properties"></a>

These properties can be set using name-value arguments.

[`ToolPrefix`](#toolprefix) | [`TimeOut`](#timeout) | [`Transport`](#transport)
## Properties
<a id="properties"></a>
### `Tools` — AI agent tools
<a id="tools"></a>

`MCPTool` object | array of `MCPTool` objects

AI agent tools, returned as one or more [`MCPTool`](MCPTool.md)
objects.
### `Server` — MCP server
<a id="server"></a>

string scalar | string array

MCP server, specified as string scalar or string array.

If you specify the `mcpServer` argument, then the
`Server` property contains the endpoint URI of the MCP server
specified by `mcpServer`.

If you specify the `stdioCommand` argument, then the
`Server` property contains the stdio command specified by
`stdioCommand`.

Example: `"https://server.example/mcp"`

Example: `"npx -y @user/server --additional args"`
### `ToolPrefix` — Tool prefix
<a id="toolprefix"></a>

`""` (default) | string scalar | character vector

Tool prefix, specified as a string scalar or character vector.

When you specify the `ToolPrefix` property, then the software
prepends the tool prefix, followed by an underscore, to the name of each tool provided
by the MCP server. Use this property to distinguish between tools from different MCP
servers that share the same name.

For example, if an MCP server has a tool named `"myTool"` and you
specify `ToolPrefix` as `"myFavoriteMCPServer"`,
then the resulting tool name is `"myFavoriteMCPServer_myTool"`.

Example:
`"myFavoriteMCPServer"`
### `TimeOut` — Timeout in seconds
<a id="timeout"></a>

`120` (default) | nonnegative numeric scalar

Timeout in seconds, specified as a nonnegative numeric scalar.

If the server does not return the tool call result in the timeout, then the function returns an
error.
### `Transport` — Transport mechanism for client-server communication
<a id="transport"></a>

`"auto"` (default) | `"streamable-http"` | `"sse"` | `"stdio"`

Transport mechanism for client-server communication, specified as
`"auto"`,`"streamable-http"`,
`"sse"`, or `"stdio"`.

`aisdk.MCPClient` objects support three types of transport mechanisms:

- `"streamable-http"` — Streamable HTTP

- `"sse"` — SSE

- `"stdio"` — Stdio

If `Transport` is `"auto"`, then the software
derives the transport mechanism from the `Server`:

| Transport Protocol | Rule | Example Server |
| --- | --- | --- |
| SSE | Server starts with `"http://"` or `"https://"` and server ends with `"sse"` or `"sse/"`. | `"https://server.example/sse"` |
| Streamable HTTP | Server starts with `"http://"` or `"https://"` and server does not end with `"sse"` or `"sse/"`. | `"https://server.example/mcp"` |
| Stdio | All other servers. | `"npx -y @user/server --additional args"` |

- If you specify the `mcpServer` argument and the URL ends
with `"sse"` or `"sse/"`, then the software uses
the SSE protocol.

- If you specify the `mcpServer` argument and the URL does
not end with `"sse"` or `"sse/"`, then the
software uses streamable HTTP.

- If you specify the `stdioCommand` argument, then the
software uses the stdio protocol.
## Examples
<a id="examples"></a>
### Create Tool From MCP Server
<a id="create-tool-from-mcp-server"></a>

To create one or more AI tools from the tools provided by an MCP
server, first connect to the MCP server by using the `aisdk.MCPClient`
function. Then, use the client as the input to the [`aisdk.LLMTool`](aisdk.LLMTool.md) function.

Create an MCP client from the MCP server `mcpServer`.

```
client = aisdk.MCPClient(mcpServer);
```

Extract the tools from the MCP server by using the `Tools`
property.

```
tool = client.Tools;
```

If the MCP server provides more than one tool, then `tool` is an
array of `MCPTool` objects.
### Manually Evaluate MCP Tool
<a id="manually-evaluate-mcp-tool"></a>

This example shows how to manually evaluate an LLM tool provided by an MCP server by using the `evaluate` function.

For example, evaluate tools to debug, or when creating a custom agent architecture. When you add tools to an [`aisdk.AIAgent`](aisdk.AIAgent.md) object instead, then the agent calls and evaluates tools automatically.

To learn about the input arguments of an `MCPTool` object `tool`, inspect the JSON input schema by using the `InputSchema` property.

```
tool.InputSchema
```

```
ans =

  struct with fields:

    properties: [1×1 struct]
      required: {'parameter1'}
          type: 'object'
```

The tools has one required input argument, `parameter1`. To
determine the required data type of this parameter, inspect the parameter:

```
tool.InputSchema.properties.parameter1;
```

```
ans =

  struct with fields:

    title: "parameter1"
     type: "string"
```

Evaluate the tool.

```
inputArguments = struct(parameter1="test");
output = evaluate(tool,inputArguments);
```
## See Also
<a id="see-also"></a>

[`aisdk.AIAgent`](aisdk.AIAgent.md) | [`MCPTool`](MCPTool.md) | [`aisdk.LLMTool`](aisdk.LLMTool.md) | [`evaluate`](evaluate.md)

*Copyright 2026 The MathWorks, Inc.*

