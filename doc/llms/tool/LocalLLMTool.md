# llms.tool.LocalLLMTool

Tool wrapping a MATLAB function for use with an LLM.

## Syntax

```matlab
tool = aisdk.llms.tool.LocalLLMTool(fcnHandle)
tool = aisdk.llms.tool.LocalLLMTool(fcnHandle, name)
tool = aisdk.llms.tool.LocalLLMTool(fcnHandle, Name=Value)
tool = aisdk.llms.tool.LocalLLMTool(fcnHandle, name, Name=Value)
```

## Description

`aisdk.llms.tool.LocalLLMTool(fcnHandle)` creates a tool from a function handle. The function's name, description, and input/output signatures are automatically extracted from metadata when available.

`aisdk.llms.tool.LocalLLMTool(fcnHandle, name)` creates a tool with an explicit name. Required for anonymous functions; optional for named functions (defaults to the function name).

`aisdk.llms.tool.LocalLLMTool(fcnHandle, Name=Value)` specifies options using one or more name-value arguments. You can specify any of the properties below as name-value arguments.

You can also create an `LocalLLMTool` using the [`LLMTool`](../../LLMTool.md) factory function:

```matlab
tool = aisdk.LLMTool(@myFunction);
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Name` | `string` | | Name of the tool. Set via the optional positional `name` argument. Defaults to the function name. |
| `DisplayTitle` | `string` | | Name of the tool for display purposes. |
| `Description` | `string` | | Description of what the tool does. |
| `Annotations` | `struct` | `struct()` | Additional metadata. |
| `InputArguments` | `LLMToolArgument` | | Descriptions of the function inputs. |
| `OutputArguments` | `LLMToolArgument` | | Descriptions of the function outputs. |
| `RequiresApproval` | `RequiresApproval` | `never` | Approval mode for user confirmation before calling. Values: `never`, `once`, `always`. |
| `Workspace` | `string` | `"none"` | Whether the tool receives and returns the agent workspace. Values: `"none"`, `"agent"`. See [Persisting Data Between Tool Calls](#persisting-data-between-tool-calls). |

## Methods

| Method | Description |
|--------|-------------|
| `evaluate` | Evaluate the wrapped function with a struct of arguments. |
| `selectTool` | Select a tool by name from an array. |

## Examples

Create a tool from a function on the path. If the function has an arguments block, the name, description, and input/output types are extracted automatically. Name-value arguments and optional positional arguments are marked as not required:

```matlab
tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbers);
tool.InputArguments(1)
%   LLMToolArgument with properties:
%       Name: "a"
%       Type: "double"
%   Required: 1
%   NameValue: 0


tool = aisdk.llms.tool.LocalLLMTool(@addTwoNumbersUsingNVP);
tool.InputArguments(1)
%   LLMToolArgument with properties:
%       Name: "a"
%       Type: "number"
%   Required: 0
%   NameValue: 1

```

Override metadata on a built-in function, inferring input types from a prototype struct:

```matlab
tool = aisdk.llms.tool.LocalLLMTool(@sin, ...
    Description="Sine of argument in radians", InputArguments=struct("angle", pi/2));
```

Create a tool from a local function with explicit metadata:

```matlab
tool = aisdk.llms.tool.LocalLLMTool(@myLocalFcn, ...
    Description="Add two numbers", InputArguments=struct('a', 5, 'b', pi));
```

Create a tool with explicit input descriptions:

```matlab
inputs = aisdk.LLMToolArgument("x", DataType="number", Description="Input value");
tool = aisdk.llms.tool.LocalLLMTool(@sin, InputArguments=inputs);
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
- The last output argument is always the updated `Workspace` struct, written back to `agent.Workspace` after the call.
- The declared `InputArguments` and `OutputArguments` on the tool should **not** include the workspace — it is handled implicitly.
- If the tool has multiple registered outputs, the workspace is returned after all of them: `[out1, out2, ..., workspace]`.

Example:

```matlab
function [observation, workspace] = storeNumber(workspace, value)
    workspace.storedValue = value;
    observation = "Stored " + value;
end

tool = llms.tool.LocalLLMTool(@storeNumber, ...
    Description="Store a number in the workspace", ...
    InputArguments=struct("value", 42), ...
    Workspace="agent");

agent = AIAgent(client, "You are helpful.", tool, Workspace=struct());
```

## See Also

[MCPTool](MCPTool.md) | [LLMToolArgument](../../LLMToolArgument.md) | [LLMTool](../../LLMTool.md)
