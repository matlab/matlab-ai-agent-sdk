# OpenAIClient
<a id="openaiclient"></a>

Client for OpenAI API
## Description
<a id="description"></a>

Use an `OpenAIClient` object to set large language model (LLM)
options to generate text and create agents using the OpenAI&#x00AE; API.

To generate text, use the `OpenAIClient` object as an input to the
[`generate`](generate.md)
function. To create an AI agent, use the `OpenAIClient` object as an input to
the [`aisdk.AIAgent`](aisdk.AIAgent.md)
function.
## Creation
<a id="creation"></a>

Create an `OpenAIClient` object using [`aisdk.LLMClient`](aisdk.LLMClient.md)
and specifying `"openai"` as the first input argument.
## Properties
<a id="properties"></a>
### `ModelName` — Model name
<a id="modelname"></a>

string scalar

Model name, specified as a string scalar containing the name of the model using the
spelling that OpenAI expects.

Example: `"gpt-4o-mini"`

Data Types: `string`
### `BaseURL` — Base URL for OpenAI-compatible API
<a id="baseurl"></a>

string scalar

Base URL for OpenAI-compatible API, specified as a string scalar.

Specify this property to use an OpenAI-compatible API.

Example: `"https://api.openai.com/v1"`

Data Types: `string`
### `MaxNumTokens` — Maximum number of generated tokens
<a id="maxnumtokens"></a>


`inf`
(default) | positive integer

Maximum number of generated tokens, specified as `inf` or as a positive integer.

Data Types: `single` | `double` | `int8` | `int16` | `int32` | `int64` | `uint8` | `uint16` | `uint32` | `uint64`
### `ReasoningEffort` — Amount of internal reasoning
<a id="reasoningeffort"></a>

`"auto"` (default) | string scalar

Amount of internal reasoning, specified as a string scalar.

If `ReasoningEffort` is set to `"auto"`, then
the software chooses the default value of the model used to generate text. The supported
values and the default value depend on the model, for example:

| Model | Default | Supported Values |
| --- | --- | --- |
| GPT-5 | `"medium"` | `"minimal"`, `"low"`, `"medium"`, `"high"` |
| GPT-5.1 | `"none"` | `"none"`, `"low"`, `"medium"`, `"high"` |
| GPT 5.2 | `"none"` | `"none"`, `"low"`, `"medium"`, `"high"`, `"xhigh"` |

Data Types: `string`
### `StopSequences` — Stop sequences
<a id="stopsequences"></a>


`[]`
(default) | string array

Stop sequences, specified as `[]` or as a string array.

When the generated output contains one of the specified stop sequences, the model stops token generation.

Example:
`["The end.","And that is all she wrote."]`

Data Types: `string`
### `StreamFcn` — Custom streaming function
<a id="streamfcn"></a>

function handle

Custom streaming function, specified as a function handle.

Specify a custom streaming function to process the generated output as it is
generated, rather than having to wait for the end of the generation. For example, you
can use this function to print the output as it is generated.

Example: `@(token) fprintf("%s",token)` prints each token when it is
generated.

Data Types: `function_handle`
### `TimeOut` — Connection timeout in seconds
<a id="timeout"></a>

`120` (default) | nonnegative numeric scalar

Connection timeout in seconds, specified as a nonnegative numeric scalar.

If the model does not respond within the timeout, then the function returns an
error.

Data Types: `single` | `double` | `int8` | `int16` | `int32` | `int64` | `uint8` | `uint16` | `uint32` | `uint64`
### `ResponseFormat` — Response format
<a id="responseformat"></a>

`"text"` (default) | `"json"` | string scalar | structure array

Response format, specified as a string scalar or structure array.

Use the `ResponseFormat` property to specify the output format of
the generated text. You can request unformatted output, JSON mode, or structured output.
To find out which of these output formats your model supports, check the model
documentation.

If the response format is set to `"text"`, then the generated
output is an unformatted string.

If the response format is set to `"json"`, then the generated
output is a formatted string containing JSON encoded data. To configure the format of
the generated JSON file, describe the format using natural language and provide it to
the model either in the system prompt or as a user message.

To ensure that the model output adheres to the required format, use structured
output. To do this, set `ResponseFormat` to:

- A structure array containing an example that adheres to the required format,
for example: `ResponseFormat=struct("Name","Rudolph","NoseColor",[255 0
0])` results in outputs with two fields,`"Name"` with
a string value, and `NoseColor` with a three-integer array
value.

- A string scalar containing a valid JSON schema.

