function y = testFcn(x)
% Increment an integer by one
% Inputs
% - x double input value

% Copyright 2026 The MathWorks, Inc.

    arguments (Input)
        x (1,1) double
    end
    arguments (Output)
        y double % incremented value
    end
    y = x + 1;
end
