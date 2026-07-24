# MATLAB AI Agent SDK

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=matlab/matlab-ai-agent-sdk)

MATLAB® AI Agent SDK lets you build and run AI agents in MATLAB.

- Create agents based on OpenAI®, Ollama™, or OpenAI-compatible APIs.
- Integrate LLMs and agentic workflows into your workflows in a targeted manner, retaining deterministic workflows when those are more suitable.
- Create agentic tools that use:
  - large amounts of data
  - any MATLAB data type

## Research Preview

This SDK is a Research Preview under active development and APIs may change.

Please leave feedback, report bugs and feature requests via [Issues](../../issues). We review all contributions, but we do not merge external pull requests. See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

Help us improve the MATLAB AI Agent SDK by completing our short [feedback survey](https://www.surveymonkey.com/r/KLQY8WC).

## Setup

You can use the add\-on in MATLAB Online™ by clicking this link: [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=matlab/matlab-ai-agent-sdk)

To use the add\-on on an installed version of MATLAB, you can clone the GitHub repository. In the MATLAB Command Window, run this command:
```
>> !git clone https://github.com/matlab/matlab-ai-agent-sdk.git
```
To run code from the add\-on outside of the installation directory, add the path to the installation directory.
```
>> addpath("path/to/matlab-ai-agent-sdk")
```

### OpenAI

Using the OpenAI API requires an OpenAI API key. For information on how to obtain one, as well as pricing, terms and conditions of use, and available models, see the [OpenAI documentation](https://platform.openai.com/docs/overview).

Set your key as an environment variable in a `.env` file:

```
OPENAI_API_KEY=<your key>
```

Then load it in MATLAB.

```matlab
loadenv(".env")
```

### OpenAI-Compatible APIs

To connect to APIs that are compatible with the OpenAI Chat Completions API, set your key as an environment variable in a `.env` file:

```
OPENAI_API_KEY=<your key>
```

If your API does not need an API key, set the environment variable `OPENAI_API_KEY` to `"EMPTY"`.

Then, when creating an LLM client, set the `api` argument of the `aisdk.LLMClient` function to `"openai"` and set the `BaseURL` name-value argument to the base URL of the API. For example, for OpenAI, `BaseURL` is `"https://api.openai.com/v1"`.

### Ollama

To connect to local or remote [Ollama](https://ollama.com/) models, first install Ollama.

After you have installed Ollama, you can install models from the MATLAB Command Window:
```matlab
!ollama pull <modelname>
```

## Get Started

Create an LLM client by using the `aisdk.LLMClient` function and using the API and the model name as input arguments, for example:

```matlab
clientOpenAI = aisdk.LLMClient("openai", "gpt-4.1-mini");
clientOllama = aisdk.LLMClient("ollama", "<model-name>");
```

Then, generate text by using the `generate` function.

```matlab
text = generate(client, "This is an example prompt.")
```
```
text = 
    "This is an example reponse."
```

### Create Chat With LLM

This example shows how to create a conversation with an LLM and automatically keep track of the message history.

Create the agent from an LLM client `client` by using the `aisdk.AIAgent` function. Provide a system prompt.

```matlab
systemPrompt = "Reply as if you are writing telegrams.";
agent = aisdk.AIAgent(client,SystemPrompt=systemPrompt);
```
Run the agent by using the `run` function. Provide a prompt.

```matlab
prompt = "TOMATO FRUIT OR VEGETABLE STOP";
run(agent,prompt)
```
```
ans = 

    "TOMATO TECHNICALLY A FRUIT STOP COMMONLY USED AS VEGETABLE IN CULINARY CONTEXT STOP END OF TRANSMISSION."
```

Ask a follow up question by using the `run` function.

```matlab
run(agent,"HOW ABOUT AVOCADO STOP")
```
```
ans = 

    "AVOCADO ALSO A FRUIT STOP KNOWN AS ALLIGATOR PEAR STOP HIGH IN HEALTHY FATS AND NUTRIENTS STOP END OF TRANSMISSION."
```
Inspect the chat history by using the `Messages` property of the agent.

```matlab
agent.Messages
```
```
ans = 

  1×4 LLMTextMessage array with messages:

    1    User         Text    "TOMATO FRUIT OR VEGETABLE STOP"
    2    Assistant    Text    "TOMATO TECHNICALLY A FRUIT STOP COMMONLY USED AS VEGETABLE I..."
    3    User         Text    "HOW ABOUT AVOCADO STOP"
    4    Assistant    Text    "AVOCADO ALSO A FRUIT STOP KNOWN AS ALLIGATOR PEAR STOP HIGH ..."
```

### Create AI Agent With Tools

This example shows how to create an AI agent with a set of tools.

Create a function that counts the number of times a letter appears in a word.

```matlab
function numLetter = countLetters(word,letter)
    numLetter = count(word,letter);
end
```
Create a tool from the `countLetters` function by using the `aisdk.LLMTool` function. Add information about input and output arguments to the tool by using the `aisdk.LLMToolArgument` function.

```matlab
tool = aisdk.LLMTool(@countLetters);
tool.InputArguments(1) = aisdk.LLMToolArgument("word",DataType="string");
tool.InputArguments(2) = aisdk.LLMToolArgument("letter",DataType="string");
tool.OutputArguments = aisdk.LLMToolArgument("numLetter",DataType="number");
```

Create the agent from an LLM client `client` by using the `aisdk.AIAgent` function.

```matlab
agent = aisdk.AIAgent(client,Tools=tool);
```

Run the agent by using the `run` function.

```matlab
run(agent,"How many times is the letter r in the word strawberry?")
```
```
ans = "The letter "r" appears 3 times in the word "strawberry.""
```

### Configure Tool to Use Agent Workspace
This example shows how to configure an LLM tool to use data from the agent workspace as input or output data.

The `eig` function calculates the eigenvectors and eigenvalues of matrices. Vectors and matrices can contain a lot of numerical data. Instead of sending all this data to an LLM, which would cost tokens, keep the data in the agent workspace and configure your tools to work on that workspace.

Create a function called `eigTool`.

- The first input argument of the function must be a structure array. Call the argument `ws`.

- The last output argument of the function must be the same structure array.

To allow the agent to understand the outcome of the tool call, add another output argument, observation, that contains a natural language description of the outcome of the tool call. Describe the outcome using the observation output argument.

```matlab
function [observation,ws] = eigTool(ws)
% Compute the eigenvalues of a matrix
ws.eigenvalues = eig(ws.matrix);
observation = "Eigenvalues added to the workspace as a variable called eigenvalues.";
end
```

Create an LLM tool from the `eigTool` function by using the `aisdk.LLMTool` function. Set the `Workspace` name-value argument to `"agent"`.

```matlab
tool = aisdk.LLMTool(@eigTool,Workspace="agent");
```

You can now add the tool to an agent `agentWithWorkspace`. Add a matrix `A` to the agent workspace by setting the `Workspace` property. Call the field `matrix` to match the field name in the tool definition.

```matlab
agentWithWorkspace.Tools = tool;
agentWithWorkspace.Workspace.matrix = A;
```

## Functions

| Function | Description |
|----|----|
| [aisdk.AIAgent](doc/functions/aisdk.AIAgent.md) | Build AI agent | 
| [run](doc/functions/run.md) | Run AI agent | 
| [aisdk.LLMClient](doc/functions/aisdk.LLMClient.md) | Connect to third-party LLM API | 
| [OpenAIClient](doc/functions/OpenAIClient.md) | Client for OpenAI API | 
| [OllamaClient](doc/functions/OllamaClient.md) | Client for Ollama API | 
| [generate](doc/functions/generate.md) | Generate output from LLMs | 
| [aisdk.LLMTool](doc/functions/aisdk.LLMTool.md) | Tool for AI agent | 
| [LocalLLMTool](doc/functions/LocalLLMTool.md) | AI agent tool from MATLAB function | 
| [MCPTool](doc/functions/MCPTool.md) | AI agent tool from MCP server | 
| [selectTool](doc/functions/selectTool.md) | Select LLM tool from tool array | 
| [evaluate](doc/functions/evaluate.md) | Evaluate LLM tool | 
| [aisdk.LLMToolArgument](doc/functions/aisdk.LLMToolArgument.md) | Argument for LLM tool | 


## Examples

| Example                                                                              | Description                                                                                                                                                                                                                 |
| ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [SimpleMathAgent.m](doc/examples/SimpleMathAgent.m)                                     | Simple math agent example                                                      |
| [CreateSimpleChatBotUsingAIAgent.m](doc/examples/CreateSimpleChatBotUsingAIAgent.m)     | Create interactive chatbot in Command Window                                   |
| [AnalyzeTextUsingParallelToolCalls.m](doc/examples/AnalyzeTextUsingParallelToolCalls.m) | Extract structured data from text                                              |
| [FitPolynomialToDataUsingAIAgent.m](doc/examples/FitPolynomialToDataUsingAIAgent.m)     | Build AI agent that fits polynomials to data (requires Curve Fitting Toolbox™) |
| [NestedToolsAndSubagentsExample.m](doc/examples/NestedToolsAndSubagentsExample.m)       | Create tools that provide other tools                                          |
| [SupervisorSubagentExample.m](doc/examples/SupervisorSubagentExample.m)                 | Supervisor pattern with sub-agents                                             |
| [MCPClientAndAgentTools.m](doc/examples/MCPClientAndAgentTools.m)                       | Connect agent to Model Context Protocol (MCP) server                           |
| [SendImageMessagesToVisionModels.m](doc/examples/SendImageMessagesToVisionModels.m)     | Send image messages to vision models                                           |

## License

The license is available in the [LICENSE](LICENSE) file in this GitHub repository.

## Contact

To ask questions, report issues, or request technical support, open an [Issue](../../issues).

---

*Copyright 2026 The MathWorks, Inc.*
