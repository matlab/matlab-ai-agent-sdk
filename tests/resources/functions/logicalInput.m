function result = logicalInput(flag)
% Function with a logical input for testing type mapping.
% Inputs
% - flag logical a boolean flag

% Copyright 2026 The MathWorks, Inc.

    arguments (Input)
        flag (1,1) logical
    end
    arguments (Output)
        result string
    end
    if flag
        result = "true";
    else
        result = "false";
    end
end
