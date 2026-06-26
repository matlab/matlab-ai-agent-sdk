function result = typedWithVarargin(x, varargin)
% A function with a typed positional arg and varargin.
    arguments
        x (1,1) double
    end
    arguments (Repeating)
        varargin
    end
    result = x;
end
