classdef LLMToolArgument
%LLMToolArgument Description of a function parameter for tool definitions.

% Copyright 2026 The MathWorks, Inc.

    properties
        %Name   Name of the parameter.
        Name(1,1) string

        %Description   Description of the parameter.
        Description(1,1) string

        %DataType   JSON Schema type of the parameter ("string", "number", "integer", "boolean").
        DataType(1,1) string

        %Required   Whether the LLM must provide this parameter (JSON Schema "required").
        Required(1,1) logical

        %NameValue   Whether to pass this parameter as a name-value pair to the MATLAB function.
        NameValue(1,1) logical
    end

    methods
        function this = LLMToolArgument(nameOrPrototype, NVPairs)
            arguments
                nameOrPrototype {mustBeTextOrStruct}
                NVPairs.Description = ""
                NVPairs.DataType = ""
                NVPairs.Required = []
                NVPairs.NameValue = false
            end
            if isstruct(nameOrPrototype)
                opts = rmfield(NVPairs, "DataType");
                this = aisdk.LLMToolArgument.fromPrototype(nameOrPrototype, opts);
            else
                validateRequiredForDirectConstruction(NVPairs.Required);
                validateNameValueForDirectConstruction(NVPairs.NameValue);
                if isempty(NVPairs.Required)
                    NVPairs.Required = ~NVPairs.NameValue;
                end
                this.Name = string(nameOrPrototype);
                this.Description = NVPairs.Description;
                this.DataType = NVPairs.DataType;
                this.Required = NVPairs.Required;
                this.NameValue = NVPairs.NameValue;
            end
        end

        function tbl = summary(these)
            arguments
                these(1,:) aisdk.LLMToolArgument
            end
            tbls = arrayfun(@(pd)pd.summaryImpl, these, UniformOutput=false);
            tbl = vertcat(tbls{:});
        end

    end

    methods (Static, Access = private)
        function params = fromPrototype(str, options)
            names = fieldnames(str);
            params = aisdk.LLMToolArgument.empty(numel(names), 0);
            extraParams = fieldnames(options);
            for i = 1:numel(names)
                paramArgs{1} = names{i};
                paramArgs{2} = "DataType";
                paramArgs{3} = aisdk.LLMToolArgument.getType(str.(names{i}));
                for j = 1:numel(extraParams)
                    jParamName = extraParams{j};
                    jValues = options.(jParamName);
                    paramArgs{end+1} = jParamName; %#ok<*AGROW>
                    if isempty(jValues)
                        paramArgs{end+1} = jValues;
                    elseif isscalar(jValues)
                        paramArgs{end+1} = jValues;
                    else
                        paramArgs{end+1} = jValues(i);
                    end
                end
                params(i) = aisdk.LLMToolArgument(paramArgs{:});
            end
        end

        function t = getType(x)
            if isa(x, 'double') || isa(x, 'single') || isinteger(x)
                if ~isreal(x)
                    error("llms:unsupportedDatatypeInPrototype", ...
                        aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:unsupportedDatatypeInPrototype", class(x)));
                elseif ~isscalar(x)
                    error("llms:arrayPrototypeNotSupported", ...
                        aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:arrayPrototypeNotSupported"));
                elseif isfinite(x) && ceil(x) == x
                    t = "integer";
                else
                    t = "number";
                end
            elseif islogical(x)
                if ~isscalar(x)
                    error("llms:arrayPrototypeNotSupported", ...
                        aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:arrayPrototypeNotSupported"));
                end
                t = "boolean";
            elseif ischar(x) || isstring(x)
                t = "string";
            else
                error("llms:unsupportedDatatypeInPrototype", ...
                    aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:unsupportedDatatypeInPrototype", class(x)));
            end
        end
    end

    methods (Access = private)
        function tbl = summaryImpl(this)
            tbl = table(this.Name, this.Description, this.DataType, this.Required, this.NameValue, ...
                'VariableNames', {'Name', 'Description', 'DataType', 'Required', 'NameValue'});
        end
    end
end

function mustBeTextOrStruct(x)
if ~((isstruct(x) && isscalar(x)) || ischar(x) || (isstring(x) && isscalar(x)))
    error("llmToolArgument:invalidInput", ...
        aisdk.llms.internal.ErrorMessageCatalog.getMessage("llmToolArgument:invalidInput"));
end
end

function validateRequiredForDirectConstruction(value)
if ~isempty(value) && ~isscalar(value)
    error("llmToolArgument:nonScalarRequired", ...
        aisdk.llms.internal.ErrorMessageCatalog.getMessage("llmToolArgument:nonScalarRequired"));
end
end

function validateNameValueForDirectConstruction(value)
if ~isscalar(value)
    error("llmToolArgument:nonScalarNameValue", ...
        aisdk.llms.internal.ErrorMessageCatalog.getMessage("llmToolArgument:nonScalarNameValue"));
end
end
