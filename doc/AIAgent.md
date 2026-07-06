# AIAgent

Agent for AI chat completions with an agentic tool-calling loop.

## Syntax

```matlab
agent = aisdk.AIAgent(client)
agent = aisdk.AIAgent(client, Name=Value)
```

## Description

`AIAgent(client)` creates an agent that uses the specified LLM client. The agent manages conversation history and can run a multi-turn tool-calling loop.

`AIAgent(client, Name=Value)` specifies additional options using name-value arguments. You can specify any of the properties below as name-value arguments, including `SystemPrompt` and `Tools`.

The `client` argument is any object created by [`LLMClient`](../+aisdk/LLMClient.m).

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Client` | | | The LLM client used for API calls. |
| `Messages` | `aisdk.llms.message.LLMMessage` array | `[]` | Conversation history, updated automatically by `run`. |
| `ResponseFormat` | | `"text"` | Response format: `"text"`, `"json"`, `struct`, or JSON schema string. |
| `Workspace` | `struct` | `struct()` | Shared data passed into and out of tool calls. |
| `SystemPrompt` | `string` | | System prompt sent with every request. |
| `DisplayMode` | `string` | `"detailed"` | Display mode: `"off"` (silent) or `"detailed"` (print tool calls and responses to the command window). |
| `ApprovalFcn` | `function_handle` | `@aisdk.llms.internal.uiconfirm` | Callback used to prompt the user for tool call confirmation. |
| `MaxIterations` | positive numeric | `25` | Maximum tool-calling iterations per `run` call. Can be overridden per call via Name-Value argument. |
| `NumInputTokens` | numeric (read-only) | `0` | Cumulative input (prompt) tokens across all `run` calls. |
| `NumOutputTokens` | numeric (read-only) | `0` | Cumulative output (completion) tokens across all `run` calls. |
| `NumTotalTokens` | numeric (read-only) | `0` | Cumulative total tokens across all `run` calls. |
| `NumCachedInputTokens` | numeric (read-only) | `0` | Cumulative cached input tokens across all `run` calls. |


## Methods

### run

```matlab
response = run(agent, prompt)
response = run(agent, prompt, Name=Value)
```

Run the agentic loop: send `prompt` to the model, execute any tool calls the model requests, feed results back, and repeat until the model returns a text response or `MaxIterations` is reached.

**Inputs:**

| Argument | Description |
|----------|-------------|
| `prompt` | A string containing the user's question or instruction. |

**Name-Value Arguments:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `Tools` | tools created by [`LLMTool`](../+aisdk/LLMTool.m) | agent tools | Override the tools available for this run. |
| `ToolChoice` | `string` | `"auto"` | Controls which tool the model calls. Must be one of `"auto"` (model decides), `"none"` (no tool calls), `"required"` (model must call a tool), or the name of a specific tool to force (e.g., `"addNumbers"`). |
| `ResponseFormat` | | `"text"` | Override the response format for this run. `"text"`, `"json"`, `struct`, or JSON schema string. |
| `MaxIterations` | positive numeric | `25` | Maximum number of generate-then-tool-call loop iterations. When reached, a warning is issued, the message history is preserved in `agent.Messages`, and accumulated text responses are returned. |
| `DisplayMode` | `string` | agent's `DisplayMode` | Override display mode for this run. `"off"` or `"detailed"`. Does not mutate the agent property. |

**Outputs:**

| Argument | Description |
|----------|-------------|
| `response` | The final text response from the model. If the model produces multiple text messages during the agentic loop, they are concatenated with newline delimiters. |

## Examples

### Simple question-and-answer

```matlab
client = aisdk.LLMClient("openai", "gpt-4.1-mini");
agent = aisdk.AIAgent(client);
response = run(agent, "Reply with the word hello.");
disp(response)
```

### Agent with tools

```matlab
tool = aisdk.LLMTool("addNumbers", ...
    Description="Add two numbers", ...
    InputArguments=[
        aisdk.LLMToolArgument("a", DataType="number", Description="First number")
        aisdk.LLMToolArgument("b", DataType="number", Description="Second number")
    ]);

