# LLMToolResultMessage

Represents the result of a tool call, returned to the model.

## Syntax

```matlab
msg = aisdk.LLMToolResultMessage(result)
msg = aisdk.LLMToolResultMessage(result, ToolCallID=id, Name=name)
```

## Description

`aisdk.LLMToolResultMessage(result, ToolCallID=id, Name=name)` creates a tool result message.

These messages provide the output of a tool execution back to the model so it can continue the conversation.

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Role` | `string` | `"tool"` | Always `"tool"`. |
| `Type` | `string` | `"text"` | Always `"text"`. |
| `Result` | `string` | | The result returned by the tool. |
| `Name` | `string` | `""` | The name of the tool that produced the result. |
| `ToolCallID` | `string` or `[]` | `[]` | The identifier matching the original `LLMToolCallMessage` that triggered this result. |

## Examples

```matlab
msg = aisdk.LLMToolResultMessage("Sunny, 22C", ToolCallID="call_01", Name="getWeather");
msg.ToolCallID  % "call_01"
msg.Result      % "Sunny, 22C"
```

## See Also

[LLMMessage](../../LLMMessage.md) | [LLMToolCallMessage](LLMToolCallMessage.md)
