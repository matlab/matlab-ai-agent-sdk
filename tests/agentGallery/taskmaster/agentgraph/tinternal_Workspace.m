classdef tinternal_Workspace < matlab.unittest.TestCase
%TINTERNAL_WORKSPACE  The workspace schema's accessors, including the absent-record
%   paths that a normal run never reaches.

% Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addToPath(testCase)
            repoRoot = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'agentGallery', 'taskmaster')));
        end
    end

    methods (Test, TestTags = {'Unit'})

        %% prompt

        function recordPrompt_storesRequestAtGraphLevel(testCase)
            ws = agentgraph.internal.Workspace.recordPrompt(struct(), "g", "Do the thing");

            testCase.verifyEqual(ws.agentgraph.g.prompt, "Do the thing");
        end

        %% nodeTrace

        function appendNodeTrace_calledTwice_keepsOrder(testCase)
            ws = agentgraph.internal.Workspace.appendNodeTrace(struct(), "g", "A");
            ws = agentgraph.internal.Workspace.appendNodeTrace(ws, "g", "B");

            testCase.verifyEqual( ...
                agentgraph.internal.Workspace.nodeTrace(ws, "g"), ["A","B"]);
        end

        function appendNodeTrace_twoGraphs_keepsRecordsSeparate(testCase)
            % One branch per graph is what makes a nesting's levels readable.
            ws = agentgraph.internal.Workspace.appendNodeTrace(struct(), "outer", "A");
            ws = agentgraph.internal.Workspace.appendNodeTrace(ws, "inner", "B");

            testCase.verifyEqual( ...
                agentgraph.internal.Workspace.nodeTrace(ws, "outer"), "A");
            testCase.verifyEqual( ...
                agentgraph.internal.Workspace.nodeTrace(ws, "inner"), "B");
        end

        function appendNodeTrace_nestedPaths_keepsOwnersSeparate(testCase)
            ws = agentgraph.internal.Workspace.appendNodeTrace( ...
                struct(), "top", "outerNode");
            ws = agentgraph.internal.Workspace.appendNodeTrace( ...
                ws, ["top","inner"], "innerNode");

            testCase.verifyEqual( ...
                agentgraph.internal.Workspace.nodeTrace(ws, "top"), "outerNode");
            testCase.verifyEqual( ...
                agentgraph.internal.Workspace.nodeTrace(ws, ["top","inner"]), "innerNode");
        end

        function nodeTrace_graphWithNoRecord_returnsEmpty(testCase)
            testCase.verifyEmpty( ...
                agentgraph.internal.Workspace.nodeTrace(struct(), "g"));
        end

        function nodeTrace_graphWithPromptButNoTrace_returnsEmpty(testCase)
            % The "not driven" case: the level above published a prompt and then
            % answered without reaching this graph. The record exists, the trace
            % does not.
            ws = agentgraph.internal.Workspace.recordPrompt(struct(), "g", "go");

            testCase.verifyEmpty( ...
                agentgraph.internal.Workspace.nodeTrace(ws, "g"));
        end

        %% tokenUsage

        function addTokenUsage_onFreshWorkspace_initialisesEveryField(testCase)
            ws = agentgraph.internal.Workspace.addTokenUsage(struct(), fakeAgent(10, 4));

            testCase.verifyEqual(ws.tokenUsage, ...
                struct("input", 10, "output", 4, "total", 14, "cachedInput", 0));
        end

        function addTokenUsage_calledTwice_accumulates(testCase)
            % Two nodes of one nesting both charge the same total.
            ws = agentgraph.internal.Workspace.addTokenUsage(struct(), fakeAgent(10, 4));
            ws = agentgraph.internal.Workspace.addTokenUsage(ws, fakeAgent(1, 2));

            testCase.verifyEqual(ws.tokenUsage.total, 17);
        end

        function addTokenUsage_withBaseline_chargesOnlyTheDelta(testCase)
            % A persistent agent reports cumulative counters, so without the
            % baseline every earlier call would be charged again.
            agent = fakeAgent(100, 50);
            baseline = agentgraph.internal.Workspace.tokenCounts(fakeAgent(90, 45));

            ws = agentgraph.internal.Workspace.addTokenUsage(struct(), agent, baseline);

            testCase.verifyEqual(ws.tokenUsage.total, 15);
        end

        function totalTokens_withNoUsageRecorded_returnsZero(testCase)
            testCase.verifyEqual( ...
                agentgraph.internal.Workspace.totalTokens(struct()), 0);
        end

        %% cache

        function cacheResult_thenCachedResult_returnsWhatWasWritten(testCase)
            ws = agentgraph.internal.Workspace.cacheResult(struct(), "g", "A", "resultA");

            [found, result] = agentgraph.internal.Workspace.cachedResult(ws, "g", "A");

            testCase.verifyTrue(found);
            testCase.verifyEqual(result, "resultA");
        end

        function cachedResult_graphWithNoRecord_returnsNotFound(testCase)
            found = agentgraph.internal.Workspace.cachedResult(struct(), "g", "A");

            testCase.verifyFalse(found);
        end

        function cachedResult_nodeWithNoEntry_returnsNotFound(testCase)
            ws = agentgraph.internal.Workspace.cacheResult(struct(), "g", "A", "resultA");

            found = agentgraph.internal.Workspace.cachedResult(ws, "g", "B");

            testCase.verifyFalse(found);
        end

        function cacheResult_sameNodeTwice_lastWriteWins(testCase)
            % Re-execution must supersede the entry, or a later drive that skips
            % this node reuses a result already known to be stale.
            ws = agentgraph.internal.Workspace.cacheResult(struct(), "g", "A", "run1");
            ws = agentgraph.internal.Workspace.cacheResult(ws, "g", "A", "run2");

            [~, result] = agentgraph.internal.Workspace.cachedResult(ws, "g", "A");

            testCase.verifyEqual(result, "run2");
        end

        function cacheResult_twoGraphs_keepsCachesSeparate(testCase)
            ws = agentgraph.internal.Workspace.cacheResult(struct(), "one", "A", "fromOne");
            ws = agentgraph.internal.Workspace.cacheResult(ws, "two", "A", "fromTwo");

            [~, result] = agentgraph.internal.Workspace.cachedResult(ws, "one", "A");

            testCase.verifyEqual(result, "fromOne");
        end

        function cacheResult_nestedPaths_keepsOwnersSeparate(testCase)
            ws = agentgraph.internal.Workspace.cacheResult( ...
                struct(), "top", "A", "outer");
            ws = agentgraph.internal.Workspace.cacheResult( ...
                ws, ["top","inner"], "A", "inner");

            [~, outer] = agentgraph.internal.Workspace.cachedResult(ws, "top", "A");
            [~, inner] = agentgraph.internal.Workspace.cachedResult( ...
                ws, ["top","inner"], "A");

            testCase.verifyEqual([outer, inner], ["outer", "inner"]);
        end

        function cachedNodes_graphWithNoRecord_returnsEmpty(testCase)
            testCase.verifyEqual( ...
                agentgraph.internal.Workspace.cachedNodes(struct(), "g"), strings(1,0));
        end

        function cachedNodes_graphWithSeveralEntries_returnsEveryName(testCase)
            ws = agentgraph.internal.Workspace.cacheResult(struct(), "g", "A", "resultA");
            ws = agentgraph.internal.Workspace.cacheResult(ws, "g", "B", "resultB");

            names = agentgraph.internal.Workspace.cachedNodes(ws, "g");

            testCase.verifyEqual(sort(names), sort(["A","B"]));
        end

        function clearCache_namedNode_removesOnlyIt(testCase)
            ws = agentgraph.internal.Workspace.cacheResult(struct(), "g", "A", "resultA");
            ws = agentgraph.internal.Workspace.cacheResult(ws, "g", "B", "resultB");

            ws = agentgraph.internal.Workspace.clearCache(ws, "g", "A");

            testCase.verifyEqual( ...
                agentgraph.internal.Workspace.cachedNodes(ws, "g"), "B");
        end

        function clearCache_nodeWithNoEntry_isNoOp(testCase)
            % A taskmaster hands down a whole
            % descendant set, most of which may never have run.
            before = agentgraph.internal.Workspace.cacheResult(struct(), "g", "A", "resultA");

            after = agentgraph.internal.Workspace.clearCache(before, "g", ["B","C"]);

            testCase.verifyEqual(after, before);
        end

        function clearCache_graphWithNoRecord_isNoOp(testCase)
            % Must not create the record it was about to clear from.
            ws = agentgraph.internal.Workspace.clearCache(struct(), "g", "A");

            testCase.verifyEqual(ws, struct());
        end

        function cacheResult_thenSaveAndLoad_returnsSameResults(testCase)
            % The only test standing behind resuming a workspace from disk.
            % Saves the plain struct alone -- never a graph or router,
            % which hold the Client and would write the API key to the file.
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture()).Folder;
            workspace = agentgraph.internal.Workspace.cacheResult( ...
                struct(), "g", "A", "resultA");
            file = fullfile(folder, "ws.mat");
            save(file, "workspace");

            loaded = load(file).workspace;

            [found, result] = agentgraph.internal.Workspace.cachedResult(loaded, "g", "A");
            testCase.verifyTrue(found);
            testCase.verifyEqual(result, "resultA");
        end
    end
end

function agent = fakeAgent(input, output)
%FAKEAGENT  The four counter properties tokenCounts reads, and nothing else.
    agent = struct("NumInputTokens", input, "NumOutputTokens", output, ...
        "NumTotalTokens", input + output, "NumCachedInputTokens", 0);
end
