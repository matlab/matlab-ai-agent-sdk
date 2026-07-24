# aisdk.LLMImageMessage
<a id="aisdkllmimagemessage"></a>

Image message in LLM message history
## Description
<a id="description"></a>

An image message in the message history of a large language model (LLM) stores
images and associated metadata.

View the message history to understand the reasoning and actions that an agent
performs.

The message history can contain these message types:

- [`aisdk.LLMTextMessage`](aisdk.LLMTextMessage.md)

- [`aisdk.LLMImageMessage`](aisdk.LLMImageMessage.md)

- [`aisdk.LLMToolCallMessage`](aisdk.LLMToolCallMessage.md)

- [`aisdk.LLMToolResultMessage`](aisdk.LLMToolResultMessage.md)
## Creation
<a id="creation"></a>
### Description
<a id="description-1"></a>

When you create an AI agent by using the [`aisdk.AIAgent`](aisdk.AIAgent.md) function, the
software automatically creates LLM messages and stores them in the
`Messages` property of the agent.

`message = aisdk.LLMImageMessage(img)`
creates an image message from image data `img`.

`message = aisdk.LLMImageMessage(filename)`
creates an image message from the image in the specified graphics file
`filename`.

`message = aisdk.LLMImageMessage(___,Detail=detail)`
also specifies the amount of detail `detail` that the model uses to
understand the image. This option is supported only for the OpenAI&#x00AE; API.
### `img` — Image data
<a id="img"></a>

matrix

Image data, specified as a full (nonsparse) matrix.

- For grayscale images, `img` can be m-by-n.

- For truecolor images, `img` must be m-by-n-by-3.

This argument sets the `Image` property.

Data Types: `single` | `double` | `int8` | `int16` | `int32` | `int64` | `uint8` | `uint16` | `uint32` | `uint64` | `logical`
### `filename` — Name of graphics file
<a id="filename"></a>

string scalar | character vector

Name of graphics file, specified as a string scalar or character vector.

Name of the graphics file, specified as a string scalar or character
vector.

Depending on the location of your file, `filename` can take one
of these forms.

| Location | Form |
| --- | --- |
| Current folder or folder on the MATLAB&#x00AE; path | Specify the name of the file in `filename`. Example: `"myImage.jpg"` |
| File in a folder | If the file is not in the current folder or in a folder on the MATLAB path, then specify the full or relative path name. Example: `"C:\myFolder\myImage.png"` Example: `"\imgDir\myImage.bmp"` |
| URL | If the file is located by an internet URL, then `filename` must contain the protocol type, such as `http://`. Example: `"http://my_hostname/my_path/my_image.jpg"` |
| Remote location | If the file is stored at a remote location, then `filename` must contain the full path of the file specified as a URL of the form: `scheme_name://path_to_file/my_file.ext` Based on the remote location, `scheme_name` can be one of the values in this table. Amazon S3&#x2122;: `s3`; Windows Azure&#xAE; Blob Storage: `wasb`, `wasbs`; HDFS&#x2122;: `hdfs` Example:`"s3://my_bucket/my_path/my_image.heif"` |

The function loads the image and store it in the `Image`
property.

Data Types: `string` | `char`
### `detail` — Image detail
<a id="detail"></a>

`"auto"` (default) | `"low"` | `"high"` | `"original"`

Image detail, specified as `"auto"`, `"low"`,
`"high"`, or `"original"`.

The image detail specifies how much detail the model uses to understand an
image.

This argument sets the `Detail` property.

This option is supported only for the OpenAI API.

Data Types: `string`
## Properties
<a id="properties"></a>
### `Role` — Message sender
<a id="role"></a>

Read-only: `"user"`

This property is read-only.

Message sender, specified as `"user"`.

Data Types: `string`
### `Type` — Message type
<a id="type"></a>

Read-only: `"image"`

This property is read-only.

Message type, specified as `"image"`.

Data Types: `string`
### `Image` — Image data
<a id="image"></a>

matrix

Image data, specified as a full (nonsparse) matrix.

- For grayscale images, `Image` can be m-by-n.

- For truecolor images, `Image` must be m-by-n-by-3.

Data Types: `single` | `double` | `int8` | `int16` | `int32` | `int64` | `uint8` | `uint16` | `uint32` | `uint64` | `logical`
### `Detail` — Image detail
<a id="detail-1"></a>

Read-only: `"auto"` (default) | `"low"` | `"high"` | `"original"`

This property is read-only.

Image detail, specified as `"auto"`, `"low"`,
`"high"`, or `"original"`.

The image detail specifies how much detail the model uses to understand an
image.

This option is supported only for the OpenAI API.

Data Types: `string`
## Examples
<a id="examples"></a>
### Inspect Agent Message History
<a id="inspect-agent-message-history"></a>

When you create an agent by using the [`aisdk.AIAgent`](aisdk.AIAgent.md) function, the
software keeps track of the message history automatically.

Inspect the chat history of an AI agent `agent` by using the
`Messages` property of the agent.

```
agent.Messages
```

```
ans =
  1×3 LLMMessage array with messages:

    1    User         Image    <image 10x10 double>
    2    User         Text     "Describe this image."
    3    Assistant    Text     "The image appears to be a simple black and white graphic wit..."
```

In this example, the message history contains one image message.
### Describe Image with LLM
<a id="describe-image-with-llm"></a>

Create the input message array. Add an image message that contains image data
`img`. Add a text message that contains a user prompt.

```
inputMessages = [...
    aisdk.LLMImageMessage(img), ...
    aisdk.LLMTextMessage("Describe this image.")];
```

Generate a response to the input messages by using the [`generate`](generate.md) function and
the [`aisdk.LLMClient`](aisdk.LLMClient.md) object
`client`.

```
generate(client,inputMessages)
```

```
ans =

    "This is an example image description generated by a model."
```
### Describe Image with AI Agent
<a id="describe-image-with-ai-agent"></a>

Create the input message array. Add an image message that contains image data
`img`. Add a text message that contains a user prompt.

```
inputMessages = [...
    aisdk.LLMImageMessage(img), ...
    aisdk.LLMTextMessage("Describe this image.")];
```

Run the AI agent `agent` by using the [`run`](run.md)
function.

```
run(agent,inputMessages)
```

```
ans =

    "This is an example image description generated by a model."
```

Inspect the chat history of the agent.

```
agent.Messages
```

```
ans =
  1×3 LLMMessage array with messages:

    1    User         Image    <image 10x10 double>
    2    User         Text     "Describe this image."
    3    Assistant    Text     "This is an example image description generated by a model."
```
## See Also
<a id="see-also"></a>

[`generate`](generate.md) | [`aisdk.LLMToolCallMessage`](aisdk.LLMToolCallMessage.md) | [`aisdk.LLMTextMessage`](aisdk.LLMTextMessage.md) | [`aisdk.LLMToolResultMessage`](aisdk.LLMToolResultMessage.md) | [`aisdk.AIAgent`](aisdk.AIAgent.md)

*Copyright 2026 The MathWorks, Inc.*

