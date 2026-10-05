classdef CallableTool < aisdk.tool.LLMTool
%CallableTool Base class for tools that can be called.

% Copyright 2026 The MathWorks, Inc.

    properties
        %ApprovalRequest   Approval mode for user confirmation before calling.
        ApprovalRequest(1,1) aisdk.tool.ApprovalRequest = ...
            aisdk.tool.ApprovalRequest.once
    end

    properties (Access = protected)
        %Function   Function handle to invoke when the tool is called.
        Function = @aisdk.tool.internal.CallableTool.doNothing
    end

    methods(Abstract, Access = protected)
        [output, workspace] = evaluateImpl(this, args, workspace)
    end

    methods(Abstract, Hidden)
        schema = inputSchema(this)
    end

    methods (Access = public)
        function [output, workspace] = evaluate(this, args, workspace)
            arguments
                this(1,1) aisdk.tool.internal.CallableTool
                args(1,1) struct
                workspace(1,1) struct = struct()
            end
            [output, workspace] = evaluateImpl(this, args, workspace);
        end
    end


    methods (Static, Access = protected)
        function doNothing
        end

        function str = argumentsToSchema(args)
        %argumentsToSchema Convert LLMToolArgument array to JSON Schema struct.
            str = struct();
            str.type = "object";
            params = struct();
            requiredParams = strings(1,0);
            for i = 1:numel(args)
                thisDescription = struct();
                if strlength(args(i).DataType) > 0
                    thisDescription.type = args(i).DataType;
                end
                if strlength(args(i).Description) > 0
                    thisDescription.description = args(i).Description;
                end
                params.(args(i).Name) = thisDescription;
                if args(i).Required
                    requiredParams(end + 1) = args(i).Name; %#ok<AGROW>
                end
            end
            str.properties = params;
            if ~isempty(requiredParams)
                str.required = requiredParams;
            end
            if isfield(str, 'required') && numel(str.required) == 1
                str.required = {str.required};
            end
        end
    end
end
