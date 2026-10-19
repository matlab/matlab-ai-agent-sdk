function [observation, workspace] = auditModelMemory(workspace, model)
%auditModelMemory List every Lookup Table block in a Simulink model or subsystem with its memory usage in bytes; pass model as a model name or subsystem path, and use it to find optimization candidates before defineProblem.
%   Uses FunctionApproximation.LUTMemoryUsageCalculator to find optimization
%   candidates before defining a problem. MODEL is a model or subsystem name.

% Copyright 2026 The MathWorks, Inc.

    arguments
        workspace
        model (1,1) string  % Model or subsystem name, e.g. "SimpleLookupModel".
    end

    modelName = model;
    if contains(model, "/")
        modelName = extractBefore(model, "/");
    end
    if ~bdIsLoaded(modelName)
        load_system(modelName);
    end

    calc = FunctionApproximation.LUTMemoryUsageCalculator();
    memTable = lutmemoryusage(calc, char(model));
    workspace.memoryTable = memTable;

    if isempty(memTable)
        observation = "No Lookup Table blocks found in '" + model + "'.";
        return
    end

    lines = "Lookup Table blocks in '" + model + "':";
    for i = 1:height(memTable)
        lines(end+1) = sprintf("  %s -> %g bytes", ...
            string(memTable.BlockPath(i)), memTable.MemoryUsage(i)); %#ok<AGROW>
    end
    lines(end+1) = "Use defineProblem with sourceKind='block' on a block path to optimize one.";
    observation = strjoin(lines, newline);
end
