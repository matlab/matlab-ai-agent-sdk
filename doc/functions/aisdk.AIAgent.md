# aisdk.AIAgent
<a id="aisdkaiagent"></a>

Build AI agent
## Description
<a id="description"></a>

Use an `aisdk.AIAgent` object to build and run AI agents inside
MATLAB&#x00AE;.
## Creation
<a id="creation"></a>
### Description
<a id="description-1"></a>

`agent = aisdk.AIAgent(client)`
creates an `aisdk.AIAgent` object with the specified LLM client
`client`.

`agent = aisdk.AIAgent(client,Name=Value)`
specifies additional options using one or more name-value arguments. For example, to limit
the maximum number of tool calling iterations to 10, set
`MaxIterations` to `10`.
### `client` — LLM client
<a id="client"></a>

`OpenAIClient` | `OllamaClient`

LLM client, specified as an [`OpenAIClient`](OpenAIClient.md) or [`OllamaClient`](OllamaClient.md) object.

Create a client by using the [`aisdk.LLMClient`](aisdk.LLMClient.md) function.

This argument sets the `Client` property.

Data Types: `OpenAIClient` | `OllamaClient`
### Name-Value Arguments
<a id="name-value-arguments"></a>

Specify optional pairs of arguments as
`Name1=Value1,...,NameN=ValueN`, where `Name` is
the argument name and `Value` is the corresponding value.
Name-value arguments must appear after other arguments, but the order of the
pairs does not matter.

Example: `aisdk.AIAgent(client,MaxIterations=10)` limits the maximum number
of iterations to 10.
### 
<a id=""></a>

#### Agent Properties
<a id="agent-properties"></a>

These properties support setting with name-value arguments.

