classdef MessageCatalog
%MESSAGECATALOG  Error messages for the +agentgraph framework, in one place.
%
%   Covers the framework only; example code under examples/ keeps its messages
%   inline.
%
%   Example:
%       agentgraph.internal.MessageCatalog.throwError( ...
%           "agentgraph:nodeNotFound", name);
%
%   See also agentgraph.AgentGraph.

%   Copyright 2026 The MathWorks, Inc.

    properties (Constant, Access = private)
        %Catalog  Dictionary mapping error ids to message text with {n} holes.
        Catalog = buildMessageCatalog;
    end

    methods (Static)
        function throwError(messageId, hole)
        %THROWERROR  Throw the catalog message for MESSAGEID, as the caller.
        %   Thrown as the caller so the report points at the offending config,
        %   not at the framework internals that detected it.
            arguments
                messageId (1,1) string
            end
            arguments (Repeating)
                hole (1,1) string
            end
            msg = agentgraph.internal.MessageCatalog.getMessage(messageId, hole{:});
            throwAsCaller(MException(messageId, "%s", msg));
        end
    end

    methods (Static, Access = private)
        function msg = getMessage(messageId, hole)
        %GETMESSAGE  Message text for MESSAGEID with {n} holes filled from HOLE.
        %   The n-th element of HOLE replaces "{n}".
            arguments
                messageId (1,1) string
            end
            arguments (Repeating)
                hole (1,1) string
            end

            msg = agentgraph.internal.MessageCatalog.Catalog(messageId);
            for i = 1:numel(hole)
                msg = replace(msg, "{" + i + "}", hole{i});
            end
        end
    end
end

function catalog = buildMessageCatalog
catalog = dictionary("string", "string");
catalog("agentgraph:cyclicGraph") = "AgentGraph requires an acyclic graph (DAG); the graph contains a cycle.";
catalog("agentgraph:nodeNotFound") = "Node '{1}' not found.";
catalog("agentgraph:missingGraphName") = "AgentGraph requires Name= at construction.";
catalog("agentgraph:invalidFunctionNodeArguments") = "Use FunctionNode(tool) or FunctionNode(name, functionHandle).";
catalog("agentgraph:toolNotWorkspaceAware") = "Tool '{1}' must be created with Workspace=""agent"" to back a FunctionNode; a node has to thread the workspace through.";
catalog("agentgraph:toolHasRequiredArguments") = "Tool '{1}' has required argument(s) {2}, but a FunctionNode calls it with no arguments. Use an AgentNode, or make the arguments optional.";
catalog("agentgraph:missingNodeDescription") = "Graph '{1}' cannot be used as a routing tool because node(s) {2} have no Description.";
catalog("agentgraph:duplicateNodeName") = "Graph '{1}' contains duplicate node name(s) {2}. Give each node a distinct name.";
catalog("agentgraph:unknownTargetNode") = "Graph '{1}' cannot route to unknown target '{2}'. Choose a node described to the router.";
catalog("agentgraph:clearCacheUnknownNode") = "Graph '{1}' cannot clear unknown node '{2}'.";
catalog("agentgraph:duplicateToolName") = "Tool name '{1}' is reserved for the graph routing tool.";
catalog("agentgraph:routerNotAttached") = "Graph routing tool is not attached to an agent.";
catalog("agentgraph:routerRequestMissing") = "Graph routing tool cannot find the current user request.";
end
