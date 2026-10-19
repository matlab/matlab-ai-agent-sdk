function id = newSessionId()
%newSessionId Short unique id for one agent chat session (e.g. "a3f9c1d2").
%   Returns the first 8 hex characters of a fresh UUID. Seeded once per agent
%   (see LUTOAgent.create) and stamped onto every saved contract so contracts
%   from different chat sessions can be told apart.

% Copyright 2026 The MathWorks, Inc.

    try
        raw = string(matlab.lang.internal.uuid());
    catch
        raw = string(java.util.UUID.randomUUID());
    end
    id = extractBefore(replace(raw, "-", ""), 9);   % first 8 hex chars
end
