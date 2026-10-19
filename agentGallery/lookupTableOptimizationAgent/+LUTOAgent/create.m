function agent = create(opts)
%LUTOAgent.create Build the lookup-table optimization agent.
%   AGENT = LUTOAgent.create() returns a configured aisdk.AIAgent that helps
%   the user set up, solve, and apply FunctionApproximation LUT problems.
%
%   AGENT = LUTOAgent.create(Name=Value) options:
%     Provider        - "openai" (default) or "ollama"
%     Model           - model name (default "gpt-4.1-mini" for openai)
%     DisplayMode     - "detailed" (default, shows the tool-call trace) or "off"
%     ReasoningEffort - reasoning/"thinking" level for reasoning models:
%                       "auto" (default), "none", "low", "medium", "high", or
%                       "xhigh". Use "none" to suppress verbose thinking. The
%                       default "auto" sends nothing to the backend, so plain
%                       (non-reasoning) models like gpt-4.1-mini accept it; set
%                       a level explicitly only when using a reasoning model.
%
%   The agent's FunctionApproximation domain knowledge is embedded in the
%   system prompt (see LUTOAgent.systemPrompt), so no external skill file is
%   required.
%
%   Use run(agent, "your request") to interact programmatically, or call
%   LUTOAgent.chat to start an interactive command-window session.

% Copyright 2026 The MathWorks, Inc.

    arguments
        opts.Provider (1,1) string {mustBeMember(opts.Provider, ["openai","ollama"])} = "openai"
        opts.Model (1,1) string = ""
        opts.DisplayMode (1,1) string {mustBeMember(opts.DisplayMode, ["detailed","off"])} = "detailed"
        opts.ReasoningEffort (1,1) string {mustBeMember(opts.ReasoningEffort, ...
            ["auto","none","low","medium","high","xhigh"])} = "auto"
    end

    if strlength(opts.Model) == 0
        switch opts.Provider
            case "openai"; opts.Model = "gpt-4.1-mini";
            otherwise;     opts.Model = "mistral";
        end
    end

    % ReasoningEffort is accepted by the OpenAI client; the Ollama client
    % rejects it as an unknown name-value argument. Only forward it for
    % providers that accept it.
    if opts.Provider == "openai"
        client = aisdk.LLMClient(opts.Provider, opts.Model, ReasoningEffort=opts.ReasoningEffort);
    else
        if opts.ReasoningEffort ~= "auto"
            warning("LUTOAgent:create:ReasoningEffortIgnored", ...
                "ReasoningEffort is not supported by the '%s' provider and will be ignored.", ...
                opts.Provider);
        end
        client = aisdk.LLMClient(opts.Provider, opts.Model);
    end
    tools = LUTOAgent.buildTools();
    sysPrompt = LUTOAgent.systemPrompt();

    % Seed a per-session id so saved contracts can be attributed to (and
    % compared across) chat sessions. This top-level workspace field survives
    % defineProblem, which only resets workspace.contract.
    agent = aisdk.AIAgent(client, ...
        SystemPrompt=sysPrompt, ...
        Tools=tools, ...
        Workspace=struct("sessionId", LUTOAgent.internal.newSessionId()), ...
        DisplayMode=opts.DisplayMode, ...
        ApprovalFcn=@LUTOAgent.cliApproval);
end
