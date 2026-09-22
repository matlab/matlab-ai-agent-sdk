# MCPTool
<a id="mcptool"></a>

AI agent tool from MCP server
## Description
<a id="description"></a>

Use an `MCPTool` object to define an AI agent tool from an MCP
server.
## Creation
<a id="creation"></a>

To create an `MCPTool` object, first connect to an MCP server by creating
an [`aisdk.MCPClient`](aisdk.MCPClient.md) and then extract
the tools from the server by using the `Tools` property of the MCP
client.
## Properties
<a id="properties"></a>
### `InputSchema` — Input argument schema
<a id="inputschema"></a>

Read-only: structure

This property is read-only.

Input argument schema, specified as a structure.

The software derives the input argument structure from the input schema provided by
the MCP server.

Data Types: `struct`
### `OutputSchema` — Output argument schema
<a id="outputschema"></a>

Read-only: structure

This property is read-only.

Output argument schema, specified as a structure.

The software derives the output argument structure from the output schema provided
by the MCP server.

Data Types: `struct`
### `ApprovalRequest` — Option to request human approval
<a id="approvalrequest"></a>


`"never"`
(default) | 
`"always"`
| 
`"once"`


Option to request human approval, specified as `"never"`,
`"always"`, or `"once"`.

Use this property to specify if the human user must approve the tool before the agent
evaluates it.

- `"never"` — Tool does not require approval.

- `"always"` — Always ask for approval before executing the
tool.

- `"once"` — Ask for approval the first time the agent calls the
tool. The user can choose to allow tool execution without additional approval
requests for the remainder of the agent session.

Data Types: `string`
### `Name` — Tool name
<a id="name"></a>

string scalar

Tool name, specified as a string scalar.

By default, the tool name is the name provided by the MCP server.

Data Types: `string`
### `Description` — Tool description
<a id="description-1"></a>

string scalar

Tool description, specified as a string scalar.

By default, the tool description is the description provided by the MCP
server.

Data Types: `string`
### `DisplayTitle` — Display title
<a id="displaytitle"></a>

string scalar | character vector

Display title, specified as a string scalar or character vector.

By default, the display title is the title provided by the MCP server.

The agent does not see the display title. Use the display title to create
human-readable displays, and for postprocessing and analysis.

Example: `"Sine Function"`

Data Types: `char` | `string`
### `Annotations` — Tool annotations
<a id="annotations"></a>

structure

Tool annotations, specified as a structure.

By default, the software uses the tool annotations provided by the MCP
server.

Specify tool annotations to configure the tool behavior in a custom or external
application or API.

For example, display a warning message to the end user when the agent calls a tool
that is able to overwrite or delete data. First, add an annotation to the tool:
`tool.Annotations.destructiveHint = true`. Then, in your application,
verify whether the `Annotations` property of a called tool has a
field `destructiveHint` with value `false`. If it does
not, then display a warning.

Data Types: `struct`
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

[`aisdk.LLMTool`](aisdk.LLMTool.md) | [`LocalLLMTool`](LocalLLMTool.md) | [`aisdk.AIAgent`](aisdk.AIAgent.md) | [`select`](select.md) | [`aisdk.LLMClient`](aisdk.LLMClient.md)

*Copyright 2026 The MathWorks, Inc.*

