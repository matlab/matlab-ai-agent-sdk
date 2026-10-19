function [observation, workspace] = loadContract(workspace, filePath, entryId)
%loadContract Restore a saved JSON contract from the ".luto-agent" folder in the current working directory: 
%   Reads a JSON contract written by saveContract, recreates the problem via
%   defineProblem, and reapplies the saved options via configureProblem. If a
%   matching .mat sidecar exists, the live LUTSolution is restored too, so you
%   can generate/replace without re-solving; otherwise re-run solveProblem.
%
%   A session contract file holds an array of entries (one per saved
%   configuration/solution). ENTRYID selects which entry to restore; omit it
%   (or pass 0) to restore the latest entry that has results, else the latest
%   entry. A file without an "entries" array is not a loadable contract.
%
%   Contracts are stored in a ".luto-agent" folder in the current working
%   directory. If FILEPATH is omitted, that folder is scanned for LUTO
%   contract files and the candidates are listed WITHOUT loading, so the agent
%   can confirm with the user which one to load before calling again with a path.

% Copyright 2026 The MathWorks, Inc.

    arguments
        workspace
        filePath (1,1) string = ""
        entryId (1,1) double = 0
    end

    % --- Discovery mode: no path given -> scan the contract folder ---
    if strlength(filePath) == 0
        observation = scanForContracts();
        return
    end

    filePath = LUTOAgent.internal.contractPath(filePath);
    if exist(filePath, "file") ~= 2
        observation = "Contract file '" + filePath + "' not found. " + ...
            "Call loadContract with no path to list saved contracts.";
        return
    end

    try
        c = jsondecode(fileread(filePath));
    catch err
        observation = "Contract '" + filePath + "' could not be parsed as JSON: " + ...
            string(err.message) + " " + ...
            "Fix the file, or call loadContract with no path to list saved contracts.";
        return
    end

    % --- Select the entry to restore ---
    if isfield(c, "entries")
        list = entriesToCell(c.entries);
        if isempty(list)
            observation = "Contract '" + filePath + "' has no entries to load.";
            return
        end
        [entry, entryId, selNote] = pickEntry(list, entryId);
        if isempty(entry)
            observation = selNote;   % entryId not found; selNote explains
            return
        end
        cfg = entry.config;
    else
        % Not a recognized contract: a valid contract carries an "entries"
        % array. Fail cleanly instead of dereferencing a missing config.
        observation = "Contract '" + filePath + "' is not in the expected " + ...
            "format (no 'entries' array) and cannot be loaded. Re-save it with " + ...
            "saveContract, or pick another file.";
        return
    end

    if ~isstruct(cfg) || ~isfield(cfg, "functionSpec") || ~isfield(cfg, "sourceKind")
        observation = "Contract is missing functionSpec/sourceKind; cannot load.";
        return
    end

    % --- Recreate the problem (loads the model for block sources) ---
    try
        [defObs, workspace] = LUTOAgent.tools.defineProblem(workspace, ...
            string(cfg.functionSpec), string(cfg.sourceKind));
    catch err
        observation = "Failed to recreate problem from contract: " + string(err.message);
        return
    end

    % --- Rebuild configureProblem name-value pairs from the saved options ---
    % functionSpec/sourceKind drove defineProblem above; every other config
    % field replays as a configureProblem name-value pair.
    skip = ["functionSpec", "sourceKind"];
    rowFields = ["wordLengths", "inputLowerBounds", "inputUpperBounds"];
    fns = string(fieldnames(cfg));
    nv = {};
    for f = fns.'
        if ismember(f, skip)
            continue
        end
        v = cfg.(f);
        if ischar(v)
            v = string(v);          % JSON strings decode to char; opts expect string
        end
        if ismember(f, rowFields) && isnumeric(v)
            v = v(:).';             % jsondecode yields columns; opts are (1,:)
        end
        nv{end+1} = f;  %#ok<AGROW>
        nv{end+1} = v;  %#ok<AGROW>
    end

    cfgObs = "";
    if ~isempty(nv)
        [cfgObs, workspace] = LUTOAgent.tools.configureProblem(workspace, nv{:});
    end

    % --- Restore the live solution from the sidecar, if present ---
    % Must run AFTER configureProblem, which clears stale solution state.
    [p, n] = fileparts(filePath);
    matPath = fullfile(p, n + ".mat");
    solnNote = "No solution sidecar found; call solveProblem to regenerate results.";
    if exist(matPath, "file") == 2
        S = load(matPath);
        pair = sidecarPair(S, entryId);
        if ~isempty(pair)
            workspace.solution = pair.solution;
            workspace.activeSolution = pair.activeSolution;
            solnNote = "Restored live solution from '" + matPath + "'; " + ...
                "ready to inspect/generate without re-solving.";
        else
            solnNote = "Sidecar '" + matPath + "' has no solution for this " + ...
                "entry; call solveProblem to regenerate results.";
        end
    end

    entryNote = "";
    if entryId > 0
        entryNote = "Entry " + entryId + " (" + selNote + "). ";
    end
    observation = "Loaded contract from '" + filePath + "'. " + entryNote + ...
        defObs + " " + cfgObs + " " + solnNote;
end

