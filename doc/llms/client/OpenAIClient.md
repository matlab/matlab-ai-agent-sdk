# llms.client.OpenAIClient

Client for OpenAI chat completions.

## Syntax

```matlab
client = aisdk.llms.client.OpenAIClient(modelName)
client = aisdk.llms.client.OpenAIClient(modelName, Name=Value)
```

## Description

`aisdk.llms.client.OpenAIClient(modelName)` creates a client for the specified OpenAI model.

`aisdk.llms.client.OpenAIClient(modelName, Name=Value)` specifies options using one or more name-value arguments. You can specify any of the properties below as name-value arguments.

You can also create an `OpenAIClient` using the [`LLMClient`](../../LLMClient.md) factory function:

```matlab
client = aisdk.LLMClient("openai", "gpt-4o");
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `ModelName` | `string` | | Name of the model to use. |
| `Temperature` | `numeric` or `"auto"` | `"auto"` | Controls randomness of the output. Higher values increase creativity. |
| `TopP` | `numeric` or `"auto"` | `"auto"` | Top probability mass for controlling output diversity. |
| `StopSequences` | `string` | `[]` | Sequences that stop token generation. |
| `MaxNumTokens` | `numeric` | `inf` | Maximum number of tokens in the response. |
| `PresencePenalty` | `numeric` or `"auto"` | `"auto"` | Penalty for reusing tokens already in the response. |
| `FrequencyPenalty` | `numeric` or `"auto"` | `"auto"` | Penalty for using frequent tokens. |
| `ResponseFormat` | | `"text"` | Response format: `"text"`, `"json"`, `struct`, or JSON schema string. |
| `TimeOut` | `numeric` | `120` | Connection timeout in seconds. |
| `StreamFcn` | `function_handle` | `[]` | Callback function for streaming results. |
| `BaseURL` | `string` | `"https://api.openai.com/v1/"` | API endpoint. Also reads from `OPENAI_API_ENDPOINT` environment variable. |

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
| `ToolChoice` | Controls tool selection: `"auto"`, `"none"`, `"required"`, or a tool name. |
| `SystemPrompt` | System prompt prepended to the conversation. |

## Examples

Create a client and generate a response:

```matlab
client = aisdk.llms.client.OpenAIClient("gpt-4o");
[text, messages] = generate(client, "What is the capital of France?");
```

Use a custom temperature:

```matlab
client = aisdk.llms.client.OpenAIClient("gpt-4o", Temperature=0.7);
```

## See Also

[OllamaClient](OllamaClient.md) | [LLMClient](../../LLMClient.md)
