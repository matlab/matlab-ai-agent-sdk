function prompt = systemPrompt()
%systemPrompt System prompt for the LUTO (lookup-table optimization) agent.
%   PROMPT = LUTOAgent.systemPrompt() reads the prompt text from
%   systemPrompt.md, which sits next to this function. Edit the markdown file to
%   change the agent's instructions or embedded domain knowledge.

% Copyright 2026 The MathWorks, Inc.

    promptFile = fullfile(fileparts(mfilename("fullpath")), "systemPrompt.md");
    if ~isfile(promptFile)
        error("LUTOAgent:systemPrompt:FileNotFound", ...
            "System prompt file not found: %s", promptFile);
    end

    % Normalize CRLF so the prompt is identical regardless of how the file was
    % checked out.
    prompt = strip(replace(string(fileread(promptFile)), sprintf("\r\n"), newline));
end
