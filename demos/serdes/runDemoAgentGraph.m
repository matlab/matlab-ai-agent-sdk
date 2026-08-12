%% SerDes Graph Demo — Optimize CTLE Gain for Eye Height

%% ---- Setup ---------------------------------------------------------------
client = aisdk.LLMClient("openai", "gpt-4.1-mini");
allTools = createSerdesTools();
workspace = struct();

[nodes, edges] = graphConfig();
graph = agentgraph.AgentGraph(nodes, edges, Engine=agentgraph.ToposortEngine());

%% ---- Run -----------------------------------------------------------------
prompt = "On a 28 GBaud NRZ link with 5 dB channel loss and a receiver CTLE, " + ...
    "optimize the CTLE AC gain (0-15 dB) to maximize bestEH, produce the " + ...
    "final eye diagram, and report the best gain and the resulting eye height.";

fprintf('Prompt: %s\n\n', prompt);
tic;
[result, workspace] = graph.run(client, prompt, workspace, allTools);
elapsed = toc;

%% ---- Output --------------------------------------------------------------
fprintf('\n========================================\n');
fprintf(' Graph Result\n');
fprintf('========================================\n');
fprintf('%s\n', result);
fprintf('\n--- %.1f s ---\n', elapsed);
