function nt = parseDataType(spec)
%parseDataType Convert a textual data-type spec into a numerictype.
%   NT = LUTOAgent.parseDataType(SPEC) resolves a data-type string to an
%   embedded.numerictype. Accepted forms include:
%     "single" / "double" / "half"          -> floating-point numerictype
%     "numerictype(s,wl)" / "(s,wl,fl)"      -> fixed-point numerictype
%     "fixdt(s,wl,fl)"                       -> fixed-point numerictype
%     built-in integers ("int8", "uint16")  -> equivalent fixed-point
%   Parsing is delegated to Simulink's built-in parseDataType, which reads
%   the string structurally without evaluating it.

% Copyright 2026 The MathWorks, Inc.

    arguments
        spec (1,1) string
    end

    % parseDataType parses the string and returns a
    % SimulinkFixedPoint.DataTypeContainer.ParsedDataTypeContainer.
    container = parseDataType(char(strtrim(spec)));

    if container.isUnknown
        error("LUTOAgent:parseDataType:unknown", ...
            "Unrecognized data type '%s'. Use 'single', 'double', 'half', " + ...
            "'fixdt(signed, wordLength, fractionLength)', or " + ...
            "'numerictype(signed, wordLength, fractionLength)'.", spec);
    end

    % ResolvedType is a Simulink.NumericType; convert it to the
    % embedded.numerictype the FunctionApproximation problem expects.
    try
        nt = numerictype(container.ResolvedType);
    catch
        error("LUTOAgent:parseDataType:unknown", ...
            "Data type '%s' does not resolve to a numeric type usable as an " + ...
            "input or output type.", spec);
    end
end
