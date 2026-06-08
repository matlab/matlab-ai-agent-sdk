function result = alwaysError(x)
% A tool that always throws an error, for testing error handling.
% Inputs
% - x double any number

% Copyright 2026 The MathWorks, Inc.

    arguments (Input)
        x (1,1) double
    end
    arguments (Output)
        result double
    end
    error("alwaysError:fail", "something went wrong");
end