[`SystemPrompt`](#systemprompt) | [`Tools`](#tools) | [`Messages`](#messages) | [`Workspace`](#workspace) | [`DisplayMode`](#displaymode) | [`MaxIterations`](#maxiterations)
## Properties
<a id="properties"></a>
### `Client` — LLM client
<a id="client-1"></a>

`OpenAIClient` object | `OllamaClient` object object

LLM client, specified as an [`OpenAIClient`](OpenAIClient.md) or [`OllamaClient`](OllamaClient.md) object.

Data Types: `OpenAIClient` | `OllamaClient`
### `SystemPrompt` — System prompt
<a id="systemprompt"></a>

`[]` (default) | string scalar

System prompt, specified as a string scalar.

The system prompt is a natural language description that provides the framework in
which a large language model generates its responses. The system prompt can include
instructions about tone, communications style, language, etc.

Data Types: `string`
### `Tools` — LLM tools
<a id="tools"></a>

`[]` (default) | `LocalLLMTool` | `MCPTool` | LLM tool array

LLM tools, specified as one or more [`LocalLLMTool`](LocalLLMTool.md) objects, [`MCPTool`](MCPTool.md) objects, or a combination of both.

Data Types: `LocalLLMTool` | `MCPTool`
### `Messages` — Message history
<a id="messages"></a>

[] (default) | LLM message array

Message history, specified as an array of LLM messages.

LLM message arrays can contain one or more of these objects:

- [`aisdk.LLMTextMessage`](aisdk.LLMTextMessage.md)

- [`aisdk.LLMImageMessage`](aisdk.LLMImageMessage.md)

- [`aisdk.LLMToolCallMessage`](aisdk.LLMToolCallMessage.md)

- [`aisdk.LLMToolResultMessage`](aisdk.LLMToolResultMessage.md)

When you use the [`run`](run.md)
function, the software automatically updates the message history.

You can provide the agent with an initial message history for:

- One-shot prompting.

- Providing a summary of a previous conversation.

- Creating subagents.

Data Types: `aisdk.LLMTextMessage` | `aisdk.LLMImageMessage` | `aisdk.LLMToolCallMessage` | `aisdk.LLMToolResultMessage`
### `Workspace` — Agent workspace
<a id="workspace"></a>

structure

Agent workspace, specified as a structure.

Instead of providing data to an LLM directly, you can store the data in the agent
workspace and configure tools to read and write to parts of the agent workspace. For
example, use this for large amounts of data, or data types that cannot be converted to
JSON data types, such as complex numbers, arrays, or custom classes.

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

For example, configure the underlying function like this:

```
function [out1,...,outM,agentWorkspace] = myFunction(agentWorkspace,in1,...,inN)
...
end
```

Then, create an LLM tool by using the [`aisdk.LLMTool`](aisdk.LLMTool.md)
function.

```
tool = aisdk.LLMTool(@myFunction,Workspace="agent");

```

For an example of how to configure a tool to operate on the agent workspace, see
[`Configure Tool to Use Agent Workspace`](#configure-tool-to-use-agent-workspace).

Example: `struct(x = randn(100),y = dlarray(1:10))`

Data Types: `struct`
### `DisplayMode` — Option for displaying messages in the MATLAB Command Window
<a id="displaymode"></a>

`"detailed"` (default) | `"off"`

Option for displaying messages in the MATLAB Command Window, specified as `"detailed"` or
`"off"`.

When `DisplayMode` is set to `"detailed"`, the
agent prints information about each step of the agentic loop, including tool calls and
responses.

You can also view the chat history of the agent, including tool calls and responses,
by using the `Messages` property.

Data Types: `string`
### `MaxIterations` — Maximum number of agent iterations per run
<a id="maxiterations"></a>

25 (default) | positive integer

Maximum number of agent iterations per run, specified as a positive integer.

Agents can attempt more than one agent iteration during a single execution of the
[`run`](run.md)
function. To avoid getting stuck in the loop, limit the maximum number of agent
iterations.

For example, agents can attempt more than one tool call. If a tool is misconfigured,
then an agent can get stuck trying and failing to call the same tool repeatedly.

For more information on the agentic loop, see [`Algorithms`](#algorithms).

Data Types: `double`
## Object Functions
<a id="object-functions"></a>

| Function | Description |
| --- | --- |
| [`run`](run.md) | Run AI agent |
## Examples
<a id="examples"></a>
### Create Chat With LLM
<a id="create-chat-with-llm"></a>

This example shows how to create a conversation with an LLM and
automatically keep track of the message history by using the [`aisdk.AIAgent`](aisdk.AIAgent.md) function.

Create the agent from an LLM client `client` by using the [`aisdk.AIAgent`](aisdk.AIAgent.md) function. Provide a system prompt.

```
systemPrompt = "Reply as if you are writing telegrams.";
agent = aisdk.AIAgent(client,SystemPrompt=systemPrompt);
```

Run the agent by using the [`run`](run.md)
function. Provide a prompt.

```
prompt = "TOMATO FRUIT OR VEGETABLE STOP";
run(agent,prompt)
```

```
ans =

    "TOMATO TECHNICALLY A FRUIT STOP COMMONLY USED AS VEGETABLE IN CULINARY CONTEXT STOP END OF TRANSMISSION."
```

Ask a follow up question by using the [`run`](run.md)
function again.

```
run(agent,"HOW ABOUT AVOCADO STOP")
```

```
ans =

    "AVOCADO ALSO A FRUIT STOP KNOWN AS ALLIGATOR PEAR STOP HIGH IN HEALTHY FATS AND NUTRIENTS STOP END OF TRANSMISSION."
```

Inspect the chat history by using the `Messages` property of the
agent.

```
agent.Messages
```

```
ans =

  1×4 aisdk.LLMTextMessage array with messages:

    1    User         Text    "TOMATO FRUIT OR VEGETABLE STOP"
    2    Assistant    Text    "TOMATO TECHNICALLY A FRUIT STOP COMMONLY USED AS VEGETABLE I..."
    3    User         Text    "HOW ABOUT AVOCADO STOP"
    4    Assistant    Text    "AVOCADO ALSO A FRUIT STOP KNOWN AS ALLIGATOR PEAR STOP HIGH ..."
```
### Call Tool Using AI Agent
<a id="call-tool-using-ai-agent"></a>

This example shows how to create an AI agent with a set of tools by
using the [`aisdk.AIAgent`](aisdk.AIAgent.md) function.

Create a tool from the `count` function by using the [`aisdk.LLMTool`](aisdk.LLMTool.md) function. The `count` function counts the
occurrences of patterns in strings. Add information about input and output arguments to
the tool by using the [`aisdk.LLMToolArgument`](aisdk.LLMToolArgument.md)
function.

```
tool = aisdk.LLMTool(@count);
tool.InputArguments(1) = aisdk.LLMToolArgument("word",DataType="string");
tool.InputArguments(2) = aisdk.LLMToolArgument("letter",DataType="string");
tool.OutputArguments = aisdk.LLMToolArgument("numLetter",DataType="number");
```

Create the agent from an LLM client `client` by using the
[`aisdk.AIAgent`](aisdk.AIAgent.md) function.

```
agent = aisdk.AIAgent(client,Tools=tool);
```

Run the agent by using the [`run`](run.md)
function.

```
run(agent,"How many times is the letter r in the word strawberry?")
```

```
[think]
[call function count with inputs {"word":"strawberry","letter":"r"}]
[function return] {"numLetter":3}
[think]
The letter "r" appears 3 times in the word "strawberry."
ans = "The letter "r" appears 3 times in the word "strawberry.""
```

To see whether the agent called a tool, inspect the chat history by using the
`Messages` property of the agent.

```
agent.Messages
```

```
ans =
  1×4 LLMMessage array with messages:

    1    User         Text         "How many times is the letter r in the word strawberry?"
    2    Assistant    Tool Call    countLetters({"word":"strawberry","letter":"r"})
    3    Tool         Text         "{"numLetter":3}"
    4    Assistant    Text         "The letter "r" appears 3 times in the word "strawberry."
```
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
## Algorithms
<a id="algorithms"></a>

An AI agent combines an LLM with a set of software tools. During each run of the
agent:

- User provides a prompt.

- Model decides whether to call one or more tools.

- If yes, then:

  - Model calls one or more tools. This step is called a tool calling
iteration.
  - Model decides whether to call additional tools.
  - Model provides answer.

The user can then provide a follow-up prompt by using the `run`
function and the software repeats the same steps to generate a new answer.
## References
<a id="references"></a>

[1] Yao, S., J. Zhao, D. Yu, N. Du, I. Shafran, K. Narasimhan, and Y. Cao. "ReAct: Synergizing
Reasoning and Acting in Language Models" Preprint, submitted Mar 10, 2023. https://doi.org/10.48550/arXiv.2210.03629.
## See Also
<a id="see-also"></a>

[`aisdk.LLMClient`](aisdk.LLMClient.md) | [`aisdk.LLMTool`](aisdk.LLMTool.md) | [`LocalLLMTool`](LocalLLMTool.md) | [`MCPTool`](MCPTool.md) | [`aisdk.LLMToolArgument`](aisdk.LLMToolArgument.md) | [`OpenAIClient`](OpenAIClient.md) | [`OllamaClient`](OllamaClient.md)

*Copyright 2026 The MathWorks, Inc.*

