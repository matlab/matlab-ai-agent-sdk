# MATLAB AI Agent SDK

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=matlab/matlab-ai-agent-sdk)

> [!IMPORTANT]
> This SDK is a research preview under active development and APIs may change.


MATLAB® AI Agent SDK lets you build and run AI agents in MATLAB.

•	Connect to OpenAI® or Ollama™.

•	Give agents access to MATLAB functions and toolbox workflows.

•	Create agents that reason about a goal, call MATLAB tools, and maintain state across turns.

•	Keep domain logic, validation, and workflow control in MATLAB code.

•	Run multi-step workflows in MATLAB with full control over the tools an agent can use.

•	Connect agents to tools from Model Context Protocol (MCP) servers

## Setup

You can use the add-on in MATLAB Online™ by clicking this link: [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=matlab/matlab-ai-agent-sdk)

The recommended way of using the add-on on an installed version of MATLAB is to use the Add-On Explorer.

In MATLAB, go to the Home tab, and in the Environment section, click the Add-Ons icon.
In the Add-On Explorer, search for "MATLAB AI Agent SDK".
Select Install.

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

This example shows how to create a conversation with an LLM and automatically keep track of the message history by using the `aisdk.aiAgent` function.

Create the agent from an LLM client `client` by using the `aisdk.aiAgent` function. Provide a system prompt.

```matlab
systemPrompt = "Reply as if you are writing telegrams.";
agent = aiAgent(client,systemPrompt);
```
Run the agent by using the `aisdk.run` function. Provide a prompt.

```matlab
prompt = "TOMATO FRUIT OR VEGETABLE STOP";
run(agent,prompt)
```
```
ans = 

    "TOMATO TECHNICALLY A FRUIT STOP COMMONLY USED AS VEGETABLE IN CULINARY CONTEXT STOP END OF TRANSMISSION."
```

Ask a follow up question by using the `aisdk.run` function.

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

    1    User         Text    "TOMTATO FRUIT OR VEGETABLE STOP"
    2    Assistant    Text    "TOMATO TECHNICALLY A FRUIT STOP COMMONLY USED AS VEGETABLE I..."
    3    User         Text    "HOW ABOUT AVOCADO STOP"
    4    Assistant    Text    "AVOCADO ALSO A FRUIT STOP KNOWN AS ALLIGATOR PEAR STOP HIGH ..."
```

### Create AI Agent With Tools

This example shows how to create an AI agent with a set of tools by using the `aisdk.aiAgent` function.

Create a function that counts the number of times a letter appears in a word.

```matlab
function numLetter = countLetters(word,letter)
    numLetter = length(extract(word,letter));
end
```
Create a tool from the `countLetters` function by using the `aisdk.llmTool` function. Add information about input and output arguments to the tool by using the `aisdk.llmToolArgument` function.

```matlab
tool = llmTool(@countLetters);
tool.InputArguments(1) = llmToolArgument("word",DataType="string");
tool.InputArguments(2) = llmToolArgument("letter",DataType="string");
tool.OutputArguments = llmToolArgument("numLetter",DataType="number");
```

Create the agent from an LLM client `client` by using the `aisdk.aiAgent` function. Leave the system prompt empty.

```matlab
systemPrompt = "";
agent = aiAgent(client,systemPrompt,tool);
```

Run the agent by using the `aisdk.run` function.

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

- The first input argument of the function must be a structure array. Call the argument `workspace`.

- The last output argument of the function must be the same structure array.

To allow the agent to understand the outcome of the tool call, add another output argument, observation, that contains a natural language description of the outcome of the tool call. If the call to the `eig` function is successful, then describe the outcome using the observation output argument. If the call returns an error, capture the error and return the error message as the observation string.

```matlab
function [observation,workspace] = eigTool(workspace)
% Compute the eigenvalues of a matrix
try
    workspace.eigenvalues = eig(workspace.matrix);
    observation = "Eigenvalues added to the workspace as a variable called eigenvalues.";
catch error
    observation = error;
end
end
```

Create an LLM tool from the `eigTool` function by using the `aisdk.llmTool` function. Set the `Contextual` name-value argument to `true`.

```matlab
tool = llmTool(@eigTool,Contextual=true);
```

Add information about the observation output argument to the tool. Do not add information about the workspace argument.

```matlab
tool.OutputArguments = llmToolArgument("observation",DataType="string", ...
    Description="Natural language description of outcome of function call");
```

You can now add the tool to an agent.


## Functions

| Function | Description |
|----|----|
| [AIAgent](doc/AIAgent.md) | Build AI agent | 
|[LLMClient](doc/LLMClient.md) | Connect to third-party LLM API |
| [LLMTool](doc/LLMTool.md) | Tool for AI agent |
| [LLMToolArgument](doc/LLMToolArgument.md) | Argument for LLM tool |
| [LLMMessage](doc/LLMMessage.md) | Create LLM message |
| [OpenAIClient](doc/llms/client/OpenAIClient.md) | Client for OpenAI API |
| [OllamaClient](doc/llms/client/OllamaClient.md) | Client for Ollama API |
| [LocalLLMTool](doc/llms/tool/LocalLLMTool.md) | Tool for AI agent from local function |
| [MCPTool](doc/llms/tool/MCPTool.md) | Tool for AI agent from MCP server |
| [LLMTextMessage](doc/llms/message/LLMTextMessage.md) | LLM message containing text |
| [LLMImageMessage](doc/llms/message/LLMImageMessage.md) | LLM message containing image |
| [LLMToolCallMessage](doc/llms/message/LLMToolCallMessage.md) | LLM message containing tool call |
| [LLMToolResultMessage](doc/llms/message/LLMToolResultMessage.md) | LLM message containing tool result |

## Examples

| Example                                                                              | Description                                                                                                                                                                                                                 |
| ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [CreateSimpleChatBotUsingAIAgent.m](doc/examples/CreateSimpleChatBotUsingAIAgent.m)     | Create interactive chatbot in Command Window                                                                                                                                                                                   |
| [AnalyzeTextUsingParallelToolCalls.m](doc/examples/AnalyzeTextUsingParallelToolCalls.m) | Extract structured data from text                                                                                                                                                                 |
| [FitPolynomialToDataUsingAIAgent.m](doc/examples/FitPolynomialToDataUsingAIAgent.m)     | Build AI agent that fits polynomials to data (requires Curve Fitting Toolbox™) |
| [NestedToolsAndSubagentsExample.m](doc/examples/NestedToolsAndSubagentsExample.m)       | Create tools that provide other tools                                                                                                                                                                             |
| [MCPClientAndAgentTools.m](doc/examples/MCPClientAndAgentTools.m)                       | Connect agent to Model Context Protocol (MCP) server                                                                                                                                                                   |

## License

The license is available in the [LICENSE](LICENSE) file in this GitHub repository.

## Contact

To ask questions, report issues, or request technical support, open an [Issue](../../issues).

---

*Copyright 2026 The MathWorks, Inc.*
