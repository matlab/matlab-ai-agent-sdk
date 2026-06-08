classdef MCPTool < aisdk.llms.tool.CallableTool
%MCPTool Tool wrapping an MCP server tool for use with an LLM.

% Copyright 2026 The MathWorks, Inc.

    methods
        function this = MCPTool(mcpClient)
            if nargin == 0
                return
            end
            callMethod = @mcpClient.callTool;
            toolDescriptions = mcpClient.ServerTools;
            tools = cell(1, numel(toolDescriptions));
            for i = 1:numel(toolDescriptions)
                td = toolDescriptions{i};
                tool = aisdk.llms.tool.MCPTool();
                tool.Name = td.name;
                tool.Description = td.description;
                tool.Function = @(varargin)callMethod(td.name, varargin{:});
                tool.InputArguments = td.inputSchema;
                tool.RequiresApproval = aisdk.llms.tool.RequiresApproval.never;
                tools{i} = tool;
            end
            this = [tools{:}];
        end

    end

    methods (Access = protected)
        function [output, workspace] = evaluateImpl(this, args, workspace)
            arguments
                this
                args(1,1) struct
                workspace
            end
            inputs = this.processArguments(args);
            output = this.Function(inputs{:});
        end

        function argsOut = processArguments(~, argsIn)
            argNames = fieldnames(argsIn);
            argsOut = cell(1,2*numel(argNames));
            for iArg = 1:numel(argNames)
                argsOut{2*iArg - 1} = string(argNames{iArg});
                argsOut{2*iArg} = argsIn.(argNames{iArg});
            end
        end
    end
end
