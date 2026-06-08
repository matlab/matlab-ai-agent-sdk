# LLMMessage

Create an LLM message.

## Syntax

```matlab
msg = aisdk.LLMMessage(content)
msg = aisdk.LLMMessage(content, Role=role)
msg = aisdk.LLMMessage(content, Type="image")
msg = aisdk.LLMMessage(content, Type="image", Detail=detail)
msg = aisdk.LLMMessage(content, Type="tool-call", Name=name, ToolCallID=id, Arguments=args)
msg = aisdk.LLMMessage(content, Type="tool-result", Name=name, ToolCallID=id)
```

## Description

`LLMMessage` is the top-level factory for creating conversation messages. It infers the message type from the input content, or you can specify it explicitly with the `Type` name-value argument.

`LLMMessage(content)` creates a user text message when `content` is a string or char, or a user image message when `content` is a non-scalar numeric or logical array.

`LLMMessage(content, Role=role)` creates a text message with the specified role (`"user"`, `"assistant"`, or `"tool"`).

`LLMMessage(content, Type="image")` creates a user image message from a file path or URL. (For MATLAB arrays, `Type` is inferred automatically.)

`LLMMessage(content, Type="image", Detail=detail)` sets the image resolution detail level (`"auto"`, `"low"`, `"high"`, or `"original"`).

`LLMMessage(content, Type="tool-call", Name=name, ToolCallID=id, Arguments=args)` creates a tool call message.

`LLMMessage(content, Type="tool-result", Name=name, ToolCallID=id)` creates a tool result message.

## Name-Value Arguments

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `Type` | `string` | `"auto"` | Message type: `"auto"`, `"text"`, `"image"`, `"tool-call"`, or `"tool-result"`. When `"auto"`, inferred from content. |
| `Role` | `string` | `"user"` | Message role: `"user"`, `"assistant"`, or `"tool"`. |
| `Detail` | `string` | `"auto"` | Image resolution detail: `"auto"`, `"low"`, `"high"`, or `"original"`. Only applies to image messages. |
| `Name` | `string` | — | Tool name. Required for `"tool-call"` and `"tool-result"` types. |
| `ToolCallID` | `string` | — | Tool call identifier. Required for `"tool-call"` and `"tool-result"` types. |
| `Arguments` | `struct` | `struct()` | Arguments for tool call messages. |

## Examples

### Text messages

```matlab
msg = aisdk.LLMMessage("Hello!")
msg = aisdk.LLMMessage("I am an assistant message!", Role="assistant")
```

### Image from a MATLAB array

```matlab
img = imread("peppers.png");
msg = aisdk.LLMMessage(img)
```

### Image from a file path

```matlab
msg = aisdk.LLMMessage("photo.jpg", Type="image")
msg = aisdk.LLMMessage("photo.jpg", Type="image", Detail="low")
```

### Image from a URL

```matlab
msg = aisdk.LLMMessage("https://example.com/cat.jpg", Type="image")
```

### Multi-turn with images

```matlab
msgs = [aisdk.LLMMessage("What is in this image?"), ...
        aisdk.LLMMessage("peppers.png", Type="image")];
```

### Tool messages

```matlab
toolCall = aisdk.LLMMessage([], Type="tool-call", Name="getWeather", ...
    ToolCallID="call_01", Arguments=struct("city", "London"))

toolResult = aisdk.LLMMessage("Sunny, 22C", Type="tool-result", ...
    Name="getWeather", ToolCallID="call_01")
```

## See Also

[LLMTextMessage](llms/message/LLMTextMessage.md) | [LLMImageMessage](llms/message/LLMImageMessage.md) | [LLMToolCallMessage](llms/message/LLMToolCallMessage.md) | [LLMToolResultMessage](llms/message/LLMToolResultMessage.md)
