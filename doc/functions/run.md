# run
<a id="run"></a>

Run AI agent
## Syntax
<a id="syntax"></a>

`response = run(agent,prompt)`

`response = run(agent,prompt,Name=Value)`
## Description
<a id="description"></a>

`response = run(agent,prompt)`
runs the AI agent `agent` with the prompt `prompt` and
returns the generated text response.

`response = run(agent,prompt,Name=Value)`
specifies additional options using one or more name-value arguments. For example, to limit
the maximum number of agent iterations to 10, set [`MaxIterations`](#maxiterations) to
`10`.
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
## Input Arguments
<a id="input-arguments"></a>
### `agent` — AI agent
<a id="agent"></a>

`aisdk.AIAgent` object

AI agent, specified as an [`aisdk.AIAgent`](aisdk.AIAgent.md) object.
### `prompt` — Prompt
<a id="prompt"></a>

string scalar | character vector | `aisdk.LLMTextMessage` | `aisdk.LLMImageMessage` | `aisdk.LLMToolCallMessage` | `aisdk.LLMToolResultMessage` | LLM message array

Prompt, specified as a string scalar, character vector, or an array of messages
containing one or more of these message objects:

- [`aisdk.LLMTextMessage`](aisdk.LLMTextMessage.md)

- [`aisdk.LLMImageMessage`](aisdk.LLMImageMessage.md)

- [`aisdk.LLMToolCallMessage`](aisdk.LLMToolCallMessage.md)

- [`aisdk.LLMToolResultMessage`](aisdk.LLMToolResultMessage.md)

Data Types: `char` | `string` | `aisdk.LLMTextMessage` | `aisdk.LLMImageMessage` | `aisdk.LLMToolCallMessage` | `aisdk.LLMToolResultMessage`
## Name-Value Arguments
<a id="name-value-arguments"></a>

Specify optional pairs of arguments as
`Name1=Value1,...,NameN=ValueN`, where `Name` is
the argument name and `Value` is the corresponding value.
Name-value arguments must appear after other arguments, but the order of the
pairs does not matter.

Example: `run(agent,query,MaxIterations=10)` limits the maximum number
of agent iterations to 10.
### `Tools` — LLM tools
<a id="tools"></a>

`LocalLLMTool` | `MCPTool` | LLM tool array

LLM tools, specified as an array of [`LocalLLMTool`](LocalLLMTool.md) objects, [`MCPTool`](MCPTool.md) objects, or a combination of both.

By default, the [`run`](run.md) function uses the tools specified by the `Tools`
property of the AI agent [`agent`](#agent).

Data Types: `LocalLLMTool` | `MCPTool`
### `ToolChoice` — Tool choice
<a id="toolchoice"></a>

`"auto"` (default) | `"none"` | `"required"` | tool name

Tool choice, specified as a string scalar.

- `"auto"` — Model decides whether to call a tool.

- `"none"` — Disable tool calling.

- `"required"` — Model must call at least one tool.

- tool name — When you specify a tool name, the model must call that
tool.

Data Types: `string` | `char`
### `MaxIterations` — Maximum number of agent iterations
<a id="maxiterations"></a>

positive integer

Maximum number of agent iterations, specified as a positive integer.

By default, the function uses the `MaxIterations` property of
the AI agent [`agent`](#agent).

Agents can attempt more than one action during a single execution of the [`run`](run.md) function. To avoid getting stuck in the loop, limit the maximum
number of agent iterations.

For example, agents can attempt more than one tool calling iteration. If a tool is
misconfigured, then an agent can get stuck trying to call the same tool
repeatedly.

The number of tool call iterations is not equal to the number of tool calls. Each
tool call iteration can contain multiple tool calls. For example, if the agent decides
to call three tools, then based on the outputs of those tools, calls another tool,
then that workflow contains two tool calling iterations and four tool calls.

Data Types: `single` | `double` | `int8` | `int16` | `int32` | `int64` | `uint8` | `uint16` | `uint32` | `uint64`
## Output Arguments
<a id="output-arguments"></a>
### `response` — Generated response
<a id="response"></a>

string scalar

Generated response, returned as a string scalar.

The response contains the text generated by the LLM.

To view the entire message history, use the `Messages` property
of the agent.

Data Types: `string`
## See Also
<a id="see-also"></a>

[`aisdk.AIAgent`](aisdk.AIAgent.md)

*Copyright 2026 The MathWorks, Inc.*

