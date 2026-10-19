# OpenAIResponsesClient
<a id="openairesponsesclient"></a>

Client for OpenAI Responses API
## Description
<a id="description"></a>

Use an `OpenAIResponsesClient` object to set large language model
(LLM) options to generate text and create agents using the OpenAI&#x00AE; Responses API.

To generate text, use the `OpenAIResponsesClient` object as an input to the
[`generate`](generate.md)
function. To create an AI agent, use the `OpenAIResponsesClient` object as an
input to the [`aisdk.AIAgent`](aisdk.AIAgent.md)
function.

To use the OpenAI Chat Completions API instead, use an
[`OpenAIClient`](OpenAIClient.md) object.
## Creation
<a id="creation"></a>

Create an `OpenAIResponsesClient` object using [`aisdk.LLMClient`](aisdk.LLMClient.md)
and specifying `"openai-responses"` as the first input argument.
## Properties
<a id="properties"></a>
### `ModelName` — Model name
<a id="modelname"></a>

string scalar

Model name, specified as a string scalar containing the name of the model using the
spelling that OpenAI expects.

Example: `"gpt-5.4-mini"`

Data Types: `string`
### `BaseURL` — Base URL for OpenAI-compatible API
<a id="baseurl"></a>

string scalar

Base URL for OpenAI-compatible API, specified as a string scalar.

Specify this property to use an OpenAI-compatible API.

The client appends `"responses"` to the base URL, so the value of
this property is the full endpoint that the client sends requests to. For example, if
you specify `"https://api.openai.com/v1"`, then
`BaseURL` is
`"https://api.openai.com/v1/responses"`.

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
values and the default value depend on the model.

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

`120` (default) | positive numeric scalar

Connection timeout in seconds, specified as a positive numeric scalar.

If the model does not respond in the timeout, then the function returns an
error.

Data Types: `single` | `double` | `int8` | `int16` | `int32` | `int64` | `uint8` | `uint16` | `uint32` | `uint64`
### `ResponseFormat` — Response format
<a id="responseformat"></a>

`"text"` (default) | `"json"` | string scalar | structure array

Response format, specified as a string scalar or structure array.

Use the `ResponseFormat` property to specify the output format of
the generated text. You can request unformatted output, JSON mode, or structured output.
To find out which of these output formats your model supports, see the model
documentation.

If the response format is set to `"text"`, then the generated
output is an unformatted string.

If the response format is set to `"json"`, then the generated
output is a formatted string containing JSON encoded data. To configure the format of
the generated JSON file, describe the format using natural language and provide it to
the model either in the system prompt or as a user message.

To make sure that the model output adheres to the required format, use structured
output. To do this, set `ResponseFormat` to:

- A structure array containing an example that adheres to the required format,
for example: `ResponseFormat=struct("Name","Rudolph","NoseColor",[255 0
0])` results in outputs with two fields,`"Name"` with
a string value, and `NoseColor` with a three-integer array
value.

- A string scalar containing a valid JSON schema.

Data Types: `string` | `struct`
### `ContextSize` — Maximum number of input tokens
<a id="contextsize"></a>


`NaN`
(default) | positive integer

Maximum number of input tokens, specified as `NaN` or as a positive
integer.

Specify the context size so that an [`aisdk.AIAgent`](aisdk.AIAgent.md) object can
calculate the fraction of the model context that the agent has used in a
conversation.

When `ContextSize` is `NaN`, the
`ContextUsage` property of the agent is also
`NaN`.

The maximum number of input tokens not only depends on the model, but can also
depend on other properties, such as the locally available VRAM. For more information,
consult the model documentation.

Data Types: `single` | `double` | `int8` | `int16` | `int32` | `int64` | `uint8` | `uint16` | `uint32` | `uint64`
### `Verbosity` — Verbosity of generated output
<a id="verbosity"></a>

`"auto"` (default) | `"low"` | `"medium"` | `"high"`

Verbosity of generated output, specified as a string scalar or character
vector.

If `Verbosity` is set to `"auto"`, then the
software chooses the default value of the model.

Data Types: `string`
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
### Connect to OpenAI Responses API
<a id="connect-to-openai-responses-api"></a>

To generate text using the OpenAI Responses API and the model `model`, first create an
`OpenAIResponsesClient` by using the [`aisdk.LLMClient`](aisdk.LLMClient.md) function. Then, generate text by using the [`generate`](generate.md) function.

```
client = aisdk.LLMClient("openai-responses",model);
prompt = "This is an example prompt.";
generate(client,prompt)
```

```
ans =
  "This is an example response generated by using the OpenAI Responses API."
```
### Connect to OpenAI-Compatible API
<a id="connect-to-openai-compatible-api"></a>

This example shows how to connect to an API that is compatible with
the OpenAI Responses API.

If the API requires an API key, then set the `OPENAI_API_KEY`
environment variable in a file called `.env` to the API key of the
OpenAI-compatible API.

```
OPENAI_API_KEY=<your key>
```

Then, load the environment file.
```
loadenv(".env")
```

Set the `BaseURL` name-value argument to the base URL
`baseurl` of the API. For example, for OpenAI, the base URL is `"https://api.openai.com/v1"`.

```
client = aisdk.LLMClient("openai-responses",model,BaseURL=baseurl);
```
## See Also
<a id="see-also"></a>

[`aisdk.LLMClient`](aisdk.LLMClient.md) | [`generate`](generate.md) | [`OpenAIClient`](OpenAIClient.md) | [`OllamaClient`](OllamaClient.md)

*Copyright 2026 The MathWorks, Inc.*

