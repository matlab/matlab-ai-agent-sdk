function d = contractDir()
%contractDir The folder where LUTO contracts are stored under the cwd.
%   Contracts (JSON + .mat sidecars) live in a ".luto-agent" folder in the
%   current working directory. Single source of truth for save, load, and scan.

% Copyright 2026 The MathWorks, Inc.

    d = fullfile(pwd, ".luto-agent");
end
