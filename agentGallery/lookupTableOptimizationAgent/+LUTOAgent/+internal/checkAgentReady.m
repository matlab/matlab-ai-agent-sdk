function [ok, reason] = checkAgentReady(agent)
%checkAgentReady Probe that the Agent SDK backend is reachable and authenticated.
%   [OK, REASON] = LUTOAgent.internal.checkAgentReady(AGENT) sends a tiny
%   throwaway request through the agent's LLM client. OK is true when the
%   backend answers successfully; otherwise OK is false and REASON is a
%   human-readable explanation (including hints for the common failure modes:
%   a missing API key or an unreachable endpoint).
%
%   This is provider-agnostic: it exercises the same generate() path the chat
%   loop uses, so it catches auth, endpoint, and connectivity problems for
%   openai and ollama alike, rather than only checking one env var.

% Copyright 2026 The MathWorks, Inc.

    client = agent.Client;
    provider = string(client.API);
    keyVar = upper(provider) + "_API_KEY";

    try
        % Minimal, cheap round-trip. A tiny token budget keeps it fast/cheap;
        % we only care that the backend accepts the request and replies.
        generate(client, "Reply with the single word: ok", MaxNumTokens=32);
        ok = true;
        reason = "";
    catch ME
        ok = false;
        reason = diagnose(ME, provider, keyVar);
    end
end

function reason = diagnose(ME, provider, keyVar)
    msg = string(ME.message);

    keyMissing = (provider ~= "ollama") && strlength(getenv(keyVar)) == 0;
    isAuth = contains(msg, "unauthorized", IgnoreCase=true) || ...
             contains(msg, "keyMustBeSpecified", IgnoreCase=true) || ...
             contains(ME.identifier, "keyMustBeSpecified");

    if keyMissing || isAuth
        reason = sprintf( ...
            "Could not authenticate with the '%s' backend. " + ...
            "Set the %s environment variable, e.g.:" + newline + ...
            "    setenv(""%s"", ""<your-key>"")" + newline + ...
            "        or use Ollama: "+ newline + ...
            "    LUTOAgent.chat(LUTOAgent.create(Provider=""ollama""))" + newline + ...
            "        then start the agent again.", ...
            provider, keyVar, keyVar);
    else
        reason = sprintf( ...
            "Could not reach the '%s' backend. Check your network/installation " + ...
            "and try again. (Underlying error: %s)", provider, msg);
    end
end
