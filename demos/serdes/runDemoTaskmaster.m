%% SerDes Graph Demo (goal-driven) — taskmaster re-drives a DAG to a goal
%
% Unlike runDemoGraph.m (which runs the whole graph once, top to bottom), this
% demo puts an LLM TASKMASTER above the graph. The taskmaster has one tool,
% runToGoal(goalNode), that runs the goal node + its ancestors and returns the
% resulting metrics. The taskmaster reads those metrics and decides whether to
% re-drive (iterate the optimization) or advance the goal (e.g. on to plotting)
% -- a runtime, metric-gated decision the fixed toposort flow cannot express.
% agentgraph.createTaskmaster is domain-agnostic: it learns the graph's strategy
% from each node's Description (set in graphConfig), so nothing SerDes-specific
% is passed here -- only the user's goal, via the prompt below.

%% ---- Setup ---------------------------------------------------------------
client = aisdk.LLMClient("openai", "gpt-4.1-mini");
allTools = createSerdesTools();
workspace = struct();

[nodes, edges] = graphConfig();
graph = agentgraph.AgentGraph(nodes, edges, Observer=@agentgraph.livePlot);

taskmaster = agentgraph.createTaskmaster(client, graph, allTools, workspace);

%% ---- Run -----------------------------------------------------------------
prompt = "On a 28 GBaud NRZ link with 5 dB channel loss and a receiver CTLE, " + ...
    "optimize the CTLE AC gain (0-15 dB) to maximize bestEH, produce the " + ...
    "final eye diagram, and report the best gain and the resulting eye height.";

% Give the graph nodes the user's intent as their base prompt.
taskmaster.Workspace.agentGraphPrompt = prompt;

fprintf('Prompt: %s\n\n', prompt);
tic;
response = taskmaster.run(prompt);
elapsed = toc;

%% ---- Output --------------------------------------------------------------
fprintf('\n========================================\n');
fprintf(' Taskmaster Result\n');
fprintf('========================================\n');
fprintf('%s\n', response);

% Goal-drive trajectory.
goalLog = taskmaster.Workspace.goalLog;
fprintf('\n--- Goal-drive trajectory (%d drives) ---\n', numel(goalLog));
for i = 1:numel(goalLog)
    fprintf('  %d. goalNode=%-10s ran: %s\n', i, ...
        goalLog{i}.goalNode, strjoin(goalLog{i}.ranNodes, ", "));
end
% Token usage: taskmaster (outer) + graph nodes (inner).
tmTokens = taskmaster.NumTotalTokens;
ws = taskmaster.Workspace;
if isfield(ws, 'tokenUsage')
    nodeTokens = ws.tokenUsage.total;
else
    nodeTokens = 0;
end
fprintf('\n--- %.1f s | %d tokens (taskmaster: %d, nodes: %d) ---\n', ...
    elapsed, tmTokens + nodeTokens, tmTokens, nodeTokens);