client = aisdk.LLMClient("openai", "gpt-4.1-mini");
agent = aisdk.AIAgent(client, Tools=tool);
response = run(agent, "What is 2 + 3?");
disp(response)
```

### Using Tools and ToolChoice in run

```matlab
addTool  = aisdk.LLMTool("addNumbers",      Description="Add two numbers",      InputArguments=struct("a", 0, "b", 0));
multTool = aisdk.LLMTool("multiplyNumbers", Description="Multiply two numbers", InputArguments=struct("a", 0, "b", 0));

client = aisdk.LLMClient("openai", "gpt-4.1-mini");
agent = aisdk.AIAgent(client, Tools=[addTool, multTool]);

run(agent, "What is 2+3?");                            % "auto": model picks a tool or replies directly
run(agent, "Compute 4 and 5", ToolChoice="required");  % must call a tool
run(agent, "Add 4 and 5",    ToolChoice="addNumbers"); % force a specific tool
run(agent, "What is 2+3?",   ToolChoice="none");       % no tool calls, text only
run(agent, "What is 4*5?",   Tools=multTool);           % override tools for this run
```

### Agent with workspace

Tools can read and write a shared `Workspace` struct to pass data between calls. Define a "contextual" function with two outputs — the second is the updated workspace.

```matlab
function [observation, workspace] = storeNumber(workspace, value)
    workspace.storedValue = value;
    observation = "stored!";
end
```

```matlab
storeTool = aisdk.LLMTool(@storeNumber, ...
    Description="Store a number for later use", ...
    InputArguments=aisdk.LLMToolArgument("value", DataType="number", ...
        Description="The number to store"));

workspace = struct();
client = aisdk.LLMClient("openai", "gpt-4.1-mini");
agent = aisdk.AIAgent(client, SystemPrompt="Store all the numbers the user gives you.", ...
    Tools=storeTool, Workspace=workspace);
run(agent, "The number is 42.");

agent.Workspace.storedValue   % 42
```

### Human-in-the-loop (HITL)

Tools created by `LLMTool` accept a `RequiresApproval` argument that controls whether the agent pauses for user approval before executing a tool call. The default is `"never"`.

```matlab
tool = aisdk.LLMTool(@web_search, ...
    Description="Search the web for information", ...
    InputArguments=struct("Query", "example query"), ...
    RequiresApproval="always");

client = aisdk.LLMClient("openai", "gpt-4.1-mini");
agent = aisdk.AIAgent(client, Tools=tool);
run(agent, "Search for the population of France.");
```

When the agent tries to call `web_search`, a confirmation dialog opens showing the tool name and its arguments as pretty-printed JSON. The user can approve, deny, or (when `RequiresApproval="once"`) approve all future calls to that tool.

If the user denies a tool call, the denial message is recorded as the tool result and the agent continues processing any remaining tool calls in the round. The model sees the denial in its conversation history and can adapt on subsequent rounds.

| `RequiresApproval` value | Behaviour |
|-----------------------|-----------|
| `"never"` (default)   | Tool runs immediately with no prompt. |
| `"always"`            | Agent asks for confirmation before every call to that tool. |
| `"once"`              | Agent asks for confirmation on the first call. An "Approve Always" button allows the user to skip confirmation for all subsequent calls to that tool during the run. |

The agent's `ApprovalFcn` property controls which function displays the dialog. The default is `@aisdk.llms.internal.uiconfirm`, which opens a GUI figure. You can replace it with a custom callback that has the signature `result = myCallback(tool, toolArguments)`, where `result` is a struct with fields `Approved`, `Permanent`, and `Reason`.

For a complete example, see [`AnalyzeTextUsingParallelToolCalls.m`](examples/AnalyzeTextUsingParallelToolCalls.m).

## See Also

[LLMClient](../+aisdk/LLMClient.m) | [LLMTool](../+aisdk/LLMTool.m)
