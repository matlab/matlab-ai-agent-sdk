function result = tableInput(data)
% Function with a table input for testing unsupported type error.
% Inputs
% - data table input data

% Copyright 2026 The MathWorks, Inc.

    arguments (Input)
        data (1,1) table
    end
    arguments (Output)
        result string
    end
    result = "got table";
end
