function [observation, workspace] = saveContract(workspace, filePath)
%saveContract Persist the current setup — source, bounds, data types, and solver options as supplied — to the session's JSON contract in a ".luto-agent" folder in the current working directory, embedding result metrics and saving the live solution to a .mat sidecar when a solution exists. Each chat session writes ONE aggregated file, "luto-agent-<sessionId>.json", holding an array of entries (each with its own entryId, timestamp, config, and optional results): a before-solve save creates a config-only entry, the following after-solve save fills that entry's results in place, and a save after the configuration changed appends a new entry. Omit filePath to use the session file; pass one only to override.
%   Aggregates the whole chat session into a SINGLE JSON "contract" file named
%   "luto-agent-<sessionId>.json". Each call adds an entry capturing the source,
%   bounds, data types, and solver options exactly as supplied; if a solution
%   exists, an outcome-metrics block is embedded under "results" and the live
%   LUTSolution object(s) are saved to a binary .mat sidecar (same base name)
%   so loadContract can restore them without re-solving.
%
%   Repeated saves update-in-place or append:
%     - If the latest entry has the same configuration and no results yet (the
%       typical before-solve then after-solve pattern), the results are filled
%       into that entry rather than adding a duplicate.
%     - Otherwise (the configuration changed, or the latest entry already has
%       results), a new entry with a fresh entryId is appended.
%
%   Contracts are stored in a ".luto-agent" folder in the current working
%   directory. If FILEPATH is omitted, the session file is used; pass a name to
%   choose the file, or an explicit folder to override.

% Copyright 2026 The MathWorks, Inc.

    arguments
        workspace
        filePath (1,1) string = ""
    end

    if ~isfield(workspace, "contract")
        observation = "No problem configured yet. Call defineProblem (and " + ...
            "optionally configureProblem) before saving a contract.";
        return
    end

    % Lazy-seed the session id so this works even when the workspace has no
    % session id, e.g. an agent driven programmatically via run().
    if ~isfield(workspace, "sessionId") || strlength(workspace.sessionId) == 0
        workspace.sessionId = LUTOAgent.internal.newSessionId();
    end

    stampISO = string(datetime("now"), "yyyy-MM-dd HH:mm:ss");

    if strlength(filePath) == 0
        filePath = "luto-agent-" + workspace.sessionId + ".json";
    end
    filePath = LUTOAgent.internal.contractPath(filePath, true);

    % --- Session-level log kept on the workspace so both files are rewritten
    %     whole on every save (no read-merge within a session). ---
    if ~isfield(workspace, "contractLog") || isempty(workspace.contractLog)
        workspace.contractLog = emptyEntry();       % 0x0 struct with entry fields
        workspace.contractSolutions = struct();     % keyed e<id> -> live solutions
        workspace.contractCreated = stampISO;
        workspace.nextEntryId = 1;
    end

    config = workspace.contract;
    hasSolution = isfield(workspace, "activeSolution");
    if hasSolution
        results = LUTOAgent.internal.solutionSnapshot(workspace.activeSolution);
    end

    log = workspace.contractLog;
    updatedInPlace = false;
    if ~isempty(log)
        last = log(end);
        sameConfig = isequal(last.config, config);
        lastHasResults = isfield(last, "results") && ~isempty(last.results);
        if sameConfig && ~lastHasResults
            updatedInPlace = true;
        end
    end

    if updatedInPlace
        entryId = log(end).entryId;
        log(end).timestamp = stampISO;
        if hasSolution
            log(end).results = results;
        end
    else
        entryId = workspace.nextEntryId;
        workspace.nextEntryId = entryId + 1;
        newE = emptyEntry();
        newE(1).entryId = entryId;
        newE.timestamp = stampISO;
        newE.config = config;
        if hasSolution
            newE.results = results;
        else
            newE.results = [];
        end
        log(end+1) = newE;
    end
    workspace.contractLog = log;

    % Stash/refresh the live solution for this entry. Build the pair by field
    % assignment rather than struct(...): a LUTSolution argument would dispatch
    % struct() to the object's own overloaded method ("too many input args").
    solKey = "e" + entryId;
    if hasSolution
        pair = struct();
        pair.solution = workspace.solution;
        pair.activeSolution = workspace.activeSolution;
        workspace.contractSolutions.(solKey) = pair;
    end

    % --- Serialize the aggregate document ---
    doc = struct( ...
        "sessionId", workspace.sessionId, ...
        "created", workspace.contractCreated, ...
        "updated", stampISO);
    % A length-1 struct array encodes as a JSON object, not a 1-element array;
    % wrap in a cell so "entries" is always a JSON list.
    doc.entries = num2cell(log);

    json = jsonencode(doc, PrettyPrint=true);
    fid = fopen(filePath, "w");
    if fid < 0
        observation = "Could not open '" + filePath + "' for writing.";
        return
    end
    closer = onCleanup(@() fclose(fid));
    fwrite(fid, json, "char");
    clear closer   % flush/close now so the file is readable below

    % --- Live-solution sidecar (.mat) for re-solve-free reload ---
    anySolutions = ~isempty(fieldnames(workspace.contractSolutions));
    [p, n] = fileparts(filePath);
    matPath = fullfile(p, n + ".mat");
    if anySolutions
        entries = workspace.contractSolutions;
        save(matPath, "entries");
    end

    nEntries = numel(log);
    verb = "added entry " + entryId;
    if updatedInPlace
        verb = "updated entry " + entryId + " in place";
    end
    if hasSolution
        observation = "Saved contract '" + filePath + "' (session " + ...
            workspace.sessionId + "): " + verb + " with results; " + ...
            nEntries + " entry(s) total. " + ...
            "Live solution saved to '" + matPath + "'.";
    else
        observation = "Saved contract '" + filePath + "' (session " + ...
            workspace.sessionId + "): " + verb + " (configuration only, no " + ...
            "solution yet); " + nEntries + " entry(s) total.";
    end
end

function e = emptyEntry()
%emptyEntry A 0x0 struct carrying the entry field order used on disk.
    e = struct("entryId", {}, "timestamp", {}, "config", {}, "results", {});
end
