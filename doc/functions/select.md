# select
<a id="select"></a>

Select LLM tool from tool array
## Syntax
<a id="syntax"></a>

`tool = select(tools,name)`
## Description
<a id="description"></a>

`tool = select(tools,name)`
selects the tool with name `name` from the array of LLM tools
`tools`.
## Examples
<a id="examples"></a>
### Select Tool From Tool Array
<a id="select-tool-from-tool-array"></a>

This example shows how to select an LLM tool from an array of tools
by using the name of the tool.

Create a tool array containing two functions, `extractFileText`
and `splitTextChunks`.

```
toolArray = [aisdk.LLMTool(@extractFileText),aisdk.LLMTool(@splitTextChunks)];
```

Select the tool corresponding to `splitTextChunks` from the tool
array by using the `select` function.

```
tool = select(toolArray,"splitTextChunks");
```

```
tool =

  LocalLLMTool with properties:

     InputArguments: [1×3 aisdk.LLMToolArgument]
    OutputArguments: [1×1 aisdk.LLMToolArgument]
    ApprovalRequest: Never
               Name: "splitTextChunks"
       DisplayTitle: "splitTextChunks"
        Description: "Split documents recursively into text chunks"
        Annotations: [1×1 struct]
```
## Input Arguments
<a id="input-arguments"></a>
### `tools` — LLM tools
<a id="tools"></a>

`LocalLLMTool` | `MCPTool` | LLM tool vector

LLM tools, specified as a vector of [`LocalLLMTool`](LocalLLMTool.md) objects, [`MCPTool`](MCPTool.md) objects, or a combination of both.

Data Types: `LocalLLMTool` | `MCPTool`
### `name` — Tool name
<a id="name"></a>

string scalar | character vector

Tool name, specified as a string scalar or character vector.

The value of `name` must match the `Name`
property of a tool in the array [`tools`](#tools).

Data Types: `string` | `char`
## Output Arguments
<a id="output-arguments"></a>
### `tool` — Selected tool
<a id="tool"></a>

`LocalLLMTool` | `MCPTool`

Selected tool, returned as a [`LocalLLMTool`](LocalLLMTool.md) object or an [`MCPTool`](MCPTool.md) object.
## See Also
<a id="see-also"></a>

[`aisdk.LLMTool`](aisdk.LLMTool.md) | [`LocalLLMTool`](LocalLLMTool.md) | [`MCPTool`](MCPTool.md) | [`aisdk.AIAgent`](aisdk.AIAgent.md) | [`evaluate`](evaluate.md)

*Copyright 2026 The MathWorks, Inc.*

