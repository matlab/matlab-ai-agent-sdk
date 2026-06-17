# LLMTextMessage

Represents a plain text message in a conversation.

## Syntax

```matlab
msg = aisdk.LLMTextMessage(content)
msg = aisdk.LLMTextMessage(content, Role=role)
```

## Description

`aisdk.LLMTextMessage(content)` creates a user text message.

`aisdk.LLMTextMessage(content, Role=role)` creates a text message with the specified role.

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Role` | `string` | `"user"` | `"system"`, `"user"`, `"assistant"`, or `"tool"`. |
| `Type` | `string` | `"text"` | Always `"text"`. |
| `Content` | `string` | | The text of the message. |

## Examples

```matlab
msg = aisdk.LLMTextMessage("What is the capital of France?");
msg.Role     % "user"
msg.Content  % "What is the capital of France?"
```

```matlab
msg = aisdk.LLMTextMessage("Paris is the capital of France.", Role="assistant");
msg.Role  % "assistant"
```

## See Also

[LLMMessage](../../LLMMessage.md) | [LLMImageMessage](LLMImageMessage.md) | [LLMToolCallMessage](LLMToolCallMessage.md) | [LLMToolResultMessage](LLMToolResultMessage.md)
