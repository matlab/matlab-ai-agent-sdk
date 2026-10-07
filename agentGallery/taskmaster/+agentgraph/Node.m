classdef (Abstract) Node < matlab.mixin.Heterogeneous
%NODE  Abstract base for a graph step.
%
%   A Node is one unit of work in a graph traversal. Graphs address nodes by
%   Name and run them via execute(...). Concrete node types (AgentNode and
%   FunctionNode) supply the behaviour.
%
%   HETEROGENEOUS: the mixin is what lets one graph hold several node types --
%   [FunctionNode; AgentNode] fails with MATLAB:UnableToConvert without it. Two
%   consequences:
%     - class() on a mixed array returns "agentgraph.Node", not a concrete type,
%       so isa() checks must be per element rather than on the array.
%     - Preallocation and index-assignment past the end need a
%       getDefaultScalarElement, which is not defined.

% Copyright 2026 The MathWorks, Inc.

    properties (SetAccess = protected)
        %Name  Unique identifier used by engines to address this node. Concrete,
        %   not abstract, because MATLAB allows validators on neither an abstract
        %   property nor a subclass's concrete override of one
        %   (MATLAB:type:PropTypeNotSupportedForSubclassConcrete).
        %
        %   The name keys workspace.agentgraph.<graph>.cache, a dynamic struct
        %   field, so it must be a valid variable name -- validated on each
        %   concrete node's constructor argument, not here, because MATLAB
        %   rejects the implicit "" default.
        Name (1,1) string
        %Description  Short orchestration-facing role of this node (1,1 string).
        %   Unlike an AgentNode's agent SystemPrompt (which tells that agent
        %   HOW to do its work), Description tells an ORCHESTRATOR above the graph
        %   what this node is FOR -- e.g. "baseline measurement" vs. "the iterate
        %   lever". Read by AgentGraph.describeNodes so the graph is self-describing
        %   and a taskmaster needs no hand-written per-graph hint. Empty by default.
        Description (1,1) string = ""
    end

    methods (Abstract)
        %EXECUTE  Do this node's unit of work.
        %   [RESULT, WORKSPACE] = EXECUTE(THIS, WORKSPACE, NodePrompt=TEXT,
        %   ParentWorkspacePath=PATH) runs the node, threading WORKSPACE
        %   through. Observer=OBSERVER optionally receives progress callbacks.
        %   FunctionNode accepts but does not use NodePrompt or
        %   ParentWorkspacePath.
        [result, workspace] = execute(this, workspace, nvp)
    end
end
