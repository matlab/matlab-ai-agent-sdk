classdef FunctionNode < agentgraph.Node
%FUNCTIONNODE  A graph node that runs a deterministic function (no LLM).
%
%   Two forms:
%     FunctionNode(TOOL)       Uses TOOL.Name and, by default, TOOL.Description.
%     FunctionNode(NAME, FCN)  Runs [result, workspace] = FCN(workspace).
%
%   Either form takes Description=TEXT, stating what the node is for. A
%   A graph tool uses it to describe selectable targets to its router.
%

% Copyright 2026 The MathWorks, Inc.

    properties (SetAccess = immutable)
        Fcn  function_handle
        %Tool  Empty for the function-handle form.
        Tool aisdk.tool.LLMTool {mustBeScalarOrEmpty} = aisdk.tool.LLMTool.empty(1,0)
    end

    methods
        function this = FunctionNode(source, fcn, nvp)
        %FUNCTIONNODE  Construct a deterministic node.
        %   A tool-backed node takes its name and default description from TOOL.
            arguments
                source
                fcn function_handle = function_handle.empty()
                nvp.Description (1,1) string = ""
            end
            if isa(source, "aisdk.tool.LLMTool")
                if ~isscalar(source) || ~isempty(fcn)
                    agentgraph.internal.MessageCatalog.throwError( ...
                        "agentgraph:invalidFunctionNodeArguments");
                end
                validateTool(source);
                this.Name = source.Name;
                this.Tool = source;
                this.Fcn = function_handle.empty();
                if nvp.Description == ""
                    this.Description = source.Description;
                else
                    this.Description = nvp.Description;
                end
            else
                if ~isstring(source) || ~isscalar(source) || isempty(fcn)
                    agentgraph.internal.MessageCatalog.throwError( ...
                        "agentgraph:invalidFunctionNodeArguments");
                end
                mustBeValidVariableName(source);
                this.Name = source;
                this.Fcn = fcn;
                this.Description = nvp.Description;
            end
        end

        function [result, workspace] = execute(this, workspace, nvp)
            arguments
                this
                workspace struct
                nvp.NodePrompt (1,1) string = ""  % Used by AgentNode.
                nvp.ParentWorkspacePath (1,:) string = strings(1,0)  % Used by AgentNode.
                nvp.Observer = []
            end

            if ~isempty(nvp.Observer)
                nvp.Observer.nodeRunning(this.Name);
            end

            try
                if ~isempty(this.Tool)
                    % Optional tool arguments fall back to their defaults; a
                    % FunctionNode never sees the prompt, so it passes none.
                    [result, workspace] = this.Tool.evaluate(struct(), workspace);
                    % A tool with named outputs returns a struct, one field per
                    % output (LocalLLMTool.evaluateImpl). A node's result is a
                    % string, so unwrap the single-output case -- the shape a
                    % tool written as [observation, workspace] = f(...) produces.
                    if isstruct(result)
                        names = fieldnames(result);
                        if isscalar(names)
                            result = result.(names{1});
                        else
                            result = jsonencode(result);
                        end
                    end
                else
                    [result, workspace] = this.Fcn(workspace);
                end
                result = string(result);

                if ~isempty(nvp.Observer)
                    nvp.Observer.nodeDone(this.Name, result);
                end
            catch err
                if ~isempty(nvp.Observer)
                    nvp.Observer.nodeError(this.Name, err);
                end
                rethrow(err);
            end
        end
    end
end

function validateTool(tool)
    if tool.Workspace ~= "agent"
        agentgraph.internal.MessageCatalog.throwError( ...
            "agentgraph:toolNotWorkspaceAware", tool.Name);
    end
    if isprop(tool, "InputArguments") && ~isempty(tool.InputArguments) ...
            && any([tool.InputArguments.Required])
        required = [tool.InputArguments([tool.InputArguments.Required]).Name];
        agentgraph.internal.MessageCatalog.throwError( ...
            "agentgraph:toolHasRequiredArguments", tool.Name, ...
            join(required, ", "));
    end
end
