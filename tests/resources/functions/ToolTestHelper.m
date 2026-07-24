classdef ToolTestHelper
% Helper class for testing tool construction from class methods.

%   Copyright 2026 The MathWorks, Inc.

    methods (Static)
        function c = addNumbers(a, b)
        % addNumbers Add two numbers together.
            arguments
                a (1,1) double
                b (1,1) double
            end
            c = a + b;
        end

        function [added, subtracted, multiplied, divided] = doAllMathsStatic(a, b)
        % doAllMathsStatic Perform all four basic arithmetic operations on two numbers.
            arguments
                a (1,1) double
                b (1,1) double
            end
            added = a + b;
            subtracted = a - b;
            multiplied = a * b;
            divided = a / b;
        end
    end

    methods
        function c = multiply(~, a, b)
        % multiply Multiply two numbers together.
            arguments
                ~
                a (1,1) double
                b (1,1) double
            end
            c = a * b;
        end

    end

end
