# OllamaClient
<a id="ollamaclient"></a>

Client for Ollama API
## Description
<a id="description"></a>

Use an `OllamaClient` object to set large language model (LLM)
options to generate text and create agents using the Ollama&#x2122; API.

To generate text, use the `OllamaClient` object as an input to the
[`generate`](generate.md)
function. To create an AI agent, use the `OllamaClient` object as an input to
the [`aisdk.AIAgent`](aisdk.AIAgent.md)
function.
## Creation
<a id="creation"></a>

Create an `OllamaClient` object using [`aisdk.LLMClient`](aisdk.LLMClient.md)
and specifying `"ollama"` as the first input argument.
## Properties
<a id="properties"></a>
### `ModelName` — Model name
<a id="modelname"></a>

string scalar

Model name, specified as a string scalar containing the name of the model using the
spelling that Ollama expects.

Example: `"qwen3.5"`

Data Types: `string`
### `BaseURL` — Base URL
<a id="baseurl"></a>

`"127.0.0.1:11434"` (default) | string scalar

Base URL, specified as a string scalar that contains the network address used to
communicate with the Ollama server.

To connect to a remote Ollama server, include the server name and port number. Ollama starts on port 11434 by default.

Example: `"myOllamaServer:11434"`

Data Types: `string`
### `MaxNumTokens` — Maximum number of generated tokens
<a id="maxnumtokens"></a>


`inf`
(default) | positive integer

Maximum number of generated tokens, specified as `inf` or as a positive integer.

Data Types: `single` | `double` | `int8` | `int16` | `int32` | `int64` | `uint8` | `uint16` | `uint32` | `uint64`
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
### `MinP` — Minimum probability ratio
<a id="minp"></a>

`"auto"` (default) | numeric scalar between `0` and `1`

Minimum probability ratio, specified as `"auto"` or as a numeric
scalar between `0` and `1`.

Tune the frequency of improbable tokens in generated output using min-p sampling.
Higher minimum probability ratio corresponds to lower diversity.

If the model supports `MinP` and `MinP` is
`"auto"`, then the software uses the default minimum probability
ratio of the model.

Data Types: `single` | `double` | `int8` | `int16` | `int32` | `int64` | `uint8` | `uint16` | `uint32` | `uint64` | `string`
### `TopK` — Top-k sampling parameter
<a id="topk"></a>

`"auto"` (default) | positive integer

Top-k sampling parameter, specified as `"auto"` or as a positive
integer.

Sample only from the `TopK` most likely next tokens for each
token during generation. Higher values of `TopK` correspond to higher
diversity.

If the model supports `TopK` and `TopK` is
`"auto"`, then the software uses the default top-k sampling parameter
of the model.

Data Types: `single` | `double` | `int8` | `int16` | `int32` | `int64` | `uint8` | `uint16` | `uint32` | `uint64` | `string`
### `TailFreeSamplingZ` — Tail free sampling parameter
<a id="tailfreesamplingz"></a>

`"auto"` (default) | numeric scalar

Tail free sampling parameter, specified as `"auto"` or as a numeric
scalar.

Tune the frequency of improbable tokens in generated output. Higher values of
`TailFreeSamplingZ` correspond to lower diversity. If
`TailFreeSamplingZ` is set to `1`, then the model
does not use this sampling technique.

If the model supports `TailFreeSamplingZ` and
`TailFreeSamplingZ` is `"auto"`, then the software
uses the default tail free sampling parameter of the model.

Data Types: `single` | `double` | `int8` | `int16` | `int32` | `int64` | `uint8` | `uint16` | `uint32` | `uint64` | `string`
## Examples
<a id="examples"></a>
### Connect to Ollama API
<a id="connect-to-ollama-api"></a>

To generate text using the Ollama API and the model `model`, first create an
`OllamaClient` by using the [`aisdk.LLMClient`](aisdk.LLMClient.md) function. Then, generate text by using the [`generate`](generate.md) function.

```
client = aisdk.LLMClient("ollama",model);
prompt = "This is an example prompt.";
generate(client,prompt)
```

```
ans =
  "This is an example response generated by using the Ollama API."
```
## See Also
<a id="see-also"></a>

[`aisdk.LLMClient`](aisdk.LLMClient.md) | [`generate`](generate.md) | [`OpenAIClient`](OpenAIClient.md)

*Copyright 2026 The MathWorks, Inc.*

