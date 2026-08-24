# aisdk.LLMToolArgument
<a id="aisdkllmtoolargument"></a>

Argument for LLM Tool
## Description
<a id="description"></a>

Use an `aisdk.LLMToolArgument` object to define the input or output
arguments of an LLM tool.
## Creation
<a id="creation"></a>
### Description
<a id="description-1"></a>

`argument = aisdk.LLMToolArgument(name)`
creates an `aisdk.LLMToolArgument` object with the specified argument name
`name`.

`argument = aisdk.LLMToolArgument(exampleArgument)`
creates one or more `aisdk.LLMToolArgument` objects by using the example argument
`exampleArgument`.

`argument = aisdk.LLMToolArgument(___,Name=Value)`
specifies additional options using one or more name-value arguments. For example, to
specify the data type of the argument as numeric, set `DataType` to
`"number"`.
### `name` — Argument name
<a id="name"></a>

string scalar | character vector

Argument name, specified as a string scalar or character vector.

This argument sets the `Name` property.

Data Types: `string` | `char`
### `exampleArgument` — Example argument
<a id="exampleargument"></a>

scalar structure

Example argument, specified as a scalar structure.

The software uses the field name as the argument name. The software automatically
determines the data type from the field value.

If `exampleArgument` has more than one field, then the software
creates an array of `aisdk.LLMToolArgument` objects, one for each field of
the structure.

This argument sets the `Name` and `DataType`
properties.

Example: `struct(x=3.14)`

Data Types: `struct`
### Name-Value Arguments
<a id="name-value-arguments"></a>

Specify optional pairs of arguments as
`Name1=Value1,...,NameN=ValueN`, where `Name` is
the argument name and `Value` is the corresponding value.
Name-value arguments must appear after other arguments, but the order of the
pairs does not matter.

Example: `aisdk.LLMToolArgument("x",Description="Input value")`sets the
argument description to `"Input value"`.

#### Argument Properties
<a id="argument-properties"></a>

These properties can be set using name-value arguments.

[`Description`](#description) | [`DataType`](#datatype) | [`Required`](#required) | [`NameValue`](#namevalue)
## Properties
<a id="properties"></a>
### `Name` — Argument name
<a id="name-1"></a>

string scalar

Argument name, specified as a string scalar.

The argument name must be a valid variable name. To determine whether a name is a
valid variable name, use the `isvarname` function.

Data Types: `string`
### `Description` — Argument description
<a id="description-2"></a>

string scalar

Argument description, specified as a string scalar.

Provide details about the argument meaning and usage to the model to improve the
quality of the generated output.

Data Types: `string`
### `DataType` — JSON schema data type
<a id="datatype"></a>

`""` | `"string"` | `"number"` | `"integer"` | `"boolean"`

JSON schema data type, specified as `""`,
`"string"`, `"number"`,
`"integer"`, or `"boolean"`.

To use other data types, including non-scalar inputs, complex numbers, and
specialized objects including custom objects, add the data to the agent workspace and
configure the tool to work with the agent workspace. For more information, see [`aisdk.AIAgent`](aisdk.AIAgent.md).

Data Types: `string`
### `Required` — Argument is required
<a id="required"></a>

`true` | `false`

Indicates whether the argument is required, specified as `true` or
`false`.

By default:

- If `NameValue` is `false`, then
`Required` is `true`.

- If `NameValue` is `true`, then
`Required` is `false`.

Data Types: `logical`
### `NameValue` — Argument is name-value
<a id="namevalue"></a>

`false` (default) | `true`

Indicates whether the argument is a name-value argument, specified as
`true` or `false`.

Data Types: `logical`
## Examples
<a id="examples"></a>
### Create Tool Argument
<a id="create-tool-argument"></a>

Create an LLM tool argument named `"x"`. Specify the
`Description` and `Required` options.

```
description = "Temperature value for controlling the randomness of the output, specified as ''auto'' or as a numeric scalar between 0 and 2.";
x = aisdk.LLMToolArgument("x",Description=description,Required=true)
```

```
x =

  aisdk.LLMToolArgument with properties:

           Name: "x"
    Description: "Temperature value for controlling the randomness of the output, specified as ''auto'' or as a numeric scalar between 0 and 2."
       DataType: ""
       Required: 1
      NameValue: 0
```
### Create LLM Tool Argument from Example Argument
<a id="create-llm-tool-argument-from-example-argument"></a>

Create an LLM tool argument from an example argument specified as a structure with
field `x` and value `pi`.

```
x = aisdk.LLMToolArgument(struct(x=pi))
```

```
x =

  aisdk.LLMToolArgument with properties:

           Name: "x"
    Description: ""
       DataType: "number"
       Required: 1
      NameValue: 0
```
## Algorithms
<a id="algorithms"></a>
### Argument Type Detection
<a id="argument-type-detection"></a>

If you provide an example set of input or output arguments by using a structure, then
the software automatically detects the data type of the input arguments. The JSON data type
of the `aisdk.LLMToolArgument` object depends on the field values of the example
structure:

| Input Data Type | JSON Data Type | Example |
| --- | --- | --- |
| real-valued scalar integer | `"integer"` | `struct(x=3)` |
| real-valued scalar | `"number"` | `struct(x=3.14)` |
| logical scalar | `"boolean"` | `struct(tf=true)` |
| string scalar or character vector | `"string"` | `struct(str="hello")`,`struct(str='hi')` |

To use other data types, including non-scalar inputs, complex numbers, and specialized
objects including custom objects, add the data to the agent workspace and configure the tool
to work with the agent workspace. For more information, see [`aisdk.AIAgent`](aisdk.AIAgent.md).
## See Also
<a id="see-also"></a>

[`aisdk.LLMTool`](aisdk.LLMTool.md) | [`aisdk.AIAgent`](aisdk.AIAgent.md) | [`aisdk.LLMClient`](aisdk.LLMClient.md)

*Copyright 2026 The MathWorks, Inc.*

