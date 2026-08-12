%% SerDes Flat Agent Demo — Optimize CTLE Gain for Eye Height
%
%  A single AIAgent with the full tool set figures out the workflow on its own.
%
%  Run: open in MATLAB and press F5, or:
%    matlab -batch "run('demos/serdes/runDemoFlatAgent.m')"

%% ---- Setup ---------------------------------------------------------------
client = aisdk.LLMClient("openai", "gpt-4.1-mini");
allTools = createSerdesTools();
workspace = struct();

promptDir = fullfile(fileparts(mfilename('fullpath')), "prompts");
systemPrompt = string(fileread(fullfile(promptDir, "agent.md")));

agent = aisdk.AIAgent(client, ...
    SystemPrompt  = systemPrompt, ...
    Tools         = allTools, ...
    Workspace     = workspace, ...
    DisplayMode   = "detailed", ...
    MaxIterations = 30);

%% ---- Run -----------------------------------------------------------------
prompt = "On a 28 GBaud NRZ link with 5 dB channel loss and a receiver CTLE, " + ...
    "optimize the CTLE AC gain (0-15 dB) to maximize bestEH, produce the " + ...
    "final eye diagram, and report the best gain and the resulting eye height.";

fprintf('Prompt: %s\n\n', prompt);
tic;
response = agent.run(prompt);
elapsed = toc;

%% ---- Output --------------------------------------------------------------
fprintf('\n========================================\n');
fprintf(' Agent Response\n');
fprintf('========================================\n');
fprintf('%s\n', response);
fprintf('\n--- %.1f s | %d tokens | %d messages ---\n', ...
    elapsed, agent.NumTotalTokens, numel(agent.Messages));
