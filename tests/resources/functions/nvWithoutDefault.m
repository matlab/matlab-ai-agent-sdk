function out = nvWithoutDefault(options)
%Adds x and y, where x is optional with no default
    arguments
        options.x (1,1) double
        options.y (1,1) double = 10
    end
    if isfield(options, "x")
        out = options.x + options.y;
    else
        out = options.y;
    end
end
