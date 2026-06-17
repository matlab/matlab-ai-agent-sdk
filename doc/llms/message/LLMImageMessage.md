# LLMImageMessage

Represents an image message in a conversation.

## Syntax

```matlab
msg = aisdk.llms.message.LLMImageMessage(content, role)
msg = aisdk.llms.message.LLMImageMessage(content, role, Detail=detail)
```

## Description

`aisdk.llms.message.LLMImageMessage(content, role)` creates an image message directly. `content` can be a file path, URL, or MATLAB image array. The image is eagerly resolved and stored as a MATLAB numeric array in `Content`, so it is directly usable with `imshow`, `imwrite`, and other image functions.

`aisdk.llms.message.LLMImageMessage(content, role, Detail=detail)` also sets the image resolution detail level (`"auto"`, `"low"`, `"high"`, or `"original"`). Only consumed by providers that support it (currently OpenAI).

Text and images are separate messages. A user turn with text and N images becomes N+1 messages: 1 text message + N image messages, all with `Role: "user"`. Array order preserves interleaving.

> The image is encoded to base64 PNG at serialization time by each client's `convertMessages` method. The `Content` property always holds the decoded MATLAB array, not raw bytes.

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Role` | `string` | — | `"user"`, `"assistant"`, or `"tool"`. |
| `Type` | `string` | `"image"` | Always `"image"`. |
| `Content` | numeric or logical array | — | MATLAB image array, usable with `imshow`/`imwrite`. |
| `Detail` | `string` | `"auto"` | Image resolution detail level: `"auto"`, `"low"`, `"high"`, or `"original"`. Only consumed by providers that support it (currently OpenAI). |

## Accepted Sources

| Content | Example | Notes |
|---------|---------|-------|
| File path | `"peppers.png"` | Read with `imread` at construction time. |
| URL | `"https://example.com/cat.jpg"` | Downloaded and decoded at construction time. |
| MATLAB image array | `imread("peppers.png")` | Stored directly. Must be a nonempty numeric or logical array (M×N, M×N×1, M×N×3, or M×N×4). |

## Examples

### Send an image from a file path

```matlab
client = aisdk.LLMClient("openai", "gpt-4.1-mini");

msgs = [aisdk.LLMMessage("What is in this image?"), ...
        aisdk.LLMMessage("photo.jpg", Type="image")];

resp = generate(client, msgs);
```

### Send a MATLAB-generated image

```matlab
img = imread("peppers.png");

msgs = [aisdk.LLMMessage("Describe the colors in this image."), ...
        aisdk.LLMMessage(img)];

resp = generate(client, msgs);
```

### Interleaved text and images

```matlab
msgs = [aisdk.LLMMessage("Look at this"), ...
        aisdk.LLMMessage("a.png", Type="image"), ...
        aisdk.LLMMessage("Now compare with this"), ...
        aisdk.LLMMessage("b.png", Type="image")];

resp = generate(client, msgs);
```

### With OpenAI detail control

```matlab
msg = aisdk.LLMMessage("photo.jpg", Type="image", Detail="high");
msg.Detail  % "high"
```

### Inspect the stored image

```matlab
msg = aisdk.LLMMessage("peppers.png", Type="image");
imshow(msg.Content)     % display it
size(msg.Content)       % e.g. 384×512×3
class(msg.Content)      % "uint8"
```

## See Also

[LLMMessage](../LLMMessage.md) | [LLMToolCallMessage](LLMToolCallMessage.md) | [LLMToolResultMessage](LLMToolResultMessage.md)
