# aisdk.LLMTool
<a id="aisdkllmtool"></a>

Tool for AI agent
## Syntax
<a id="syntax"></a>

`tool = aisdk.LLMTool(f)`

`tool = aisdk.LLMTool(f,name)`

`tool = aisdk.LLMTool(___,Name=Value)`

`tool = aisdk.LLMTool(client)`
## Description
<a id="description"></a>

`tool = aisdk.LLMTool(f)` creates
a [`LocalLLMTool`](LocalLLMTool.md) object from the function handle `f`. The
software automatically tries to extract the name, description, and input and output argument
information from the function.

`tool = aisdk.LLMTool(f,name)`
also specifies the function name `name`. When `f` is
an anonymous function, you must specify the name.

`tool = aisdk.LLMTool(___,Name=Value)`
specifies additional options using one or more name-value arguments. For example, to allow
an agent to execute the tool without needing human approval, set
[`ApprovalRequest`](#approvalrequest) to `"never"`.

`tool = aisdk.LLMTool(client)`
creates an [`MCPTool`](MCPTool.md)
object or an array of [`MCPTool`](MCPTool.md)
objects from the tools provided by an MCP server by using the MCP client
`client`.
## Examples
<a id="examples"></a>
### Create Tool From Built-In Function
<a id="create-tool-from-built-in-function"></a>

To create an AI tool from a built-in MATLAB&#x00AE; function, use the [`aisdk.LLMTool`](aisdk.LLMTool.md) function with the function handle of the built-in function as
input.

```
tool = aisdk.LLMTool(@splitTextChunks)
```

```
tool =

  LocalLLMTool with properties:

                Name: "splitTextChunks"
         Description: "Split documents recursively into text chunks"
      InputArguments: [1×3 aisdk.LLMToolArgument]
     OutputArguments: [1×1 aisdk.LLMToolArgument]
           Workspace: "none"
     ApprovalRequest: never
        DisplayTitle: "splitTextChunks"
         Annotations: [1×1 struct]
```

The software automatically extracts information about the arguments, function name,
and function description.

If the arguments contains `varargin` or
`varargout`, then specify a syntax by specifying the
`InputArguments` or `OutputArguments`
name-value arguments, respectively.
### Create Tool From Custom Function
<a id="create-tool-from-custom-function"></a>

To create an AI tool from a custom function, use the [`aisdk.LLMTool`](aisdk.LLMTool.md) function with the function handle of the custom function as
input.

First, create a custom function called `myFunction` and save it
to a file called `myFunction.m`. To enable the [`aisdk.LLMTool`](aisdk.LLMTool.md) function to automatically extract information about the
function description, add a comment at the top of the function file that contains
the definition. To enable the [`aisdk.LLMTool`](aisdk.LLMTool.md) function to automatically extract information about the
input arguments, use an `arguments` block. For more information
about `arguments` blocks, see [`arguments Block Syntax`](https://www.mathworks.com/help/matlab/matlab_prog/function-argument-validation-1.html#mw_7d29b198-98bc-4268-93a2-d74504d2b023).

```
function out = myFunction(x,y,nvp)
%Add two numbers with a twist
    arguments
        x double
        y double
        nvp.AlwaysReturn42(1,1) logical = true
    end

    if nvp.AlwaysReturn42
        out = 42;
    else
        out = x + y;
    end
end
```

Create an AI tool from the `myFunction` function by using the
[`aisdk.LLMTool`](aisdk.LLMTool.md) function.

```
tool = aisdk.LLMTool(@myFunction)
```

```
tool =

  LocalLLMTool with properties:

     InputArguments: [1×3 aisdk.LLMToolArgument]
    OutputArguments: [1×1 aisdk.LLMToolArgument]
    ApprovalRequest: "never"
               Name: "myFunction"
       DisplayTitle: "myFunction"
        Description: "Add two numbers with a twist"
        Annotations: [1×1 struct]
```
### Create Tool From MCP Server
<a id="create-tool-from-mcp-server"></a>

To create one or more AI tools from the tools provided by an MCP
server, first connect to the MCP server by using the [`mcpHTTPClient`](https://www.mathworks.com/matlabcentral/fileexchange/182699-matlab-mcp-http-client)
function. Then, use the client as the input to the [`aisdk.LLMTool`](aisdk.LLMTool.md) function.

Connect to an MCP server with server endpoint `endpoint` by using
the [`mcpHTTPClient`](https://www.mathworks.com/matlabcentral/fileexchange/182699-matlab-mcp-http-client) function.

```
client = mcpHTTPClient(endpoint);
```

Create an AI tool from the MCP server by using the [`aisdk.LLMTool`](aisdk.LLMTool.md) function.

```
tool = aisdk.LLMTool(client);
```

If the MCP server provides more than one tool, then `tool` is an
array of `MCPTool` objects.
### Configure Tool to Use Agent Workspace
<a id="configure-tool-to-use-agent-workspace"></a>

This example shows how to configure an LLM tool to use data from the
agent workspace as input or output data.

The `eig` function calculates the eigenvectors and eigenvalues of
matrices. Vectors and matrices can contain a lot of numerical data. Instead of sending all
this data to an LLM, which would cost tokens, keep the data in the agent workspace and
configure your tools to work on that workspace.

Create a function called `eigTool`.

- The first input argument of the function must be a structure array
representing the input agent workspace. Call the argument
`agentWorkspace`.

- The last output argument of the function must be a structure array
representing the updated agent workspace after the tool call.

- To allow the agent to understand the outcome of the tool call, add another
output argument, `observation`, that contains a natural
language description of the outcome of the tool call.

```
function [observation,agentWorkspace] = eigTool(agentWorkspace)
% Compute the eigenvalues of a matrix
agentWorkspace.eigenvalues = eig(agentWorkspace.matrix);
observation = "Eigenvalues were computed and added to the agent workspace.";
end

```

Create an LLM tool from the `eigTool` function by using the
[`aisdk.LLMTool`](aisdk.LLMTool.md) function. Set the `Workspace` name-value
argument to `"agent"`.

```
tool = aisdk.LLMTool(@eigTool,Workspace="agent");
```

Create an agent from an LLM client `client` and system prompt
`systemPrompt`. Set the `Tools` name-value
argument to `tool`.

```
agent = aisdk.AIAgent(client,SystemPrompt=systemPrompt,Tools=tool);
```

The `eigTool` functions expects the agent workspace to have a
variable called `matrix`. To allow an agent to use the tool
`tool`, add the matrix to the agent workspace.

```
agent.Workspace.matrix = randn(10);
```
## Input Arguments
<a id="input-arguments"></a>
### `f` — Function
<a id="f"></a>

function handle

Function, specified as a function handle.

Example: `@myFunction`

Data Types: `function_handle`
### `name` — Tool name
<a id="name"></a>

string scalar | character vector

Tool name, specified as a string scalar or character vector.

By default, the tool name is the name of the function specified by
[`f`](#f).

If `f` is an anonymous function, then you must specify
`name`.

Data Types: `char` | `string`
### `client` — MCP client
<a id="client"></a>

[`mcpHTTPClient`](https://www.mathworks.com/matlabcentral/fileexchange/182699-matlab-mcp-http-client) object

MCP client, specified as an [`mcpHTTPClient`](https://www.mathworks.com/matlabcentral/fileexchange/182699-matlab-mcp-http-client) object.

Data Types: [`mcpHTTPClient`](https://www.mathworks.com/matlabcentral/fileexchange/182699-matlab-mcp-http-client)
## Name-Value Arguments
<a id="name-value-arguments"></a>

Specify optional pairs of arguments as
`Name1=Value1,...,NameN=ValueN`, where `Name` is
the argument name and `Value` is the corresponding value.
Name-value arguments must appear after other arguments, but the order of the
pairs does not matter.

Example: `aisdk.LLMTool(f,ApprovalRequest="never")` allows an agent to execute
the tool without needing human approval.
### `Description` — Tool description
<a id="description-1"></a>

string scalar | character vector

Tool description, specified as a string scalar or character vector.

By default, the software tries to use the text contained in the comment directly
after the function definition line:

```
function myFunction(x)
% This is the default function description
...
end
```

Provide details about the tool meaning and usage to the model to improve the
quality of the generated output.

Data Types: `char` | `string`
### `DisplayTitle` — Display title
<a id="displaytitle"></a>

string scalar | character vector

Display title, specified as a string scalar or character vector.

The agent does not see the display title. Use the display title to create
human-readable displays, and for postprocessing and analysis.

Example: `"Sine Function"`

Data Types: `char` | `string`
### `InputArguments` — Input arguments
<a id="inputarguments"></a>

`aisdk.LLMToolArgument` array | structure array

Input arguments, specified as an `aisdk.LLMToolArgument` array or a
structure array.

Specify the input arguments in one of two ways:

- Use an `aisdk.LLMToolArgument` object.

- Provide an example set of input arguments by using a structure array. For
example, if your function has two inputs, a numerical scalar
`x` and a string scalar `str`, then you can
specify `InputArguments` as
`struct(x=3.14,str="test")`.

If your function contains an argument block, then by default, the software uses
that information to derive the input arguments. If the arguments contains
`varargin`, then specify a syntax by specifying the
`InputArguments` name-value argument.

Data Types: `aisdk.LLMToolArgument` | `struct`
### `OutputArguments` — Output arguments
<a id="outputarguments"></a>

`aisdk.LLMToolArgument` array | structure array

Output arguments, specified as an `aisdk.LLMToolArgument` array or a
structure array.

Specify the output arguments in one of two ways:

- Use an `aisdk.LLMToolArgument` object.

- Provide an example set of output argument by using a structure array. For
example, if your function has two outputs, a numerical scalar
`x` and a string scalar `str`, then you can
specify `OutputArguments` as
`struct(x=3.14,str="test")`.T

By default, the software tries to extract information about the output arguments
from the function definition. If the arguments contains `varargout`,
then specify a syntax by specifying the `OutputArguments`
name-value argument.

Data Types: `aisdk.LLMToolArgument` | `struct`
### `Annotations` — Tool annotations
<a id="annotations"></a>

structure

Tool annotations, specified as a structure.

Specify tool annotations to configure the tool behavior within a custom or external
application or API.

For example, display a warning message to the end user when the agent calls a tool that
is able to overwrite or delete data. First, add an annotation to the tool:
`tool.Annotations.destructiveHint = true`. Then, in your application,
check if the `Annotations` property of a called tool has a field
`destructiveHint` with value `false`. If it does not,
then display a warning.

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
### `Workspace` — Tool workspace
<a id="workspace"></a>

`"none"` (default) | `"agent"`

Tool workspace, specified as `"none"` or
`"agent"`.

Specifying data in the agent workspace lets tools work on data that the software
does not send to the LLM. For example:

- Large amounts of data.

- Data types that cannot be converted to JSON data types, such as complex
numbers, arrays, or specialized objects, including custom objects.

To configure a tool to operate on the agent workspace, set the
`Workspace` property of the tool to `"agent"`. The
underlying function must be configured as follows:

- The first input argument must be a structure representing the input agent
workspace.

- The last output argument must be a structure representing the updated agent workspace
after tool execution.

- Do not add either of the workspace arguments to the tool as an
`aisdk.LLMToolArgument` object.

- The agent does not directly interact with the agent workspace. To let the agent
generate a response or decide on next steps, add one or more additional output
arguments. For example:

  - Add an output argument that describes the outcome of the tool call to the
agent in natural language.
  - Add an output argument that contains the parts of the result that are
relevant to the agent. For example, if you have a tool that calculates the
eigenvalues of a large matrix in the workspace, then you can return the top
three largest eigenvalues as a separate output argument.

Ensure that any workspace field names that the underlying function uses are
defined in the `Workspace` property of the agent before the agent calls the
tool.

For more information, see [`Configure Tool to Use Agent Workspace`](#configure-tool-to-use-agent-workspace).

Data Types: `string` | `char`
## Output Arguments
<a id="output-arguments"></a>
### `tool` — LLM tool
<a id="tool"></a>

`LocalLLMTool` | `MCPTool`

LLM tool, returned as a [`LocalLLMTool`](LocalLLMTool.md) object, an [`MCPTool`](MCPTool.md) object, or as an array of tools.
## Algorithms
<a id="algorithms"></a>
### Argument Type Detection
<a id="argument-type-detection"></a>

If you provide an example set of input or output arguments by using a structure, then
the software converts the example structures into `aisdk.LLMToolArgument` objects.
The JSON data type of the `aisdk.LLMToolArgument` object depends on the field
values of the example structure:

| Input Data Type | JSON Data Type | Example |
| --- | --- | --- |
| real-valued scalar integer | `"integer"` | `struct(x=3)` |
| real-valued scalar | `"number"` | `struct(x=3.14)` |
| logical scalar | `"boolean"` | `struct(tf=true)` |
| string scalar or character vector | `"string"` | `struct(str="hello")`,`struct(str='hi')` |

To use other data types, including non-scalar inputs, complex numbers, and specialized
objects including custom objects, add the data to the agent workspace and configure the tool
to work with the agent workspace. For more information, see [`Configure Tool to Use Agent Workspace`](#configure-tool-to-use-agent-workspace).
## See Also
<a id="see-also"></a>

[`aisdk.AIAgent`](aisdk.AIAgent.md) | [`aisdk.LLMClient`](aisdk.LLMClient.md) | [`LocalLLMTool`](LocalLLMTool.md) | [`MCPTool`](MCPTool.md) | [`selectTool`](selectTool.md) | `evaluate`

*Copyright 2026 The MathWorks, Inc.*

