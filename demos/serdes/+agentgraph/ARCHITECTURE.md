# `+agentgraph` — Architecture Reference

> Source of truth for the domain-agnostic graph framework in `+agentgraph/`.
> The SerDes demo wires this framework in `graphConfig.m` and `runDemoTaskmaster.m`.

---

## 1. What this package is

`+agentgraph` runs a **multi-agent, graph-structured** workflow. A user prompt
is executed by walking a directed acyclic graph of nodes. Each node is either an
LLM agent with a focused tool subset (`AgentNode`) or a deterministic function
(`FunctionNode`). An optional **taskmaster** sits above the graph and picks which
goal node to drive, reading metrics between iterations.

The framework is **domain-agnostic** — it knows nothing about SerDes. All domain
knowledge comes from:
- Node definitions in `graphConfig.m` (tools, prompts, descriptions)
- Tool factory (`createSerdesTools.m`, auto-discovers `tools/*.m`)
- The workspace struct threaded through execution

---

## 2. Class hierarchy

```
agentgraph.Node              (abstract: Name, Description, execute)
  ├── agentgraph.AgentNode   (LLM agent with sliced tool subset)
  └── agentgraph.FunctionNode (deterministic function handle, no LLM)

agentgraph.Engine            (abstract: traverse strategy)
  └── agentgraph.ToposortEngine (DAG guard → toposort → sequential run-loop)

agentgraph.AgentGraph        (graph data + run delegation to Engine)
```

---

## 3. Key files

| File | Responsibility |
|------|----------------|
| `AgentGraph.m` | Graph data (nodes, edges) + stateless helpers (`getNode`, `dependencyString`, `describeNodes`, `buildNodePrompt`, `executionOrder`). `run()` delegates to its `Engine`. |
| `Engine.m` | Abstract traversal strategy: `traverse(graph, prompt, workspace, allTools, client)`. |
| `ToposortEngine.m` | Default engine: `digraph → DAG guard → toposort → run-loop`; optional `GoalNode` for partial traversal (goal + ancestors only). |
| `Node.m` | Abstract node base: `Name`, `Description`, `execute(...)` contract. |
| `AgentNode.m` | LLM node. Slices global tools to its declared subset, spawns a fresh `AIAgent`, runs it. Calls observer hooks (`nodeRunning`, `nodeDone`, `nodeError`) with `drawnow` for live UI. |
| `FunctionNode.m` | Deterministic node — a function handle, no LLM. |
| `createTaskmaster.m` | Factory: builds an `AIAgent` with a single `runToGoal(goalNode)` tool. Domain-agnostic; learns graph strategy from each node's `Description`. |
| `GraphObserver.m` | Abstract handle class defining the observer interface (7 methods: `nodeRunning`, `nodeDone`, `nodeError`, `toolStarted`, `toolResult`, `agentDecision`, `routerDecision`). |
| `livePlot.m` | Minimal live visualizer: returns a duck-typed observer struct with function-handle fields. Uses `uifigure` + `uihtml` with inline SVG. |

---

## 4. Two execution modes

### Fixed-flow (`runDemoAgentGraph.m`)

`AgentGraph.run()` → `ToposortEngine` runs every node in topo order, once.
No decisions at runtime.

### Goal-driven (`runDemoTaskmaster.m`)

An LLM taskmaster wraps the graph. Its single tool `runToGoal(goalNode)` calls
`graph.run(..., GoalNode=goalNode)` which runs only that node + its ancestors.
The taskmaster reads the resulting observation, decides whether to re-drive
(iterate optimization) or advance to a later goal. This is a runtime,
metric-gated decision the fixed toposort cannot express.

---

## 5. Prompt management

System prompts live in `demos/serdes/prompts/*.md`:

| File | Node |
|------|------|
| `build.md` | build |
| `analyse.md` | analyse |
| `optimize.md` | optimize |
| `plot.md` | plot |
| `taskmaster.md` | taskmaster (template: `{{nodeRoles}}` replaced at runtime) |

`graphConfig.m` loads these via `fileread`. The taskmaster prompt is loaded in
`createTaskmaster.m` with the `{{nodeRoles}}` placeholder replaced by the
graph's actual node descriptions.

---

## 6. Observer protocol

The formal interface is `agentgraph.GraphObserver` (abstract handle class):

```matlab
observer.nodeRunning(nodeName)
observer.nodeDone(nodeName, result)
observer.nodeError(nodeName, err)
observer.toolStarted(nodeName, toolName, inputText)
observer.toolResult(nodeName, toolName, isError, outputText)
observer.agentDecision(nodeName, text)
observer.routerDecision(fromName, chosenName, reason)
```

`livePlot.m` returns a duck-typed struct with function-handle fields implementing
a subset of this interface. Both approaches work — nodes call methods on whatever
`graph.Observer` is set to. `drawnow` is called after each hook in `AgentNode`
to flush UI events before re-entering blocking LLM calls.

The `Observer` NVP on the `AgentGraph` constructor accepts either a pre-built
observer or a function handle that takes the graph and returns an observer:

```matlab
graph = agentgraph.AgentGraph(nodes, edges, Observer=@agentgraph.livePlot);
```

---

## 7. Tool auto-detection

`createSerdesTools.m` auto-discovers all `.m` files in `tools/` and registers
each as an `aisdk.LLMTool` using the SDK's introspection: the function's H1 line
becomes the `Description` and its `arguments` block becomes `InputArguments`.
Tools that fail schema conversion are skipped with a warning.

---

*Copyright 2026 The MathWorks, Inc.*
