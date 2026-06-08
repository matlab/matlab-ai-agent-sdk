function c = addTwoNumbers(a, b)
% Add two numbers together#
% Inputs
% - a double first summand
% - b double second summand

% Copyright 2026 The MathWorks, Inc.

    arguments (Input)
        a (1,1) double 
        b (1,1) double
    end
    arguments (Output)
        c double % sum of a and b
    end
    c = a + b;
end
