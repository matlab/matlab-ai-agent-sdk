# aisdk.llms.tool.MCPTool

Tool wrapping an MCP server tool for use with an LLM.

## Syntax

```matlab
tools = aisdk.llms.tool.MCPTool(mcpClient)
```

## Description

`aisdk.llms.tool.MCPTool(mcpClient)` creates an array of `MCPTool` objects from an `mcpHTTPClient`.

You can also create MCP tools using the [`LLMTool`](../../LLMTool.md) factory function:

```matlab
tools = aisdk.LLMTool(mcpClient);
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Name` | `string` | | Name of the tool. |
| `DisplayTitle` | `string` | `""` | Name of the tool for display purposes. |
| `Description` | `string` | | Description of what the tool does. |
| `Annotations` | `struct` | `struct()` | Additional metadata. |
| `InputArguments` | `struct` | `struct()` | JSON Schema struct describing the tool inputs. |
| `OutputArguments` | `struct` | `struct()` | JSON Schema struct describing the tool outputs. |
| `RequiresApproval` | `RequiresApproval` | `never` | Approval mode for user confirmation before calling. Values: `never`, `once`, `always`. |

## Methods

| Method | Description |
|--------|-------------|
| `evaluate` | Evaluate the wrapped MCP tool with a struct of arguments. |
| `selectTool` | Select a tool by name from an array. |

## Examples

Create tools from an MCP server using [`mcpHTTPClient`](https://github.com/matlab-deep-learning/mcpHTTPClient) and the `LLMTool` factory:

```matlab
mcpClient = mcpHTTPClient("http://127.0.0.1:8000/math/mcp");
tools = aisdk.LLMTool(mcpClient);
```

The resulting tools can be inspected individually:

```matlab
tools(1)
%   MCPTool with properties:
%       InputArguments: [1x1 struct]
%            Name: "addTwoNumbers"
%     Description: "Add two numbers together"
```

Pass MCP tools to a client alongside other tools:

```matlab
allTools = [functionTool, tools];
[text, messages] = generate(client, "Add 3 and 4", Tools=allTools);
```

## See Also

[LocalLLMTool](LocalLLMTool.md) | [LLMTool](../../LLMTool.md)
