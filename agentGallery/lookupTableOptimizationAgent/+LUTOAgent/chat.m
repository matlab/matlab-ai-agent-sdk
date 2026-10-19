function agent = chat(agent)
%LUTOAgent.chat Start an interactive LUT-optimization chat in the Command Window.
%   LUTOAgent.chat() creates a fresh agent and starts the chat loop.
%   LUTOAgent.chat(AGENT) reuses an existing agent (keeps history/state).
%   AGENT = LUTOAgent.chat(...) returns the agent so you can inspect its
%   Workspace, Messages, or token counts afterward.
%
%   Type "exit", "quit", or "end" to leave the chat (Ctrl+C also works).

% Copyright 2026 The MathWorks, Inc.

    arguments
        agent = LUTOAgent.create();
    end

    % Confirm the Agent SDK backend is actually working before starting the
    % loop, so the user gets clear guidance instead of an opaque error on
    % their first message. This probes the live generate() path, so it catches
    % missing keys, bad endpoints, and connectivity issues across providers.
    fprintf("\n[LUTO Agent] Checking Agent SDK connection...\n");
    [ok, reason] = LUTOAgent.internal.checkAgentReady(agent);
    if ~ok
        fprintf("[LUTO Agent] %s\n", reason);
        return
    end

    fprintf("\n");
    fprintf("===============================================================\n");
    fprintf(" LUTO Agent - Lookup Table Optimization AI Agent\n");
    fprintf(" Describe a function or Simulink block to approximate with a lookup table.\n");
    fprintf(" Type 'exit' or 'quit' to close the chat session\n");
    fprintf("===============================================================\n");

    stopWords = ["exit","quit","end"];
    while true
        query = string(input("\nYou: ", "s"));
        if strlength(strtrim(query)) == 0
            continue
        end
        if ismember(lower(strtrim(query)), stopWords)
            fprintf("LUTO: Session ended. Goodbye!\n");
            break
        end

        try
            response = run(agent, query);
            fprintf("\nLUTO: %s\n", response);
        catch ME
            fprintf("\n[LUTO error] %s\n", ME.message);
            fprintf("You can rephrase your request or type 'exit' to quit.\n");
        end
    end
end
