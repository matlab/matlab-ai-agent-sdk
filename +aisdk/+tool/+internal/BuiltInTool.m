classdef (Abstract) BuiltInTool < aisdk.tool.internal.CallableTool
%BuiltInTool Abstract base class for SDK-provided built-in tools.

% Copyright 2026 The MathWorks, Inc.

    properties (SetAccess = protected)
        InputArguments (1,:) aisdk.LLMToolArgument
    end

    methods (Hidden)
        function schema = inputSchema(this)
            schema = aisdk.tool.internal.CallableTool.argumentsToSchema(this.InputArguments);
        end
    end

    methods (Access = protected)
        function sig = displaySignature(obj)
            sig = obj.Name;
        end

        function label = displayTypeLabel(~)
            label = "built-in";
        end

        function label = displayWorkspaceLabel(~)
            label = """none""";
        end
    end
end
