function result = untypedArgument(options)
% A function with an untyped NVP argument for testing.

% Copyright 2026 The MathWorks, Inc.

    arguments
        options.Value
    end
    result = options.Value;
end
