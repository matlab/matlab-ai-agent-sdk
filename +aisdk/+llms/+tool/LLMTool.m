classdef LLMTool < matlab.mixin.Heterogeneous & matlab.mixin.CustomDisplay
%LLMTool Abstract base class for all LLM tools.

% Copyright 2026 The MathWorks, Inc.

    properties
        %Name   Name of the tool.
        Name(1,1) string

        %Description   Description of what the tool does.
        Description(1,1) string

        %DisplayTitle   Name of the tool for display purposes.
        DisplayTitle(1,1) string

        %Annotations   Additional metadata for the tool.
        Annotations(1,1) struct
    end


    methods (Sealed, Access=protected)
        function displayNonScalarObject(obj)
            displayNonScalarObject@matlab.mixin.CustomDisplay(obj);
        end

        function header = getHeader(obj)
            header = getHeader@matlab.mixin.CustomDisplay(obj);
        end

        function footer = getFooter(~)
            footer = '';
        end

        function groups = getPropertyGroups(obj)
            props = ["Name"; "Description"];
            if isprop(obj, "InputArguments")
                props = [props; "InputArguments"];
            end
            if isprop(obj, "OutputArguments")
                props = [props; "OutputArguments"];
            end
            if isprop(obj, "Workspace")
                props = [props; "Workspace"];
            end
            if isprop(obj, "RequiresApproval")
                props = [props; "RequiresApproval"];
            end
            props = [props; "DisplayTitle"; "Annotations"];
            groups = matlab.mixin.util.PropertyGroup(props);
        end
    end

    methods (Sealed)
        function tools = selectTool(these, name)
            arguments
                these(1,:) aisdk.llms.tool.LLMTool
                name(1,1) string
            end
            toolIndex = find(strcmp(name, [these.Name]), 1);
            if isempty(toolIndex)
                error("llms:invalidFunctionCall", ...
                    aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:invalidFunctionCall", name));
            end
            tools = these(toolIndex);
        end
    end
end
