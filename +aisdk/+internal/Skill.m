classdef Skill
%Skill Representation of a loaded skill and its resources.

%   Copyright 2026 The MathWorks, Inc.

    properties (SetAccess = private)
        Name         (1,1) string
        Description  (1,1) string
        Path         (1,1) string
        Body         (1,1) string
        Resources    dictionary
    end

    methods
        function this = Skill(name, description, path, body, resources)
            arguments
                name        (1,1) string
                description (1,1) string
                path        (1,1) string
                body        (1,1) string
                resources   dictionary = dictionary
            end
            this.Name = name;
            this.Description = description;
            this.Path = path;
            this.Body = body;
            this.Resources = resources;
        end
    end
end
