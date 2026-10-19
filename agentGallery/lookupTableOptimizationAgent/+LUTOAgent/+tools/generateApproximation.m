function [observation, workspace] = generateApproximation(workspace, fileName, filePath)
%generateApproximation Generate the LUT from the active solution: a Simulink Lookup Table subsystem/model, or a standalone MATLAB .m function; fileName and filePath apply to MATLAB output only, and infeasible solutions are refused.
%   Calls approximate(): in Simulink mode this creates a model with a
%   Lookup Table subsystem; in MATLAB mode it writes a standalone .m
%   function. FILENAME/FILEPATH apply to MATLAB mode only.

% Copyright 2026 The MathWorks, Inc.

    arguments
        workspace
        fileName (1,1) string = ""  % Output .m name (MATLAB mode only).
        filePath (1,1) string = ""  % Output directory (MATLAB mode only).
    end

    if ~isfield(workspace, "activeSolution") || ~isa(workspace.activeSolution, 'FunctionApproximation.LUTSolution')
        observation = "No solution available. Call solveProblem first.";
        return
    end
    solution = workspace.activeSolution;

    if ~strcmp(string(solution.Feasible), "true")
        observation = "WARNING: the active solution is infeasible. " + ...
            "Generating it anyway is not recommended. Re-solve with relaxed " + ...
            "constraints or select a feasible candidate first.";
        return
    end

    args = {};
    if strlength(fileName) > 0
        args = [args, {'Name', char(fileName)}];
    end
    if strlength(filePath) > 0
        args = [args, {'Path', char(filePath)}];
    end

    approximate(solution, args{:});
    workspace.approximated = true;

    observation = "Approximation generated. " + ...
        "For a Simulink solution a Lookup Table subsystem/model was created; " + ...
        "for a MATLAB solution a standalone .m function was written. " + ...
        "For Simulink block sources, call replaceOriginalBlock to swap it into the model.";
end
