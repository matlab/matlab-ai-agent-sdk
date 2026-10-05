function data = useSameFieldTypes(data,prototype)
% This function is undocumented and will change in a future release

%useSameFieldTypes  Change struct field data types to match prototype 

% Copyright 2026 The MathWorks, Inc.

if ~isscalar(data)
    if isempty(data)
        % A model with nothing to report answers with an empty list, or with
        % no data at all. The result still has to be a struct of the
        % expected form.
        data = emptyLike(prototype);
        return
    end
    data = arrayfun( ...
        @(d) aisdk.client.internal.useSameFieldTypes(d,prototype), data, ...
        UniformOutput=false);
    data = vertcat(data{:});
    return
end

data = alignTypes(data, prototype);
end

function data = alignTypes(data, prototype)
switch class(prototype)
    case "struct"
        prototype = prototype(1);
        if isempty(data)
            data = emptyLike(prototype);
        elseif isscalar(data)
            if isequal(sort(fieldnames(data)),sort(fieldnames(prototype)))
                for field_c = fieldnames(data).'
                    field = field_c{1};
                    data.(field) = alignTypes(data.(field),prototype.(field));
                end
            end
        else
            data = arrayfun(@(d) alignTypes(d,prototype), data, UniformOutput=false);
            data = vertcat(data{:});
        end
    case "string"
        data = string(data);
    case "categorical"
        data = categorical(string(data),categories(prototype));
    case "missing"
        data = missing;
    otherwise
        data = cast(data,"like",prototype);
end
end

function data = emptyLike(prototype)
% Empty struct array with the field names of prototype
data = repmat(prototype(1),0,1);
end
