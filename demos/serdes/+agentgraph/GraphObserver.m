classdef (Abstract) GraphObserver < handle
%GRAPHOBSERVER  Event interface for observing graph execution.

    methods (Abstract)
        nodeRunning(this, nodeName)
        nodeDone(this, nodeName, result)
        nodeError(this, nodeName, err)
        toolStarted(this, nodeName, toolName, inputText)
        toolResult(this, nodeName, toolName, isError, outputText)
        agentDecision(this, nodeName, text)
        routerDecision(this, fromName, chosenName, reason)
    end
end
