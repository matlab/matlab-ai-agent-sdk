%% SerDes Graph Demo (goal-driven) — a taskmaster routes into the DAG
%
% This demo puts an LLM TASKMASTER above the graph. The taskmaster has one tool,
% runToTargetNode(TargetNode=...), which runs the target and its ancestors and returns the
% resulting metrics. It decides at runtime which stage the request actually needs
% -- or answers a question without running anything at all.
%
% agentgraph.taskmaster is domain-agnostic: its graph tool lists each node's role
% from its Description (set in rxSignoffGraphDefinition). To nest a router,
% place it in an AgentNode; see examples/nesting.

% Copyright 2026 The MathWorks, Inc.

%% ---- Setup ---------------------------------------------------------------
% Put this example folder and the +agentgraph package (two levels up) on the
% path, so the script runs from any working folder.
here = fileparts(mfilename("fullpath"));
addpath(here, fullfile(here, "..", ".."));

client = aisdk.LLMClient("openai", "gpt-4.1-mini");
allTools = createSerdesTools();
% Callers may pre-load a measured channel or configured system here.
workspace = struct();

[nodes, edges] = rxSignoffGraphDefinition(allTools, client);
graph = agentgraph.AgentGraph(nodes, edges, Name="rxSignoff", ...
    Observer=@agentgraph.livePlot);

% Zero-config: the routing prompt is the package default.
top = agentgraph.taskmaster(graph, client, Workspace=workspace);

%% ---- Run -----------------------------------------------------------------
prompt = "On a 28 GBaud NRZ link with 5 dB channel loss and a receiver CTLE, " + ...
    "optimize the CTLE AC gain (0-15 dB) to maximize bestEH, produce the " + ...
    "final eye diagram, and report the best gain and the resulting eye height.";

fprintf('Prompt: %s\n\n', prompt);
tic;
response = top.run(prompt);
workspace = top.Workspace;
elapsed = toc;

%% ---- Output --------------------------------------------------------------
fprintf('\n========================================\n');
fprintf(' Taskmaster Result\n');
fprintf('========================================\n');
fprintf('%s\n', response);

% What actually ran, in run order, as recorded by the engine. Nothing ran if the
% taskmaster answered the request as a question.
trace = agentgraph.utils.nodeTrace(workspace, "rxSignoff");
if ~isempty(trace)
    fprintf('\n--- Nodes run ---\n  %s\n', ...
        strjoin(trace, " -> "));
else
    fprintf('\n--- No drive: answered directly ---\n');
end

% The public helper adds the top router's tokens to all graph-node tokens.
fprintf('\n--- %.1f s | %d tokens ---\n', ...
    elapsed, agentgraph.utils.totalTokens(top));
