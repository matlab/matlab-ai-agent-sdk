classdef Workspace
%WORKSPACE  Accessors for the schema of an agentgraph workspace struct.
%
%   The workspace is the one value threaded through every node of every nesting
%   level. Its agentgraph bookkeeping has a fixed shape:
%
%       workspace.agentgraph.<nodePath>.graphName   graph identity at that level
%       workspace.agentgraph.<nodePath>.prompt      the request that level answered
%       workspace.agentgraph.<nodePath>.nodeTrace   names of completed nodes
%       workspace.agentgraph.<nodePath>.cache       each node's latest result
%       workspace.tokenUsage                         input/output/total/cachedInput, all levels
%
%   Everything else in the workspace is domain data written by tools.
%
%   These static methods are the only code that knows that layout, so a node, an
%   engine and a demo script cannot drift apart on it.
%
%   The SDK threads a tool's workspace as a struct and every tool assigns its own
%   fields onto it, so this class holds no state.
%
%   clearCache is the only method here that removes anything. Everything else
%   accumulates, so a resumed .mat shows the whole history.
%
%   See also agentgraph.AgentGraph, agentgraph.internal.MessageCatalog.

%   Copyright 2026 The MathWorks, Inc.

    methods (Static)

        %% ---- Per-level record ----

        function workspace = prepareGraphRecord(workspace, path, graphName)
        %PREPAREGRAPHRECORD  Bind a record to a graph, discarding foreign cache.
            arguments
                workspace struct
                path (1,:) string {mustBeNonempty}
                graphName (1,1) string
            end
            record = agentgraph.internal.Workspace.graphRecord(workspace, path);
            if ~isfield(record, "graphName") || record.graphName ~= graphName
                if isfield(record, "cache")
                    workspace = agentgraph.internal.Workspace.writeRecordField( ...
                        workspace, path, "cache", struct());
                end
            end
            workspace = agentgraph.internal.Workspace.writeRecordField( ...
                workspace, path, "graphName", graphName);
        end

        function name = graphName(workspace, path)
        %GRAPHNAME  Graph identity at PATH, or "" for an unbound record.
            arguments
                workspace struct
                path (1,:) string {mustBeNonempty}
            end
            record = agentgraph.internal.Workspace.graphRecord(workspace, path);
            if isfield(record, "graphName")
                name = record.graphName;
            else
                name = "";
            end
        end

        function workspace = recordPrompt(workspace, path, prompt)
        %RECORDPROMPT  Publish the request at an owning-node path.
        %   The graph tool records the router's latest request here.
            arguments
                workspace struct
                path (1,:) string {mustBeNonempty}
                prompt (1,1) string
            end
            workspace = agentgraph.internal.Workspace.writeRecordField( ...
                workspace, path, "prompt", prompt);
        end

        function workspace = appendNodeTrace(workspace, path, nodeName)
        %APPENDNODETRACE  Record that NODENAME completed at PATH.
        %   Called after the node returns, so an entry means "completed" -- a node
        %   that throws never appears.
            arguments
                workspace struct
                path (1,:) string {mustBeNonempty}
                nodeName (1,1) string
            end
            trace = agentgraph.internal.Workspace.nodeTrace(workspace, path);
            workspace = agentgraph.internal.Workspace.writeRecordField( ...
                workspace, path, "nodeTrace", [trace, nodeName]);
        end

        function trace = nodeTrace(workspace, path)
        %NODETRACE  Nodes that completed at PATH, in order.
        %   Empty means the graph was never driven: the level above answered
        %   without reaching it.
            arguments
                workspace struct
                path (1,:) string {mustBeNonempty}
            end
            record = agentgraph.internal.Workspace.graphRecord(workspace, path);
            if isfield(record, "nodeTrace")
                trace = record.nodeTrace;
            else
                trace = strings(1, 0);
            end
        end

        function workspace = cacheResult(workspace, path, nodeName, result)
        %CACHERESULT  Store NODENAME's latest result at PATH.
            arguments
                workspace struct
                path (1,:) string {mustBeNonempty}
                nodeName (1,1) string
                result (1,1) string
            end
            cache = agentgraph.internal.Workspace.nodeCache(workspace, path);
            cache.(nodeName) = result;
            workspace = agentgraph.internal.Workspace.writeRecordField( ...
                workspace, path, "cache", cache);
        end

        function [found, result] = cachedResult(workspace, path, nodeName)
        %CACHEDRESULT  Return NODENAME's stored result and whether it exists.
            arguments
                workspace struct
                path (1,:) string {mustBeNonempty}
                nodeName (1,1) string
            end
            cache = agentgraph.internal.Workspace.nodeCache(workspace, path);
            found = isfield(cache, nodeName);
            if found
                result = cache.(nodeName);
            else
                result = "";
            end
        end

        function names = cachedNodes(workspace, path)
        %CACHEDNODES  Node names with stored results at PATH.
            arguments
                workspace struct
                path (1,:) string {mustBeNonempty}
            end
            names = string(fieldnames( ...
                agentgraph.internal.Workspace.nodeCache(workspace, path)))';
        end

        function workspace = clearCache(workspace, path, nodeNames)
        %CLEARCACHE  Remove NODE NAMES from PATH's cache, if present.
            arguments
                workspace struct
                path (1,:) string {mustBeNonempty}
                nodeNames (1,:) string
            end
            cache = agentgraph.internal.Workspace.nodeCache(workspace, path);
            present = nodeNames(ismember(nodeNames, string(fieldnames(cache))'));
            if isempty(present)
                return;
            end
            cache = rmfield(cache, cellstr(present));
            workspace = agentgraph.internal.Workspace.writeRecordField( ...
                workspace, path, "cache", cache);
        end

        function paths = findRecordPathsByGraphName(workspace, name)
        %FINDRECORDPATHSBYGRAPHNAME  Paths owned by the named graph.
            arguments
                workspace struct
                name (1,1) string
            end
            paths = agentgraph.internal.graphLevels(workspace);
            keep = false(size(paths));
            for i = 1:numel(paths)
                keep(i) = agentgraph.internal.Workspace.graphName( ...
                    workspace, paths(i)) == name;
            end
            paths = paths(keep);
        end

        %% ---- Token usage ----

        function counts = tokenCounts(agent)
        %TOKENCOUNTS  An agent's cumulative counters, named as tokenUsage names them.
        %   This mapping from AIAgent property to workspace field is written here
        %   and nowhere else.
            counts = struct( ...
                "input",  agent.NumInputTokens, ...
                "output", agent.NumOutputTokens, ...
                "total",  agent.NumTotalTokens, ...
                "cachedInput", agent.NumCachedInputTokens);
        end

        function workspace = addTokenUsage(workspace, agent, baseline)
        %ADDTOKENUSAGE  Add AGENT's tokens to the all-levels total.
        %
        %   WORKSPACE = ADDTOKENUSAGE(WORKSPACE, AGENT) charges every token AGENT
        %   has counted. For an agent built fresh for one call, that is the call.
        %
        %   WORKSPACE = ADDTOKENUSAGE(WORKSPACE, AGENT, BASELINE) charges only
        %   what AGENT has counted since BASELINE, a tokenCounts snapshot. An
        %   agent that persists across calls reports cumulative counters, so
        %   omitting the baseline would re-charge every earlier call.
            arguments
                workspace struct
                agent
                baseline struct = struct("input", 0, "output", 0, "total", 0, "cachedInput", 0)
            end

            counts = agentgraph.internal.Workspace.tokenCounts(agent);

            if ~isfield(workspace, "tokenUsage")
                workspace.tokenUsage = struct("input", 0, "output", 0, ...
                    "total", 0, "cachedInput", 0);
            end
            for field = string(fieldnames(counts))'
                workspace.tokenUsage.(field) = workspace.tokenUsage.(field) ...
                    + counts.(field) - baseline.(field);
            end
        end

        function total = totalTokens(workspace)
        %TOTALTOKENS  Tokens across every level, or 0 if no agent has run.
            arguments
                workspace struct
            end
            if isfield(workspace, "tokenUsage")
                total = workspace.tokenUsage.total;
            else
                total = 0;
            end
        end
    end

    methods (Static, Access = private)
        function record = graphRecord(workspace, path)
        %GRAPHRECORD  The branch at PATH, or an empty struct if absent.
            path = agentgraph.internal.Workspace.pathSegments(path);
            if ~isfield(workspace, "agentgraph")
                record = struct();
                return;
            end
            record = workspace.agentgraph;
            for segment = path
                if ~isstruct(record) || ~isfield(record, segment)
                    record = struct();
                    return;
                end
                record = record.(segment);
            end
        end

        function workspace = writeRecordField(workspace, path, field, value)
            path = agentgraph.internal.Workspace.pathSegments(path);
            if ~isfield(workspace, "agentgraph")
                workspace.agentgraph = struct();
            end
            workspace.agentgraph = agentgraph.internal.Workspace.setAtPath( ...
                workspace.agentgraph, path, field, value);
        end

        function branch = setAtPath(branch, path, field, value)
            segment = path(1);
            if ~isfield(branch, segment)
                branch.(segment) = struct();
            end
            if numel(path) == 1
                branch.(segment).(field) = value;
            else
                branch.(segment) = agentgraph.internal.Workspace.setAtPath( ...
                    branch.(segment), path(2:end), field, value);
            end
        end

        function path = pathSegments(path)
            if isscalar(path) && contains(path, ".")
                path = split(path, ".")';
            end
        end

        function cache = nodeCache(workspace, path)
            record = agentgraph.internal.Workspace.graphRecord(workspace, path);
            if isfield(record, "cache")
                cache = record.cache;
            else
                cache = struct();
            end
        end

    end
end
