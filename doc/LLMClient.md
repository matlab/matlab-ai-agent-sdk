# LLMClient

Create an LLM client for chat completions.

## Syntax

```matlab
client = aisdk.LLMClient(api, modelName)
client = aisdk.LLMClient(api, modelName, Name=Value)
```

## Description

`LLMClient(api, modelName)` creates a client object for the specified `api` and `modelName`. The `api` argument must be `"openai"` or `"ollama"`.

`LLMClient(api, modelName, Name=Value)` passes additional name-value arguments to the underlying client class. The available name-value arguments depend on the provider. See [OpenAIClient](llms/client/OpenAIClient.md) and [OllamaClient](llms/client/OllamaClient.md) for details.

## Input Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `api` | `string` | Provider name: `"openai"` or `"ollama"`. |
| `modelName` | `string` | Name of the model to use. |

## Name-Value Arguments

All name-value arguments are forwarded to the underlying client constructor. See [OpenAIClient](llms/client/OpenAIClient.md) or [OllamaClient](llms/client/OllamaClient.md) for the full list.

## Examples

Create a client and generate a response:

```matlab
client = aisdk.LLMClient("openai", "gpt-4o");
[text, messages, info] = generate(client, "What is the capital of France?");
```

Create an Ollama client with a custom temperature:

```matlab
client = aisdk.LLMClient("ollama", "qwen3", Temperature=0.7);
[text, messages, info] = generate(client, "Tell me a joke.");
```

## See Also

[OpenAIClient](llms/client/OpenAIClient.md) | [OllamaClient](llms/client/OllamaClient.md)
