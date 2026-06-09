# MATLAB&reg; AI Agent SDK

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=matlab/matlab-ai-agent-sdk)

Build AI agents in MATLAB, call tools from Toolboxes, and connect to OpenAI&reg; and Ollama&trade;.

**Why use this SDK?** Build LLM agents with tool-calling by defining tools as ordinary MATLAB functions and attaching them to an agent. Manage conversation state, tool dispatch, and run multi-turn interactions in a few lines of code.

## Research Preview

This SDK is a Research Preview under active development and APIs may change.

Please leave feedback, report bugs and feature requests via [Issues](../../issues). We review all contributions, but we do not merge external pull requests. See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Getting Started

Create a client using either OpenAI or Ollama:

```matlab
client = aisdk.LLMClient("openai", "gpt-4.1-mini");
% or
client = aisdk.LLMClient("ollama", "<model-name>");
```

Then use the same workflow for both — generate a single response:

```matlab
text = generate(client, "Why is the sky blue?");
disp(text)
```

Or create an agent for multi-turn conversations with tools:

```matlab
addTool = aisdk.LLMTool(@addTwoNumbers, Description="Add two numbers");
agent = aisdk.AIAgent(client, "You are a helpful assistant.", addTool);
text = run(agent, "What is 2 + 3?");
disp(text)
```

See [Persisting Data Between Tool Calls](#persisting-data-between-tool-calls) for the full pattern.

## Persisting Data Between Tool Calls

Give an agent access to MATLAB functions so it can compute, store, and retrieve data during a conversation. The agent passes data between tools via a shared workspace struct.

```matlab
function [observation, workspace] = storeNumber(workspace, value)
    workspace.storedValue = value;
    observation = "Stored " + value + ".";
end

storeTool = aisdk.LLMTool(@storeNumber, ...
    Description="Store a number for later use", ...
    InputArguments=struct("value", 0));

client = aisdk.LLMClient("openai", "gpt-4.1-mini");
agent = aisdk.AIAgent(client, "Store the number the user gives you.", ...
    storeTool, Workspace=struct());
run(agent, "The number is 42.");

agent.Workspace.storedValue   % 42
```

See the API reference: [AIAgent](doc/AIAgent.md) | [LLMClient](doc/LLMClient.md) | [LLMTool](doc/LLMTool.md) | [LLMToolArgument](doc/LLMToolArgument.md) | [LLMMessage](doc/LLMMessage.md) | [OpenAIClient](doc/llms/client/OpenAIClient.md) | [OllamaClient](doc/llms/client/OllamaClient.md) | [LocalLLMTool](doc/llms/tool/LocalLLMTool.md) | [MCPTool](doc/llms/tool/MCPTool.md) | [LLMTextMessage](doc/llms/message/LLMTextMessage.md) | [LLMImageMessage](doc/llms/message/LLMImageMessage.md) | [LLMToolCallMessage](doc/llms/message/LLMToolCallMessage.md) | [LLMToolResultMessage](doc/llms/message/LLMToolResultMessage.md)

## Setup

### OpenAI

Using the OpenAI API requires an OpenAI API key. For information on how to obtain one, as well as pricing, terms and conditions of use, and available models, see the [OpenAI documentation](https://platform.openai.com/docs/overview).

Set your key as an environment variable in a `.env` file:

```
OPENAI_API_KEY=<your key>
```

Then load it in MATLAB:

```matlab
loadenv(".env")
```

### Ollama

Connect to [Ollama](https://ollama.com/) models locally or on a remote server. Connecting requires an installed version of Ollama, as well as installed versions of the models you want to use.

## Examples

| Example                                                                              | Description                                                                                                                                                                                                                 |
| ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [CreateSimpleChatBotUsingAIAgent.m](doc/examples/CreateSimpleChatBotUsingAIAgent.m)     | Interactive chatbot in the Command Window                                                                                                                                                                                   |
| [AnalyzeTextUsingParallelToolCalls.m](doc/examples/AnalyzeTextUsingParallelToolCalls.m) | Extract structured data from text using parallel tool calls                                                                                                                                                                 |
| [FitPolynomialToDataUsingAIAgent.m](doc/examples/FitPolynomialToDataUsingAIAgent.m)     | AI agent that fits polynomials to data (requires Curve Fitting Toolbox&trade;; based on [this example](https://github.com/matlab-deep-learning/llms-with-matlab/blob/main/examples/FitPolynomialToDataUsingAIAgentExample.md)) |
| [NestedToolsAndSubagentsExample.m](doc/examples/NestedToolsAndSubagentsExample.m)       | Tools that provide other tools (nested pattern)                                                                                                                                                                             |
| [SimpleMathAgent.m](doc/examples/SimpleMathAgent.m)                                     | Solve a quadratic equation using an agent with mathematical tools                                                                                                                                                           |
| [SendImageMessagesToVisionModels.m](doc/examples/SendImageMessagesToVisionModels.m)     | Send images to vision-capable models                                                                                                                                                                                        |
| [SupervisorSubagentExample.m](doc/examples/SupervisorSubagentExample.m)                 | Supervisor-subagent orchestration pattern                                                                                                                                                                                   |
| [MCPClientAndAgentTools.m](doc/examples/MCPClientAndAgentTools.m)                       | Connect an agent to a Model Context Protocol (MCP) server                                                                                                                                                                   |

## License

See [LICENSE](LICENSE) for details.

## Contact

For questions or support, please open an [Issue](../../issues).

---

Copyright 2026 The MathWorks, Inc.
