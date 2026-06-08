# LLMToolArgument

Description of a function parameter for tool definitions.

## Syntax

```matlab
arg = aisdk.LLMToolArgument(name)
arg = aisdk.LLMToolArgument(name, Name=Value)
args = aisdk.LLMToolArgument(prototypeStruct)
args = aisdk.LLMToolArgument(prototypeStruct, Name=Value)
```

## Description

`LLMToolArgument(name)` creates a parameter description with the specified name.

`LLMToolArgument(name, Name=Value)` specifies options using one or more name-value arguments. You can specify any of the properties below as name-value arguments.

`LLMToolArgument(prototypeStruct)` creates an array of parameter descriptions by inferring data types from the example values in the struct fields.

`LLMToolArgument(prototypeStruct, Name=Value)` specifies additional options to apply to each inferred parameter. Scalar values are broadcast; array values are applied per-element.

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Name` | `string` | | Name of the parameter. |
| `Description` | `string` | `""` | Description of the parameter. |
| `DataType` | `string` | `""` | JSON Schema type: `"string"`, `"number"`, `"integer"`, or `"boolean"`. |
| `Required` | `logical` | `true` | Whether the parameter is required. When auto-introspected from a function, name-value arguments and optional positional arguments are set to `false`. |
| `NameValue` | `logical` | `false` | Whether the parameter is a name-value argument. |

## Methods

| Method | Description |
|--------|-------------|
| `summary` | Return a table summarizing an array of parameter descriptions. |

## Examples

Create a parameter description:

```matlab
arg = aisdk.LLMToolArgument("city", DataType="string", Description="City name");
```

Create multiple and use as tool inputs:

```matlab
params = [aisdk.LLMToolArgument("x", DataType="number"), ...
          aisdk.LLMToolArgument("y", DataType="number")];
tool = aisdk.LLMTool(@myFunction, InputArguments=params);
```

Create from a prototype struct (types are inferred):

```matlab
args = aisdk.LLMToolArgument(struct("x", 1, "name", "hello"));
```

## See Also

[LocalLLMTool](llms/tool/LocalLLMTool.md)
