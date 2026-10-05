function result = typedWithVarargin(x, varargin)
% A function with a typed positional arg and varargin.

% Copyright 2026 The MathWorks, Inc.

    arguments
        x (1,1) double
    end
    arguments (Repeating)
        varargin
    end
    result = x;
end
