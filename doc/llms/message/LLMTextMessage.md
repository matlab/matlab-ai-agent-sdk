# LLMTextMessage

Represents a plain text message in a conversation.

## Syntax

```matlab
msg = aisdk.LLMTextMessage(text)
msg = aisdk.LLMTextMessage(text, Role=role)
```

## Description

`aisdk.LLMTextMessage(text)` creates a user text message.

`aisdk.LLMTextMessage(text, Role=role)` creates a text message with the specified role.

## Properties

| Property | Type       | Default    | Description                                   |
| -------- | ---------- | ---------- | --------------------------------------------- |
| `Role` | `string` | `"user"` | `"system"`, `"user"`, or `"assistant"`. |
| `Type` | `string` | `"text"` | Always`"text"`.                             |
| `Text` | `string` |            | The text of the message.                      |

## Examples

```matlab
msg = aisdk.LLMTextMessage("What is the capital of France?");
msg.Role  % "user"
msg.Text  % "What is the capital of France?"
```

```matlab
msg = aisdk.LLMTextMessage("Paris is the capital of France.", Role="assistant");
msg.Role  % "assistant"
```

## See Also

[LLMMessage](../../LLMMessage.md) | [LLMImageMessage](LLMImageMessage.md) | [LLMToolCallMessage](LLMToolCallMessage.md) | [LLMToolResultMessage](LLMToolResultMessage.md)
