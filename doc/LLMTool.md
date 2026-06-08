# LLMTool

Create LLM tools from various specifications.

## Syntax

```matlab
tools = aisdk.LLMTool(fcnHandle)
tools = aisdk.LLMTool(fcnHandle, name)
tools = aisdk.LLMTool(mcpClient)
tools = aisdk.LLMTool(___,Name=Value)
```

## Description

`LLMTool(fcnHandle)` creates a `LocalLLMTool` from a function handle.

`LLMTool(fcnHandle, name)` creates a `LocalLLMTool` with an explicit tool name. Required for anonymous functions; optional for named functions (defaults to the function name).

`LLMTool(fcnHandle, Name=Value)` passes additional name-value arguments to the `LocalLLMTool` constructor. See [LocalLLMTool](llms/tool/LocalLLMTool.md) for details.

`LLMTool(mcpClient)` creates an array of `MCPTool` objects from an `mcpHTTPClient`.

## Input Arguments

| Argument      | Type                              | Description                                                                                                                                                                  |
| ------------- | --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `fcnHandle` | `function_handle`               | Function handle to wrap as a tool. Anonymous functions are supported but require the `name` argument.                                                                        |
| `name`      | `string`                        | Tool name. Optional for named functions (defaults to the function name). Required for anonymous functions.                                                                    |
| `mcpClient` | `mcpHTTPClient`                 | MCP client whose server tools are converted to `MCPTool` objects. Available from [matlab-deep-learning/mcpHTTPClient](https://github.com/matlab-deep-learning/mcpHTTPClient). |

## Name-Value Arguments

| Name                | Type                              | Default       | Description                                                                                       |
| ------------------- | --------------------------------- | ------------- | ------------------------------------------------------------------------------------------------- |
| `Description`     | `string`                        | from metadata | Description of what the tool does.                                                                |
| `DisplayTitle`    | `string`                        | `Name`      | Name of the tool for display purposes.                                                            |
| `InputArguments`  | `struct` or `LLMToolArgument` | from metadata | Descriptions of the function inputs. Use `struct()` syntax to infer types from example values.  |
| `OutputArguments` | `struct` or `LLMToolArgument` | from metadata | Descriptions of the function outputs.                                                             |
| `Annotations`     | `struct`                        | `struct()`  | Additional metadata.                                                                              |
| `RequiresApproval` | `"never"`, `"once"`, or `"always"` | `"never"` | Whether the agent pauses for user approval before executing this tool. |
| `Workspace`       | `"none"` or `"agent"`           | `"none"`    | Whether the tool receives and returns the agent workspace. See [Persisting Data Between Tool Calls](#persisting-data-between-tool-calls). |

## Examples

Create a tool from a function handle. If the function has an arguments block, the name, description, and input/output types are extracted automatically:

```matlab
tool = aisdk.LLMTool(@addTwoNumbers);
```

Create a tool from a function handle with overrides:

```matlab
tool = aisdk.LLMTool(@sin, Description="Sine of argument in radians", InputArguments=struct("angle", pi/2));
```

Create a tool from a local function, providing metadata explicitly:

```matlab
tool = aisdk.LLMTool(@myLocalFcn, ...
    Description="Add two numbers together", InputArguments=struct('a', 5, 'b', pi));
```

Create tools from an MCP server:

```matlab
mcpClient = mcpHTTPClient("http://127.0.0.1:8000/math/mcp");
tools = aisdk.LLMTool(mcpClient);
```

Concatenate different tool types into a heterogeneous array:

```matlab
allTools = [tool1, tool2, mcpTools];
[text, messages] = generate(client, "Do something", Tools=allTools);
```

## Persisting Data Between Tool Calls

When `Workspace="agent"`, the tool function can read and modify the agent's `Workspace` — a struct that persists across tool calls within an agent run. This allows tools to share state (e.g. store intermediate results for later tools to use).

A workspace-enabled tool function must follow this signature:

```matlab
function [output, workspace] = myTool(workspace, arg1, arg2, ...)
    % workspace is the agent's Workspace struct, passed in as the first argument.
    % arg1, arg2, ... are the tool's declared InputArguments.
    %
    % output is the observation returned to the LLM.
    % workspace (last output) is the updated Workspace written back to the agent.

    workspace.someField = arg1 + arg2;
    output = "Done";
end
```

Key points:

- The first input argument is always the agent's `Workspace` struct.
- The last output argument is always the updated `Workspace` struct, written back to `agent.Workspace` after the evaluate call.
- The declared `InputArguments` and `OutputArguments` on the tool should **not** include the workspace — it is handled implicitly.
- If the tool has multiple registered outputs, the workspace is returned after all of them: `[out1, out2, ..., workspace]`.
- Registered outputs must be JSON-serializable (strings, numbers, structs, arrays). For non-serializable data (e.g. fit objects, figures), use workspace instead.

## See Also

[LocalLLMTool](llms/tool/LocalLLMTool.md) | [MCPTool](llms/tool/MCPTool.md)
