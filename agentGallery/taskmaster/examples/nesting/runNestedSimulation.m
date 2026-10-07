%% Nested taskmasters: a small engineering simulation
%
% The outer router drives an outer graph. Its runSimulation node holds an
% inner router, which drives a graph that configures, solves, and checks a
% simple spring model. The arithmetic is fixed so the nesting stays visible.

% Copyright 2026 The MathWorks, Inc.

here = fileparts(mfilename("fullpath"));
addpath(here, fullfile(here, "..", ".."));

client = aisdk.LLMClient("openai", "gpt-4.1-mini");
[outerNodes, outerEdges] = simulationGraphDefinition(client);
outerGraph = agentgraph.AgentGraph(outerNodes, outerEdges, Name="outer");
outerRouter = agentgraph.taskmaster(outerGraph, client, ...
    SystemPrompt=string(fileread(fullfile(here, "prompts", "outer.md"))));

request = "Run the spring simulation, check the displacement limit, and report the result.";
response = outerRouter.run(request);
workspace = outerRouter.Workspace;

fprintf("\n%s\n", response);
fprintf("Outer nodes: %s\n", join(agentgraph.utils.nodeTrace(workspace, "outer"), " -> "));
fprintf("Inner nodes: %s\n", join(agentgraph.utils.nodeTrace(workspace, "outer.runSimulation"), " -> "));
fprintf("Displacement: %.1f mm; limit: %.1f mm; passed: %d\n", ...
    workspace.displacementMm, workspace.limitMm, workspace.passed);
