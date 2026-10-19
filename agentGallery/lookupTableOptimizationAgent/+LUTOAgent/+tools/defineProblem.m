function [observation, workspace] = defineProblem(workspace, functionSpec, sourceKind)
%defineProblem Create a FunctionApproximation problem from a math-function string (sourceKind "math", e.g. "sin", "exp", "1./x", "atan2"), an anonymous-function string (sourceKind "handle", e.g. "@(x) exp(-x)", which must be element-wise and vectorized), or a Simulink block path (sourceKind "block", e.g. "SimpleLookupModel/LUT1"); resets any existing problem and solution.
%   Stores the new problem on workspace.problem and clears any stale
%   solution. FUNCTIONSPEC is interpreted according to SOURCEKIND:
%     "math"   - a supported math function string, e.g. "sin", "exp", "1./x"
%     "handle" - an anonymous function string, e.g. "@(x) exp(-x)"
%     "block"  - a Simulink block path, e.g. "SimpleLookupModel/LUT1"

% Copyright 2026 The MathWorks, Inc.

    arguments
        workspace
        functionSpec (1,1) string
        sourceKind (1,1) string {mustBeMember(sourceKind, ["math","handle","block"])}
    end

    switch sourceKind
        case "handle"
            funcArg = str2func(functionSpec);
        case "block"
            funcArg = char(functionSpec);
            % Make sure the model is loaded so the solver can read it.
            modelName = extractBefore(functionSpec, "/");
            if strlength(modelName) > 0 && ~bdIsLoaded(modelName)
                load_system(modelName);
            end
            workspace.model = modelName;
        otherwise % "math"
            funcArg = char(functionSpec);
    end

    problem = FunctionApproximation.Problem(funcArg);

    workspace.problem = problem;
    workspace.sourceKind = sourceKind;
    workspace.functionSpec = functionSpec;
    % Start a fresh contract recording the declared intent. configureProblem
    % appends the options the user supplies; saveContract serializes it.
    workspace.contract = struct("functionSpec", functionSpec, "sourceKind", sourceKind);
    % A fresh problem invalidates any previous solution.
    workspace = LUTOAgent.internal.clearSolution(workspace);

    observation = sprintf(...
        "Created approximation problem for %s source '%s'. " + ...
        "NumberOfInputs=%d. Configure bounds/types/options next, then solve.", ...
        sourceKind, functionSpec, problem.NumberOfInputs);
end
