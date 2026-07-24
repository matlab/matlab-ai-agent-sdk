# aisdk.LLMToolCallMessage
<a id="aisdkllmtoolcallmessage"></a>

Tool call message in LLM message history
## Description
<a id="description"></a>

A tool call message in the message history of a large language model (LLM) stores
information related to a tool call.

To generate output based on a tool call, the tool call message must be followed by a
corresponding tool result message.

View the message history to understand the reasoning and actions that an agent
performs.

The message history can contain these message types:

- [`aisdk.LLMTextMessage`](aisdk.LLMTextMessage.md)

- [`aisdk.LLMImageMessage`](aisdk.LLMImageMessage.md)

- [`aisdk.LLMToolCallMessage`](aisdk.LLMToolCallMessage.md)

- [`aisdk.LLMToolResultMessage`](aisdk.LLMToolResultMessage.md)
## Creation
<a id="creation"></a>
### Description
<a id="description-1"></a>

When you create an AI agent by using the [`aisdk.AIAgent`](aisdk.AIAgent.md) function, the
software automatically creates LLM messages and stores them in the
`Messages` property of the agent.

`message = aisdk.LLMToolCallMessage(name)`
creates a tool call message for the tool with the name `name`.

`message = aisdk.LLMToolCallMessage(name,arguments)`
also specifies the input arguments `arguments`.

`message = aisdk.LLMToolCallMessage(___,ToolCallID=id)`
also specifies the tool call ID `id`.
### `name` — Tool name
<a id="name"></a>

string scalar

Tool name, specified as a string scalar.

This argument sets the `Name` property.

Data Types: `string`
### `arguments` — Tool call input arguments
<a id="arguments"></a>

structure

Tool call input arguments, specified as a structure.

To evaluate the tool call, the field names of the structure must correspond to the
names of the input arguments defined in the `InputArguments`
property of the tool.

This argument sets the `Arguments` property.

Example: `struct(x=3.14)`

Data Types: `struct`
### `id` — Tool call ID
<a id="id"></a>

`""` (default) | string scalar

Tool call ID, specified as a string scalar.

Use tool call IDs to associate tool call message with tool result messages.

This argument sets the `ToolCallID` property.

Data Types: `string`
## Properties
<a id="properties"></a>
### `Role` — Message sender
<a id="role"></a>

Read-only: `"assistant"`

This property is read-only.

Message sender, specified as `"assistant"`.

Data Types: `string`
### `Type` — Message type
<a id="type"></a>

Read-only: `"tool-call"`

This property is read-only.

Message type, specified as `"tool-call"`.

Data Types: `string`
### `Name` — Tool name
<a id="name-1"></a>

string scalar

Tool name, specified as a string scalar.

Data Types: `string`
### `Arguments` — Tool call arguments
<a id="arguments-1"></a>

scalar structure

Tool call arguments, specified as a structure.

To evaluate the tool call, the field names of the structure must correspond to the
names of the input arguments defined in the `InputArguments` property
of the tool.

Example: `struct(x=3.14)`

Data Types: `struct`
### `ToolCallID` — Tool call ID
<a id="toolcallid"></a>

`""` | string scalar

Tool call ID, specified as a string scalar.

Use tool call IDs to associate tool call message with tool result messages.

Data Types: `string`
## Examples
<a id="examples"></a>
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
### Check Whether Agent Called Tool
<a id="check-whether-agent-called-tool"></a>

This example shows how to check whether an AI agent called a
tool.

Check whether the `Type` property of any of the messages in the
message history of the `aisdk.AIAgent` object `agent` is equal
to `"tool-call"`.

```
isToolCall = [agent.Messages.Type] == "tool-call";
```

Display the tool call messages.

```
agent.Messages(isToolCall)
```

```
ans =

  aisdk.LLMToolCallMessage with properties:

          Role: "assistant"
          Type: "tool-call"
          Name: "myTool"
     Arguments: '{"x":42}'
    ToolCallID: "abc"
```
## See Also
<a id="see-also"></a>

[`generate`](generate.md) | [`aisdk.LLMTextMessage`](aisdk.LLMTextMessage.md) | [`aisdk.LLMImageMessage`](aisdk.LLMImageMessage.md) | [`aisdk.LLMToolResultMessage`](aisdk.LLMToolResultMessage.md) | [`aisdk.AIAgent`](aisdk.AIAgent.md)

*Copyright 2026 The MathWorks, Inc.*

