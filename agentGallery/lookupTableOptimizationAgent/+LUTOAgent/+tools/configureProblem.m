function [observation, workspace] = configureProblem(workspace, opts)
%configureProblem Set input bounds, data types, and solver options on the current problem; every argument is optional name-value and only the supplied ones are applied, so call it repeatedly to refine the setup. inputLowerBounds, inputUpperBounds, and wordLengths take numeric vectors (one entry per input, e.g. [8 16 32] word lengths); inputTypes takes comma-separated type specs and outputType a single spec, where a spec is "single", "double", "half", or "numerictype(signed,wordLength,fractionLength)". Always set explicit bounds for floating-point input types.
%   All inputs are optional name-value arguments; only the ones supplied are
%   applied, so the tool can be called repeatedly to refine the setup.
%
%   Input bounds / types (vectors apply per input dimension):
%     inputLowerBounds  - numeric vector of lower bounds
%     inputUpperBounds   - numeric vector of upper bounds
%     inputTypes         - string of data-type specs, comma-separated for
%                          multi-input problems, e.g.
%                          "numerictype(0,16,12)" or "single,single"
%     outputType         - single data-type spec for the output
%
%   Solver options (FunctionApproximation.Options):
%     wordLengths             - numeric vector, e.g. [8 16 32]
%     absTol, relTol          - tolerances
%     interpolation           - "Linear" | "Flat" | "Nearest" | "None"
%     breakpointSpecification - "ExplicitValues" | "EvenSpacing" | "EvenPow2Spacing"
%     maxMemoryUsage          - numeric, in memoryUnits
%     memoryUnits             - e.g. "bytes", "bits", "KiB"
%     maxTime                 - solver time budget in seconds
%     approximateSolutionType - "Simulink" | "MATLAB"
%     hdlOptimized            - logical
%     saturateToOutputType    - logical
%     onCurveTableValues      - logical
%     useParallel             - logical

% Copyright 2026 The MathWorks, Inc.

    arguments
        workspace
        opts.inputLowerBounds (1,:) double
        opts.inputUpperBounds (1,:) double
        opts.inputTypes (1,1) string
        opts.outputType (1,1) string
        opts.wordLengths (1,:) double
        opts.absTol (1,1) double
        opts.relTol (1,1) double
        opts.interpolation (1,1) string
        opts.breakpointSpecification (1,1) string
        opts.maxMemoryUsage (1,1) double
        opts.memoryUnits (1,1) string
        opts.maxTime (1,1) double
        opts.approximateSolutionType (1,1) string
        opts.hdlOptimized (1,1) logical
        opts.saturateToOutputType (1,1) logical
        opts.onCurveTableValues (1,1) logical
        opts.useParallel (1,1) logical
    end

    if ~isfield(workspace, "problem")
        observation = "No problem defined yet. Call defineProblem first.";
        return
    end
    problem = workspace.problem;
    applied = string.empty(1,0);

    % Record the raw supplied values into the contract (before any char/
    % numerictype conversion) so saveContract can serialize exactly what the
    % user declared. opts holds only the fields actually supplied this call.
    if ~isfield(workspace, "contract")
        workspace.contract = struct();   % defensive; defineProblem normally seeds it
    end
    suppliedOpts = string(fieldnames(opts)).';
    for f = suppliedOpts
        workspace.contract.(f) = opts.(f);
    end

    % --- Problem-level: bounds ---
    if isfield(opts, "inputLowerBounds")
        problem.InputLowerBounds = opts.inputLowerBounds;
        applied(end+1) = "InputLowerBounds=[" + strtrim(num2str(opts.inputLowerBounds)) + "]";
    end
    if isfield(opts, "inputUpperBounds")
        problem.InputUpperBounds = opts.inputUpperBounds;
        applied(end+1) = "InputUpperBounds=[" + strtrim(num2str(opts.inputUpperBounds)) + "]";
    end

    % --- Problem-level: data types ---
    if isfield(opts, "inputTypes")
        % Split on commas separating per-input specs, but NOT the commas
        % inside a numerictype(...) spec. The negative lookahead skips any
        % comma that sits within an unclosed parenthesis group.
        specs = strtrim(string(regexp(opts.inputTypes, ',(?![^()]*\))', 'split')));
        nt = arrayfun(@LUTOAgent.parseDataType, specs(:).', "UniformOutput", false);
        problem.InputTypes = [nt{:}];
        applied(end+1) = "InputTypes=" + opts.inputTypes;
    end
    if isfield(opts, "outputType")
        problem.OutputType = LUTOAgent.parseDataType(opts.outputType);
        applied(end+1) = "OutputType=" + opts.outputType;
    end

    % --- Options-level ---
    optMap = struct( ...
        "wordLengths","WordLengths", ...
        "absTol","AbsTol", ...
        "relTol","RelTol", ...
        "interpolation","Interpolation", ...
        "breakpointSpecification","BreakpointSpecification", ...
        "maxMemoryUsage","MaxMemoryUsage", ...
        "memoryUnits","MemoryUnits", ...
        "maxTime","MaxTime", ...
        "approximateSolutionType","ApproximateSolutionType", ...
        "hdlOptimized","HDLOptimized", ...
        "saturateToOutputType","SaturateToOutputType", ...
        "onCurveTableValues","OnCurveTableValues", ...
        "useParallel","UseParallel");

    optFields = string(fieldnames(optMap));
    for f = optFields.'
        if isfield(opts, f)
            value = opts.(f);
            propName = optMap.(f);
            % char-valued options expect character vectors, not strings.
            if isstring(value)
                value = char(value);
            end
            problem.Options.(propName) = value;
            if isnumeric(opts.(f))
                applied(end+1) = propName + "=" + strtrim(num2str(opts.(f))); %#ok<AGROW>
            else
                applied(end+1) = propName + "=" + string(opts.(f)); %#ok<AGROW>
            end
        end
    end

    workspace.problem = problem;
    % Configuration changed: previous solution no longer matches.
    workspace = LUTOAgent.internal.clearSolution(workspace);

    if isempty(applied)
        observation = "No settings supplied; problem unchanged.";
    else
        observation = "Applied: " + strjoin(applied, "; ") + ".";
    end
end
