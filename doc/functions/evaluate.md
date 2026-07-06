# evaluate
<a id="evaluate"></a>

Evaluate LLM tool
## Syntax
<a id="syntax"></a>

`output = evaluate(tool,inputArguments)`

`[output,newData] = evaluate(tool,inputArguments,data)`
## Description
<a id="description"></a>

Use the `evaluate` function to evaluate LLM tools manually. For
example, do this to test and debug, or to create a custom agent architecture. When you create
an AI agent by using the [`aisdk.AIAgent`](aisdk.AIAgent.md) function, the
software evaluates the tools automatically.

`output = evaluate(tool,inputArguments)`
evaluates the tool `tool` with the input arguments
`inputArguments`.

`[output,newData] = evaluate(tool,inputArguments,data)`
also uses the data `data`. The LLM does not directly interact with
`data`. For example, use this for large amounts of data, or data types
that cannot be converted to JSON data types, such as complex numbers, arrays, or custom
classes.
## Examples
<a id="examples"></a>
### Evaluate Local LLM Tool
<a id="evaluate-local-llm-tool"></a>

This example shows how to manually evaluate a local LLM tool by using
the `evaluate` function.

For example, evaluate tools to debug, or when creating a custom agent architecture.
When you add tools to an [`aisdk.AIAgent`](aisdk.AIAgent.md) object instead,
then the agent calls and evaluates tools automatically.

Create a tool from the `sin` function. Provide an example set of
input arguments by using a structure array. The `sin` function takes
a single, numeric input argument. Call the argument `x`.

```
tool = aisdk.LLMTool(@sin,InputArguments=struct(x=pi));
```

Evaluate the tool.

```
output = evaluate(tool,struct(x=0))
```

```
output =

     0
```
## Input Arguments
<a id="input-arguments"></a>
### `tool` — LLM tool
<a id="tool"></a>

`LocalLLMTool` object | `MCPTool` object

LLM tool, specified as a [`LocalLLMTool`](LocalLLMTool.md) object or an [`MCPTool`](MCPTool.md)
object.

Data Types: `LocalLLMTool` | `MCPTool`
### `inputArguments` — Tool input arguments
<a id="inputarguments"></a>

structure

Tool input arguments, specified as a structure.

The field names of the structure must correspond to the names of the input arguments
defined in the `InputArguments` property of the tool.

Example: `struct(x=42)`

Data Types: `struct`
### `data` — Additional input data
<a id="data"></a>

structure

Additional input data, specified as a structure.

Instead of providing data to an LLM directly, you can store the data in a structure
in the workspace and configure tools to read and write to the structure. For example,
use this for large amounts of data, or data types that cannot be converted to JSON data
types, such as complex numbers, arrays, or custom classes.

To configure a tool to operate on the input data:

- The first input argument must be a structure representing the data.

- The last output argument must be the same structure.

- Do not add either of the workspace arguments to the tool as an
`aisdk.LLMToolArgument` object.
## Output Arguments
<a id="output-arguments"></a>
### `output` — Output from evaluated tool
<a id="output"></a>

any MATLAB&#x00AE; data type

Output from evaluated tool, returned as any MATLAB data type.

To provide the output from an evaluated tool to an LLM, the output data type has to
be convertible to a JSON data type:

| Input Data Type | JSON Data Type | Example |
| --- | --- | --- |
| real-valued integer | `"integer"` | `struct(x=3)` |
| real-valued number | `"number"` | `struct(x=3.14)` |
| logical | `"boolean"` | `struct(tf=true)` |
| string or character | `"string"` | `struct(str="hello")`,`struct(str='hi')` |

To use other data types, for example complex numbers or specialized objects
including custom objects, return the data as part of the [`newData`](#newdata)
output argument for subsequent analysis.

To let an LLM analyze data that cannot be converted to JSON data types, for example:

- Return an observation string that explains the result of the tool evaluation
in natural language, for example, `"Tool myTool created a 500-by-1000
complex-valued matrix."`.

- Analyze the data as part of the tool evaluation and return the result of the
analysis. For example, if a tool computes the eigenvalues of a large matrix, but
the subsequent analysis only requires the three largest eigenvalues, then return
the three largest eigenvalues as separate real-valued scalar output arguments and
provide those to the LLM.
### `newData` — Updated data
<a id="newdata"></a>

structure

Updated data, returned as a structure.
## See Also
<a id="see-also"></a>

[`aisdk.LLMTool`](aisdk.LLMTool.md) | [`LocalLLMTool`](LocalLLMTool.md) | [`aisdk.LLMClient`](aisdk.LLMClient.md)

*Copyright 2026 The MathWorks, Inc.*

