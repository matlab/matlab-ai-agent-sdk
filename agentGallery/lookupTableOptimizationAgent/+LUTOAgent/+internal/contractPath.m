function fp = contractPath(filePath, createDir)
%contractPath Resolve a contract file to the .luto-agent folder under the cwd.
%   Contracts live in a ".luto-agent" folder in the current working directory.
%   If FILEPATH has no folder component, it is placed in that folder; a bare
%   name with no extension gets ".json". If FILEPATH already carries a folder,
%   it is respected as-is (so callers can point elsewhere explicitly).
%
%   Set CREATEDIR true to create the .luto-agent folder when missing (used on
%   save). FP is the fully resolved path.

% Copyright 2026 The MathWorks, Inc.

    arguments
        filePath (1,1) string
        createDir (1,1) logical = false
    end

    [p, n, e] = fileparts(filePath);
    if strlength(e) == 0
        e = ".json";
    end
    if strlength(p) == 0
        p = LUTOAgent.internal.contractDir();
    end
    if createDir && exist(p, "dir") ~= 7
        mkdir(p);
    end
    fp = fullfile(p, n + e);
end
