# LLMTextMessage

Represents a plain text message in a conversation.

## Syntax

```matlab
msg = aisdk.llms.message.LLMTextMessage(role, content)
```

## Description

`aisdk.llms.message.LLMTextMessage(role, content)` creates a text message directly with the specified role and content.

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `Role` | `string` | `"user"`, `"assistant"`, or `"tool"`. |
| `Type` | `string` | Always `"text"`. |
| `Content` | `string` | The text of the message. |

## Examples

```matlab
msg = aisdk.llms.message.LLMTextMessage("user", "What is the capital of France?");
msg.Role     % "user"
msg.Content  % "What is the capital of France?"
```

```matlab
msg = aisdk.llms.message.LLMTextMessage("assistant", "Paris is the capital of France.");
msg.Role  % "assistant"
```

## See Also

[LLMMessage](../LLMMessage.md) | [LLMImageMessage](LLMImageMessage.md) | [LLMToolCallMessage](LLMToolCallMessage.md) | [LLMToolResultMessage](LLMToolResultMessage.md)
