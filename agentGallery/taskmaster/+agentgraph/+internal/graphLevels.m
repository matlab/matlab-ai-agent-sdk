function levels = graphLevels(workspace)
%GRAPHLEVELS  Dotted addresses of graph records present in a workspace.

% Copyright 2026 The MathWorks, Inc.

arguments
    workspace struct
end

if ~isfield(workspace, "agentgraph")
    levels = strings(1, 0);
    return;
end

levels = collectGraphLevels(workspace.agentgraph, string.empty(1,0));
end

function levels = collectGraphLevels(branch, prefix)
levels = strings(1,0);
% Record-data fields identify a graph level at this path. A level may also
% contain child graph levels, so keep scanning after recording it.
if isfield(branch, "graphName") || isfield(branch, "prompt") || ...
        isfield(branch, "nodeTrace") || ...
        isfield(branch, "cache")
    levels = join(prefix, ".");
end
for field = string(fieldnames(branch))'
    % These fields hold this level's data, not child graph records.
    if ismember(field, ["graphName", "prompt", "nodeTrace", "cache"])
        continue;
    end
    child = branch.(field);
    if isstruct(child)
        levels = [levels, collectGraphLevels( ...
            child, [prefix, field])]; %#ok<AGROW>
    end
end
end
