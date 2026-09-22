classdef FunctionNode < agentgraph.Node
%FUNCTIONNODE  A graph node that runs a deterministic function (no LLM).

    properties
        Name    % (1,1) string — validation lives on abstract Node
        Fcn  function_handle
    end

    methods
        function this = FunctionNode(name, fcn)
            arguments
                name (1,1) string
                fcn function_handle
            end
            this.Name = name;
            this.Fcn = fcn;
        end

        function [result, workspace] = execute(this, ~, workspace, ~, ~, observer)
            arguments
                this
                ~
                workspace struct
                ~  % allTools (unused)
                ~  % client (unused)
                observer = []
            end

            fprintf("\n== [FunctionNode: %s] ==\n", this.Name);

            if ~isempty(observer)
                observer.nodeRunning(this.Name);
            end

            try
                [result, workspace] = this.Fcn(workspace);
                result = string(result);

                if ~isempty(observer)
                    observer.nodeDone(this.Name, result);
                end
            catch err
                if ~isempty(observer)
                    observer.nodeError(this.Name, err);
                end
                rethrow(err);
            end
        end
    end
end
