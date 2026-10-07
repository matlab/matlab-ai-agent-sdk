# Nest Taskmasters in an Engineering Simulation

This example uses two graphs and one nested taskmaster. The arithmetic models a
spring under load; no engineering toolbox or external solver is required.

```text
outerRouter -> outerGraph
  runSimulation (AgentNode holding innerRouter) -> reportResult (FunctionNode)
    innerRouter -> innerGraph
      configureModel -> solveModel -> checkResult
```

The outer router selects `reportResult`, which depends on `runSimulation`.
That node's inner router selects `checkResult`, whose prerequisites configure
and solve the model. The functions use a fixed 8 N load and 4 N/mm stiffness,
giving 2 mm displacement against a 3 mm limit. `reportResult` reads the
checked result from the shared workspace.

From the repository root, run:

```matlab
run agentGallery/taskmaster/examples/nesting/runNestedSimulation.m
```

The script prints the response and the nodes that ran at each graph level.
The inner trace lives at `outer.runSimulation` in the taskmaster workspace.
See [Run and rerun](../../README.md#run-and-rerun) for cache behavior.