function [entry, entryId, note] = pickEntry(list, entryId)
%pickEntry Choose an entry (from a cell list of entry structs) by id, or default
%   to the newest that has results.
    ids = cellfun(@(e) e.entryId, list);
    if entryId > 0
        idx = find(ids == entryId, 1, "last");
        if isempty(idx)
            entry = [];
            note = "Entry id " + entryId + " not found in this contract " + ...
                "(available: " + strjoin(string(ids), ", ") + ").";
            return
        end
        note = "requested";
    else
        hasResults = cellfun(@entryHasResults, list);
        if any(hasResults)
            idx = find(hasResults, 1, "last");
            note = "latest solved entry";
        else
            idx = numel(list);
            note = "latest entry, not solved";
        end
    end
    entry = list{idx};
    entryId = entry.entryId;
end

function tf = entryHasResults(e)
%entryHasResults True when an entry carries a non-empty results block.
%   jsondecode may omit a null "results" field, or decode it to []; treat both
%   as "no results".
    tf = isfield(e, "results") && isstruct(e.results) && ~isempty(e.results);
end

function list = entriesToCell(entries)
%entriesToCell Normalize a decoded "entries" value to a cell array of structs.
%   jsondecode yields a struct array when all entries share fields, a scalar
%   struct for a single entry, or a cell array when fields differ.
    if iscell(entries)
        list = entries(:).';
    elseif isstruct(entries)
        list = num2cell(entries(:).');
    else
        list = {};
    end
end

function pair = sidecarPair(S, entryId)
%sidecarPair Extract {solution, activeSolution} for an entry from a loaded .mat.
%   S.entries is a struct keyed e<id>.
    pair = [];
    if isfield(S, "entries") && isstruct(S.entries)
        key = "e" + entryId;
        if entryId > 0 && isfield(S.entries, key)
            pair = S.entries.(key);
        end
    end
end

function observation = scanForContracts()
%scanForContracts List JSON files in the contract folder that look like LUTO
%   contracts, summarizing each so the agent can confirm a choice with the user.
    dirPath = LUTOAgent.internal.contractDir();
    files = dir(fullfile(dirPath, "*.json"));

    lines = string.empty(1, 0);
    sortKeys = string.empty(1, 0);   % updated/timestamp (or mtime fallback) for sort
    for k = 1:numel(files)
        fp = fullfile(files(k).folder, files(k).name);
        try
            c = jsondecode(fileread(fp));
        catch
            continue   % not valid JSON; skip
        end
        if ~isstruct(c)
            continue
        end

        [~, n] = fileparts(files(k).name);
        hasSidecar = exist(fullfile(files(k).folder, n + ".mat"), "file") == 2;

        if isfield(c, "entries")
            [summary, sortKey] = describeSession(c, files(k), hasSidecar);
        else
            continue   % valid JSON but not a LUTO contract
        end
        if strlength(summary) == 0
            continue
        end
        lines(end+1) = "  - " + string(files(k).name) + ": " + summary; %#ok<AGROW>
        sortKeys(end+1) = sortKey;                                       %#ok<AGROW>
    end

    if isempty(lines)
        observation = "No LUTO contract files found in '" + string(dirPath) + ...
            "'. Save one with saveContract, or call loadContract with an explicit path.";
        return
    end

    % Newest first, so the most recent sessions/solutions surface at the top.
    [~, order] = sort(sortKeys, "descend");
    lines = lines(order);

    observation = "Found " + numel(lines) + " contract(s) in '" + string(dirPath) + ...
        "' (newest first):" + newline + strjoin(lines, newline) + newline + ...
        "Each session file lists its entries with their entryId and key metrics, so " + ...
        "you can compare configurations/solutions. Ask the user which one to load, then " + ...
        "call loadContract with that file path (and an entryId to pick a specific entry).";
end

function [summary, sortKey] = describeSession(c, fileInfo, hasSidecar)
%describeSession One-line summary of a session contract file.
    list = entriesToCell(c.entries);
    n = numel(list);
    summary = "";
    sortKey = fallbackTime(c, fileInfo);
    if n == 0
        return
    end

    head = "";
    if isfield(c, "sessionId"); head = head + "session " + string(c.sessionId) + ", "; end
    if isfield(c, "updated");   head = head + "updated " + string(c.updated) + ", "; end
    head = head + n + " entr" + entryPlural(n);
    if hasSidecar
        head = head + " (live solutions available)";
    end

    entryLines = string.empty(1, 0);
    for i = 1:n
        e = list{i};
        d = "entry " + e.entryId + ": source=" + string(e.config.sourceKind) + ...
            " '" + string(e.config.functionSpec) + "'";
        if entryHasResults(e)
            d = d + " solved" + metricsSuffix(e.results);
        else
            d = d + " not solved";
        end
        entryLines(end+1) = "      * " + d; %#ok<AGROW>
    end
    summary = head + newline + strjoin(entryLines, newline);
end

function s = metricsSuffix(r)
%metricsSuffix Format the " (mem=<bytes>B maxErr=<err>)" tail of a results block,
%   or "" when the metrics are absent.
    if isstruct(r) && isfield(r, "memoryBytes") && isfield(r, "maxError")
        s = sprintf(" (mem=%gB maxErr=%g)", r.memoryBytes, r.maxError);
    else
        s = "";
    end
end

function key = fallbackTime(c, fileInfo)
%fallbackTime Prefer the embedded "updated" stamp; fall back to file mtime.
    if isfield(c, "updated")
        key = string(c.updated);
    else
        mtime = datetime(fileInfo.datenum, "ConvertFrom", "datenum");
        key = string(mtime, "yyyy-MM-dd HH:mm:ss");
    end
end

function s = entryPlural(n)
    if n == 1
        s = "y";
    else
        s = "ies";
    end
end
