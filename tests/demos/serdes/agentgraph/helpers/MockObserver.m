classdef MockObserver < agentgraph.GraphObserver
%MOCKOBSERVER  Test double that records all observer calls for assertion.

    properties
        Log cell = {}
    end

    methods
        function nodeRunning(this, nodeName)
            this.Log{end+1} = {'nodeRunning', nodeName};
        end

        function nodeDone(this, nodeName, result)
            this.Log{end+1} = {'nodeDone', nodeName, result};
        end

        function nodeError(this, nodeName, err)
            this.Log{end+1} = {'nodeError', nodeName, err};
        end

        function toolStarted(this, nodeName, toolName, inputText)
            this.Log{end+1} = {'toolStarted', nodeName, toolName, inputText};
        end

        function toolResult(this, nodeName, toolName, isError, outputText)
            this.Log{end+1} = {'toolResult', nodeName, toolName, isError, outputText};
        end

        function agentDecision(this, nodeName, text)
            this.Log{end+1} = {'agentDecision', nodeName, text};
        end

        function routerDecision(this, fromName, chosenName, reason)
            this.Log{end+1} = {'routerDecision', fromName, chosenName, reason};
        end
    end
end
