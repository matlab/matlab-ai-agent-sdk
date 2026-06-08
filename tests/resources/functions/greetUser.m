function msg = greetUser(name, greeting)
% Greet a user with an optional greeting prefix.
% Inputs
% - name string the user's name
% - greeting string an optional greeting word

% Copyright 2026 The MathWorks, Inc.

    arguments (Input)
        name (1,1) string
        greeting (1,1) string = "Hello"
    end
    arguments (Output)
        msg string
    end
    msg = greeting + ", " + name + "!";
end
