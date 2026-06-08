function c = addTwoNumbersUsingNVP(NVP)
%Add two numbers together

% Copyright 2026 The MathWorks, Inc.

    arguments (Input)
        NVP.a(1,1) double % First summand
        NVP.b(1,1) double % Second summand
    end
    arguments (Output)
        c(1,1) double % sum of a and b
    end
    c = NVP.a + NVP.b;
end