Data Types: `string` | `struct`
### `Verbosity` — Verbosity of generated output
<a id="verbosity"></a>

`"auto"` (default) | `"low"` | `"medium"` | `"high"`

Verbosity of generate output, specified as a string scalar or character
vector.

If `Verbosity` is set to `"auto"`, then the
software chooses the default value of the model.

Data Types: `string`
### `PresencePenalty` — Presence penalty
<a id="presencepenalty"></a>

`"auto"` (default) | numeric scalar between `-2` and `2`

Presence penalty value for using a token that has already been used at least once in
the generated output, specified as `"auto"` or as a numeric scalar
between `-2` and `2`.

Higher, positive presence penalty reduces the repetition of tokens. Lower, negative
values increase the repetition of tokens.

The presence penalty is independent of the number of times a token appears in the
output, so long as it is repeated at least once. To increase the penalty for every
additional time the model generates a token, use the
`FrequencyPenalty` property.

If the model supports `PresencePenalty` and
`PresencePenalty` is `"auto"`, then the software
uses the default presence penalty of the model.

Data Types: `single` | `double` | `int8` | `int16` | `int32` | `int64` | `uint8` | `uint16` | `uint32` | `uint64` | `string`
### `FrequencyPenalty` — Frequency penalty
<a id="frequencypenalty"></a>

`"auto"` (default) | numeric scalar between `-2` and `2`

Frequency penalty value for repeatedly using the same token in the generated output,
specified as `"auto"` or as a numeric scalar between
`-2` and `2`.

Higher, positive frequency penalty reduces the repetition of tokens. Lower, negative
values increase the repetition of tokens.

The frequency penalty increases with every instance of a token in the generated
output. To use a constant penalty for a repeated token, independent of the number of
instances that token is generated, use the `PresencePenalty`
property.

If the model supports `FrequencyPenalty` and
`FrequencyPenalty` is `"auto"`, then the software
uses the default frequency penalty of the model.

Data Types: `single` | `double` | `int8` | `int16` | `int32` | `int64` | `uint8` | `uint16` | `uint32` | `uint64` | `string`
### `Temperature` — Temperature
<a id="temperature"></a>

`"auto"` (default) | numeric scalar between `0` and `2`

Temperature value for controlling the randomness of the output, specified as `"auto"` or as a numeric scalar between `0` and `2`. Higher temperature increases the diversity of the output.

If the model supports `Temperature` and `Temperature` is `"auto"`, then the software uses the default temperature of the model.

Data Types: `single` | `double` | `int8` | `int16` | `int32` | `int64` | `uint8` | `uint16` | `uint32` | `uint64` | `string`
### `TopP` — Top probability mass
<a id="topp"></a>

`"auto"` (default) | numeric scalar between `0` and `1`

Top probability mass for controlling the diversity of the output, specified as
`"auto"` or as a numeric scalar between `0` and
`1`. Higher top probability mass increases the diversity of the
output.

If the model supports `TopP` and `TopP` is
`"auto"`, then the software uses the default top probability mass of
the model.

Data Types: `single` | `double` | `int8` | `int16` | `int32` | `int64` | `uint8` | `uint16` | `uint32` | `uint64` | `string`
## Examples
<a id="examples"></a>
### Connect to OpenAI API
<a id="connect-to-openai-api"></a>

To generate text using the OpenAI API and the model `model`, first create an
`OpenAIClient` by using the [`aisdk.LLMClient`](aisdk.LLMClient.md) function. Then, generate text by using the [`generate`](generate.md) function.

```
client = aisdk.LLMClient("openai",model);
prompt = "This is an example prompt.";
generate(client,prompt)
```

```
ans =
  "This is an example response generated by using the OpenAI API."
```
### Connect to OpenAI-Compatible API
<a id="connect-to-openai-compatible-api"></a>

This example shows how to connect to an OpenAI-compatible API.

If the API requires an API key, then set the `OPENAI_API_KEY` environment variable in a file called `.env` to the API key of the OpenAI-compatible API.

```
OPENAI_API_KEY=<your key>
```

Set the `BaseURL` name-value argument to the base URL `baseurl` of the API. For example, for OpenAI, the base URL is `"https://api.openai.com/v1"`.

```
client = aisdk.LLMClient("openai",model,BaseURL=baseurl);
```
## See Also
<a id="see-also"></a>

[`aisdk.LLMClient`](aisdk.LLMClient.md) | [`generate`](generate.md) | [`OllamaClient`](OllamaClient.md)

*Copyright 2026 The MathWorks, Inc.*

