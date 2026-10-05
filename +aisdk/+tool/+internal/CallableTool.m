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
    end
end
