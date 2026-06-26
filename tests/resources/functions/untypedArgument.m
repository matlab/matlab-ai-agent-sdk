function result = untypedArgument(options)
% A function with an untyped NVP argument for testing.
    arguments
        options.Value
    end
    result = options.Value;
end
