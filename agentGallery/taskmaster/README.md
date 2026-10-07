# Orchestrate Graph-Based Workflows with Taskmaster Agent

> **Naming note:** The `+agentgraph` package and `AgentGraph` class are due to be renamed. The names below reflect the current API.

Taskmaster is a custom graph-based agent architecture built with the AI Agent SDK. A taskmaster is an `aisdk.AIAgent` configured to route a request through an `AgentGraph`. The router selects a target node, and the graph runs that node and its prerequisites in dependency order. An agent at a node can still decide which of its tools to call, so the graph controls stage order without making agent decisions reproducible.

Graphs can contain `AgentNode` and `FunctionNode` steps. See the [architecture guide](+agentgraph/ARCHITECTURE.md) for the graph and workspace model.

## Requirements

- MATLAB R2025a or later.
- The AI Agent SDK (`+aisdk` on the MATLAB path) and access to an LLM endpoint.

The [SerDes example](examples/serdes/README.md) has additional toolbox requirements.

## Setup

From the repository root, add the taskmaster package parent to the MATLAB path:

```matlab
addpath("agentGallery/taskmaster")
```

For the OpenAI examples, set `OPENAI_API_KEY` in the environment or in a `.env` file on the MATLAB path. You can use another provider by changing the `aisdk.LLMClient` constructor in an example script.

## Create a taskmaster

Give the graph a name and give each routable node a description. The taskmaster factory returns an `aisdk.AIAgent`, so it uses the normal `run` and `Workspace` API:

```matlab
prepare = agentgraph.FunctionNode("prepare", ...
    @(workspace) deal("Prepared", workspace), ...
    Description="Prepare the input");
measure = agentgraph.FunctionNode("measure", ...
    @(workspace) deal("Measured", workspace), ...
    Description="Measure the prepared input");

graph = agentgraph.AgentGraph([prepare, measure], ...
    ["prepare", "measure"], Name="example");
client = aisdk.LLMClient("openai", "gpt-4.1-mini");
top = agentgraph.taskmaster(graph, client);

response = top.run("Measure the input.");
workspace = top.Workspace;
```

The router offers `runToTargetNode(TargetNode=...)` to the model. If it selects `measure`, the graph runs `prepare` first. The function nodes above are small placeholders; the examples below show agents and tools in larger workflows.

## Nest taskmasters

To route through multiple graph levels, put a taskmaster in an `AgentNode` of an outer graph. See the [nested graphs example](examples/nesting/README.md) for a walkthrough.

## Run and rerun

When the router drives a graph, completed node results are cached in the agent workspace. A later drive can reuse them. Changing the prompt or application data does not automatically invalidate the cache. Clear affected results before asking the router to redo work:

```matlab
workspace = graph.clearCache(top.Workspace, Node="measure");
top.Workspace = workspace;
response = top.run("Measure the input again.");
```

`Node="measure"` clears that node and its downstream nodes at this graph level. `graph.clearCache(top.Workspace)` clears all cached nodes for every occurrence of that named graph in the workspace. Inner graphs keep their own caches; clear those with their own graph objects. Cache clearing leaves prompts, node traces, application data, and router conversation intact.

A direct `graph.traverse(...)` call executes the selected nodes without reading or writing this routed cache. The router is prompted to drive at most once per user request; a follow-up drive starts with another `top.run(...)` call.

## Examples

| Example | What it shows |
| --- | --- |
| [SerDes equalization](examples/serdes/README.md) | A flat agent and a taskmaster over a SerDes workflow. |
| [Nested simulation](examples/nesting/README.md) | Two graph levels, each with a router. |

## See also

[Architecture](+agentgraph/ARCHITECTURE.md) · [aisdk.AIAgent](../../+aisdk/AIAgent.m) · [aisdk.LLMClient](../../+aisdk/LLMClient.m)

*Copyright 2026 The MathWorks, Inc.*
