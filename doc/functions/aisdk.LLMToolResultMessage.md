# aisdk.LLMToolResultMessage
<a id="aisdkllmtoolresultmessage"></a>

Tool result message in LLM message history
## Description
<a id="description"></a>

A tool result message in the message history of a large language model (LLM)
stores information related to a tool result in response to a tool call message.

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

`message = aisdk.LLMToolResultMessage(result)`
creates a tool result message from the result `result`.

`message = aisdk.LLMToolResultMessage(result,Name=Value)`
specifies additional options using one or more name-value arguments. For example, to
specify the tool name as `"myTool"`, set `Name` to
`"myTool"`.
### `result` — Tool result
<a id="result"></a>

string scalar

Tool result, specified as a string scalar.

This argument sets the `Result` property.

Example: `"{\"numLetter\":3}"`

Data Types: `string`
### Name-Value Arguments
<a id="name-value-arguments"></a>

Specify optional pairs of arguments as
`Name1=Value1,...,NameN=ValueN`, where `Name` is
the argument name and `Value` is the corresponding value.
Name-value arguments must appear after other arguments, but the order of the
pairs does not matter.

#### Message Properties
<a id="message-properties"></a>

These properties can be set using name-value arguments.

[`Name`](#name) | [`ToolCallID`](#toolcallid)
## Properties
<a id="properties"></a>
### `Role` — Message sender
<a id="role"></a>

Read-only: `"tool"`

This property is read-only.

Message sender, specified as `"tool"`.

Data Types: `string`
### `Type` — Message type
<a id="type"></a>

Read-only: `"text"`

This property is read-only.

Message type, specified as `"text"`.

Data Types: `string`
### `Result` — Tool result
<a id="result-1"></a>

string scalar

Tool result, specified as a string scalar.

Data Types: `string`
### `Name` — Tool name
<a id="name"></a>

string scalar

Tool name, specified as a string scalar that contains the name of the tool that
returned the result.

Data Types: `string`
### `ToolCallID` — Tool call ID
<a id="toolcallid"></a>

`""` (default) | string scalar

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
### Determine Whether Agent Called Tool
<a id="determine-whether-agent-called-tool"></a>

This example shows how to determine whether an AI agent called a
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

[`aisdk.LLMToolCallMessage`](aisdk.LLMToolCallMessage.md) | [`aisdk.LLMTextMessage`](aisdk.LLMTextMessage.md) | [`aisdk.LLMImageMessage`](aisdk.LLMImageMessage.md) | [`generate`](generate.md) | [`aisdk.AIAgent`](aisdk.AIAgent.md)

*Copyright 2026 The MathWorks, Inc.*

