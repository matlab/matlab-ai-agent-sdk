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

    properties (SetAccess = protected)
        %Workspace   Whether the tool accepts and returns a workspace argument.
        Workspace(1,1) string {mustBeMember(Workspace, ["none","agent"])} = "none"
    end


    methods (Sealed, Access=protected)
        function displayNonScalarObject(obj)
            displayTools(obj);
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
            if isprop(obj, "InputSchema")
                props = [props; "InputSchema"];
            end
            if isprop(obj, "OutputSchema")
                props = [props; "OutputSchema"];
            end
            props = [props; "Workspace"];
            if isprop(obj, "ApprovalRequest")
                props = [props; "ApprovalRequest"];
            end
            props = [props; "DisplayTitle"; "Annotations"];
            groups = matlab.mixin.util.PropertyGroup(props);
        end
    end

    methods (Sealed, Access=private)
        function displayTools(obj)
            n = numel(obj);
            dimStr = matlab.mixin.CustomDisplay.convertDimensionsToString(obj);
            header = aisdk.llms.internal.MessageCatalog.getMessage( ...
                "llms:tool:arrayHeader", dimStr);
            fprintf("  %s\n\n", header);

            syntaxCol      = strings(n,1);
            descriptionCol = strings(n,1);
            typeCol        = strings(n,1);
            workspaceCol   = strings(n,1);

            for i = 1:n
                syntaxCol(i) = displaySignature(obj(i));
                descriptionCol(i) = truncateDescription(obj(i).Description);
                typeCol(i) = displayTypeLabel(obj(i));
                workspaceCol(i) = displayWorkspaceLabel(obj(i));
            end

            t = table(char(syntaxCol), char(descriptionCol), char(typeCol), char(workspaceCol), ...
                VariableNames=["Syntax", "Description", "Type", "Workspace"]);
            disp(t);
        end
    end

    methods (Access=protected)
        function label = displayWorkspaceLabel(obj)
            label = """" + obj.Workspace + """";
        end
    end

    methods (Abstract, Access=protected)
        sig = displaySignature(obj)
        label = displayTypeLabel(obj)
    end

    methods (Sealed)
        function tools = select(these, name)
            arguments
                these(1,:) aisdk.llms.tool.LLMTool
                name(1,1) string
            end
            toolIndex = find(strcmp(name, [these.Name]), 1);
            if isempty(toolIndex)
                error("llms:invalidFunctionCall", ...
                    aisdk.llms.internal.MessageCatalog.getMessage("llms:invalidFunctionCall", name));
            end
            tools = these(toolIndex);
        end
    end
end

function txt = truncateDescription(description)
% Flatten newlines and truncate to maxLen chars.
    maxLen = 60;
    txt = replace(description, newline, " ");
    if strlength(txt) > maxLen + 1
        txt = extractBefore(txt, maxLen + 1) + "…";
    end
end
