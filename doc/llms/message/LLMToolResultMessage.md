# LLMToolResultMessage

Represents the result of a tool call, returned to the model.

## Syntax

```matlab
msg = aisdk.llms.message.LLMToolResultMessage(content, name, toolCallID)
```

## Description

`aisdk.llms.message.LLMToolResultMessage(content, name, toolCallID)` creates a tool result message directly.

These messages provide the output of a tool execution back to the model so it can continue the conversation.

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `Role` | `string` | Always `"tool"`. Identifies this as a tool output. |
| `Type` | `string` | Always `"text"`. |
| `Content` | `string` | The result returned by the tool. |
| `Name` | `string` | The name of the tool that produced the result. |
| `ToolCallID` | `string` | The identifier matching the original `LLMToolCallMessage` that triggered this result. |

## Examples

```matlab
msg = aisdk.llms.message.LLMToolResultMessage("Sunny, 22C", "getWeather", "call_01");
msg.ToolCallID  % "call_01"
msg.Content     % "Sunny, 22C"
```

## See Also

[LLMMessage](../LLMMessage.md) | [LLMToolCallMessage](LLMToolCallMessage.md)
