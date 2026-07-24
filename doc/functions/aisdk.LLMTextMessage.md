# aisdk.LLMTextMessage
<a id="aisdkllmtextmessage"></a>

Text message in LLM message history
## Description
<a id="description"></a>

A text message in the message history of a large language model (LLM) stores
text-only content.

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

`message = aisdk.LLMTextMessage(text)`
creates an `aisdk.LLMTextMessage` objects with message text
`text`.

`message = aisdk.LLMTextMessage(text,Role=role)`
specifies the role of the message sender, such as `"user"` or
`"assistant"`.
### `text` — Message text
<a id="text"></a>

string scalar | character vector

Message text, specified as a string scalar or character vector.

This argument sets the `Text` property.

Example: `"Calculate the sine of pi"`

Data Types: `string` | `char`
### `role` — Message sender
<a id="role"></a>


`"user"`
(default) | 
`"system"`
| 
`"assistant"`


Message sender, specified as `"user"`,
`"system"`, or `"assistant"`.

- `"user"` — Human end user.

- `"system"` — Agent developer. For example, you can express
system prompts as text messages with `Role` specified as
`"system"`.

- `"assistant"` — LLM or AI agent.

This argument sets the `Role` property.

Data Types: `string` | `char`
## Properties
<a id="properties"></a>
### `Text` — Message text
<a id="text-1"></a>

string scalar

Message text, specified as a string scalar.

Data Types: `string`
### `Role` — Message sender
<a id="role-1"></a>

Read-only: `"user"` | `"system"` | `"assistant"`

This property is read-only.

Message sender, specified as `"user"`, `"system"`,
or `"assistant"`.

- `"user"` — Human end user.

- `"system"` — Agent developer. For example, you can express
system prompts as text messages with `Role` specified as
`"system"`.

- `"assistant"` — LLM or AI agent.

Data Types: `string`
### `Type` — Message type
<a id="type"></a>

Read-only: `"text"`

This property is read-only.

Message type, specified as `"text"`.

Data Types: `string`
## Examples
<a id="examples"></a>
### Inspect Agent Message History
<a id="inspect-agent-message-history"></a>

When you create an agent by using the [`aisdk.AIAgent`](aisdk.AIAgent.md) function, the
software keeps track of the message history automatically.

Inspect the chat history of an AI agent `agent` by using the
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

In this example, the message history contains two text messages, the first user
message containing the question, and the last assistant message containing the final
answer.
### Manually Track Message History
<a id="manually-track-message-history"></a>

To track the message history during a conversation with an LLM, store
the messages as an `LLMMessage` array and pass that message array to the
[`generate`](generate.md) function.

When you create an AI agent by using the [`aisdk.AIAgent`](aisdk.AIAgent.md) function, the
software tracks the message history automatically.

Create the initial prompt and convert it to an `aisdk.LLMTextMessage`
object. Create an `LLMMessage` array.

```
messageHistory = aisdk.LLMTextMessage("This is the initial prompt.");
```

Generate a response to the prompt by using the [`generate`](generate.md) function and add the second output argument to the message
history array.

```
[~,message2] = generate(client,messageHistory);
messageHistory = [messageHistory; message2];
```

Ask a follow-up question, add it to the message history, and generate a response by
using the [`generate`](generate.md) function. Add the response to the message history.

```
messageHistory(end+1) = aisdk.LLMTextMessage("This is a follow-up question.");

[~,message4] = generate(client,messageHistory);
messageHistory = [messageHistory; message4];
```
### Create Message History for Few-Shot Prompting
<a id="create-message-history-for-few-shot-prompting"></a>

This example shows how to prompt an LLM by providing an example
message history as input.

Create the initial message history.

- Add a system prompt by creating a text message with `Role`
set to `"system"`.

- Add three sample prompts with `Role` set to
`"user"`, each followed by a sample response with
`Role` set to `"assistant"`.

- Add a final prompt with `Role` set to
`"user"`.

```
messageHistory = [...
    aisdk.LLMTextMessage("Assess user statements. Answer as succinctly as possible.",Role="system"), ...
    aisdk.LLMTextMessage("Broccoli is a vegetable.",Role="user"), ...
    aisdk.LLMTextMessage("True",Role="assistant"), ...
    aisdk.LLMTextMessage("Apples are a vegetable.",Role="user"), ...
    aisdk.LLMTextMessage("False",Role="assistant"), ...
    aisdk.LLMTextMessage("Tomatoes are a vegetable.",Role="user"), ...
    aisdk.LLMTextMessage("True culinarily, but not botanically.",Role="assistant"), ...
    aisdk.LLMTextMessage("Cucumbers are a vegetable.",Role="user")];
```

Generate a response to the message history by using the [`generate`](generate.md) function.

```
[~,newMessage] = generate(client,messageHistory)
```

```
newMessage =

  aisdk.LLMTextMessage with properties:

       Text: "False botanically; they are a fruit, but commonly used as a vegetable."
       Role: "assistant"
       Type: "text"
```
## See Also
<a id="see-also"></a>

[`generate`](generate.md) | [`aisdk.LLMToolCallMessage`](aisdk.LLMToolCallMessage.md) | [`aisdk.LLMImageMessage`](aisdk.LLMImageMessage.md) | [`aisdk.LLMToolResultMessage`](aisdk.LLMToolResultMessage.md) | [`aisdk.AIAgent`](aisdk.AIAgent.md)

*Copyright 2026 The MathWorks, Inc.*

