# aisdk.llms.client.OllamaClient

Client for Ollama chat completions.

## Syntax

```matlab
client = aisdk.llms.client.OllamaClient(modelName)
client = aisdk.llms.client.OllamaClient(modelName, Name=Value)
```

## Description

`aisdk.llms.client.OllamaClient(modelName)` creates a client for the specified Ollama model.

`aisdk.llms.client.OllamaClient(modelName, Name=Value)` specifies options using one or more name-value arguments. You can specify any of the properties below as name-value arguments.

You can also create an `OllamaClient` using the [`LLMClient`](../../LLMClient.md) factory function:

```matlab
client = aisdk.LLMClient("ollama", "qwen3");
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `ModelName` | `string` | | Name of the model to use. |
| `Temperature` | `numeric` or `"auto"` | `"auto"` | Controls randomness of the output. Higher values increase creativity. |
| `TopP` | `numeric` or `"auto"` | `"auto"` | Top probability mass for controlling output diversity. |
| `MinP` | `numeric` or `"auto"` | `"auto"` | Minimum probability ratio for controlling output diversity. |
| `TopK` | `numeric` or `"auto"` | `"auto"` | Maximum number of most likely tokens considered for output. |
| `TailFreeSamplingZ` | `numeric` or `"auto"` | `"auto"` | Tail-free sampling parameter. Lower values reduce diversity. |
| `StopSequences` | `string` | `[]` | Sequences that stop token generation. |
| `MaxNumTokens` | `numeric` | `inf` | Maximum number of tokens in the response. |
| `ResponseFormat` | | `"text"` | Response format: `"text"`, `"json"`, `struct`, or JSON schema string. |
| `TimeOut` | `numeric` | `120` | Connection timeout in seconds. |
| `StreamFcn` | `function_handle` | `[]` | Callback function for streaming results. |
| `BaseURL` | `string` | `"http://127.0.0.1:11434"` | Server endpoint. Also reads from `OLLAMA_API_ENDPOINT` environment variable. |

## Methods

### generate

```matlab
[text, messages] = generate(client, messagesIn)
[text, messages, info] = generate(client, messagesIn)
[text, messages, info] = generate(client, messagesIn, Name=Value)
```

Generate a response from the model. `messagesIn` can be a string or an array of `LLMMessage` objects. Returns the response text, an array of `LLMMessage` objects (either `LLMAssistantMessage` or `LLMToolCallMessage`), and an `info` struct with token usage. The `info` struct has a `Tokens` field containing `NumInputTokens`, `NumOutputTokens`, `NumTotalTokens`, and `NumCachedInputTokens`.

Name-value arguments allow overriding any client property for a single call, plus:

| Name | Description |
|------|-------------|
| `Tools` | Tools available to the model, as tools created by `LLMTool` or a pre-converted cell/struct. |
| `SystemPrompt` | System prompt prepended to the conversation. |

## Examples

Create a client and generate a response:

```matlab
client = aisdk.llms.client.OllamaClient("qwen3");
[text, messages] = generate(client, "What is the capital of France?");
```

Use custom sampling parameters:

```matlab
client = aisdk.llms.client.OllamaClient("qwen3", Temperature=0.7, TopK=40);
```

## See Also

[OpenAIClient](OpenAIClient.md) | [LLMClient](../../LLMClient.md)
