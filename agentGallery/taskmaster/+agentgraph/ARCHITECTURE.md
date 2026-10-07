# Agent graph architecture

> **Naming note:** The `+agentgraph` package and `AgentGraph` class are due to be renamed. The names in this document reflect the current API.

`AgentGraph` is a named DAG of `Node` objects. It executes a whole
graph or a target node and its ancestors. A direct call uses the graph without a
router:

```matlab
[result, workspace] = graph.traverse(request, workspace, TargetNode="measure");
```

Each node runs once in dependency order and receives the same workspace struct.
`FunctionNode` executes a tool object or a function handle. `AgentNode` runs a
configured `aisdk.AIAgent`; its `ClearHistory` setting controls whether messages
are restored before each node execution.

## Routing and nesting

`agentgraph.taskmaster(graph, client, ...)` returns an ordinary `aisdk.AIAgent`.
Its `runToTargetNode(TargetNode=...)` tool is built by `graph.asTool()` and lists
the graph's node descriptions. A target drive executes that node and its
ancestors, reusing cached results when available. The router may also have
ordinary tools. Its latest user request is passed to the graph when it calls
the graph tool.

```matlab
inner = agentgraph.AgentGraph(nodes, edges, Name="inner");
router = agentgraph.taskmaster(inner, client);
```

For a standalone route, call `router.run(request)` and read
`router.Workspace`. Alternatively, put that router in an `AgentNode` in an
outer graph. Here `report` runs after `analyse` and reads what the inner graph
recorded in the workspace:

```matlab
analyse = agentgraph.AgentNode("analyse", router, ...
    Description="Run the inner analysis", ClearHistory=false);
report = agentgraph.FunctionNode("report", @reportAnalysis, ...
    Description="Report which analysis nodes completed");
outer = agentgraph.AgentGraph([analyse, report], ...
    ["analyse", "report"], Name="outer");
top = agentgraph.taskmaster(outer, client);
response = top.run(request);
workspace = top.Workspace;

function [result, workspace] = reportAnalysis(workspace)
    completed = agentgraph.utils.nodeTrace(workspace, "outer.analyse");
    if isempty(completed)
        result = "No analysis nodes ran.";
    else
        result = "Analysis nodes completed: " + join(completed, ", ");
    end
end
```

The `analyse` node binds a copy of the graph tool to its owning workspace path
during execution. The original tool remains bound to `inner` for a direct
router run. The `analyse -> report` edge sets their order; `reportAnalysis`
receives the workspace, not `analyse`'s return value directly.
The graph tool and its bound path are implementation details; the public setup
is the factory, `AgentNode`, and `AgentGraph`.

## Workspace and cache

The workspace is the persisted graph state. Records live under
`workspace.agentgraph`: a direct graph traversal uses its `Name`, while a nested
drive uses its owning node path, such as `outer.analyse`. Each record stores the
graph name and can store the driven request, completed node trace, and cached
node results. Other
workspace fields belong to application tools. Token usage from graph nodes
accumulates in `workspace.tokenUsage`.

`graph.clearCache(workspace)` removes that named graph's immediate cache layer
at every occurrence in the workspace. `Node="B"` clears B and its downstream
nodes at that layer. Enclosing and nested layers remain intact. Direct
`graph.traverse(...)` executes selected nodes even when the workspace holds cached
results; target drives through the graph tool reuse them.

Use the read-only public helpers to inspect a workspace:

```matlab
levels = agentgraph.utils.graphLevels(workspace);
trace = agentgraph.utils.nodeTrace(workspace, "outer.analyse");
tokens = agentgraph.utils.totalTokens(top);
```

`totalTokens(top)` adds the top router's own tokens to those recorded in its
workspace. `totalTokens(workspace)` returns only the workspace total. Do not
pass a nested `AgentNode`'s agent to this helper, because its tokens are already
included in the workspace.

## Files

| File | Responsibility |
| --- | --- |
| `AgentGraph.m` | Graph definition, topological traversal, target tool, cache clearing |
| `Node.m`, `FunctionNode.m`, `AgentNode.m` | Node execution contracts |
| `taskmaster.m` | Construct and connect a router agent |
| `+internal/GraphTargetTool.m` | Target selection tool and bound workspace path |
| `+internal/Workspace.m` | Workspace record layout and cache access |
| `+utils/` | Public workspace inspection helpers |

*Copyright 2026 The MathWorks, Inc.*
