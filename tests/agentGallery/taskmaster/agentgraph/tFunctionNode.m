classdef tFunctionNode < matlab.unittest.TestCase

% Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addToPath(testCase)
            repoRoot = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'agentGallery', 'taskmaster')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'agentGallery', 'taskmaster', 'agentgraph', 'helpers')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'resources', 'functions')));
        end
    end

    methods (Test, TestTags = {'Unit'})

        function FunctionNode_withNonIdentifierName_throws(testCase)
            testCase.verifyError(@() agentgraph.FunctionNode( ...
                "not a name", @(w) deal("ok", w)), ...
                "MATLAB:validators:mustBeValidVariableName");
        end

        %% Tool object form

        function constructor_withTool_usesToolName(testCase)
            tool = aisdk.LLMTool(@stampWorkspace, Workspace="agent");
            node = agentgraph.FunctionNode(tool);

            testCase.verifyEqual(node.Name, "stampWorkspace");
            testCase.verifyEqual(node.Tool, tool);
        end

        function FunctionNode_withFunctionHandle_stillWorks(testCase)
            node = agentgraph.FunctionNode("n", @(w) deal("ok",w));

            testCase.verifyEmpty(node.Tool);
        end

        function FunctionNode_withDescription_storesIt(testCase)
            % A handle-form node has no tool to take a description from, and a
            % taskmaster routes on descriptions.
            node = agentgraph.FunctionNode("n", @(w) deal("ok",w), ...
                Description="Does the thing");

            testCase.verifyEqual(node.Description, "Does the thing");
        end

        function constructor_withToolAndDescription_usesOverride(testCase)
            tool = aisdk.LLMTool(@stampWorkspace, Workspace="agent");
            node = agentgraph.FunctionNode(tool, Description="Graph-specific");

            testCase.verifyEqual(node.Description, "Graph-specific");
        end

        function constructor_withTwoTools_throws(testCase)
            tool = aisdk.LLMTool(@stampWorkspace, Workspace="agent");

            testCase.verifyError(@() agentgraph.FunctionNode([tool tool]), ...
                "agentgraph:invalidFunctionNodeArguments");
        end

        function constructor_withNameButNoFunction_throws(testCase)
            testCase.verifyError(@() agentgraph.FunctionNode("stampWorkspace"), ...
                "agentgraph:invalidFunctionNodeArguments");
        end

        function constructor_withToolWithoutWorkspace_throws(testCase)
            tool = aisdk.LLMTool(@addTwoNumbers);
            testCase.verifyError(@() agentgraph.FunctionNode(tool), ...
                "agentgraph:toolNotWorkspaceAware");
        end

        function constructor_withRequiredToolInput_throws(testCase)
            tool = aisdk.LLMTool(@stampWorkspaceRequired, Workspace="agent");
            testCase.verifyError(@() agentgraph.FunctionNode(tool), ...
                "agentgraph:toolHasRequiredArguments");
        end

        function execute_withTool_callsEvaluateAndThreadsWorkspace(testCase)
            tool = aisdk.LLMTool(@stampWorkspace, Workspace="agent");
            node = agentgraph.FunctionNode(tool);

            [result, wsOut] = node.execute(struct());

            testCase.verifyEqual(result, "stamped: stamped");
            testCase.verifyEqual(wsOut.stamps, "stamped");
        end

        function constructor_setsNameAndFcn(testCase)
            fcn = @(w) deal("ok",w);
            node = agentgraph.FunctionNode("myNode", fcn);

            testCase.verifyEqual(node.Name, "myNode");
            testCase.verifyEqual(node.Fcn, fcn);
        end

        function execute_simpleFcn_returnsStringResult(testCase)
            node = agentgraph.FunctionNode("n", @(w) deal("hello",w));
            ws = struct();

            [result, ~] = node.execute(ws);

            testCase.verifyEqual(result, "hello");
        end

        function execute_numericResult_convertedToString(testCase)
            node = agentgraph.FunctionNode("n", @(w) deal(42,w));
            ws = struct();

            [result, ~] = node.execute(ws);

            testCase.verifyEqual(result, "42");
        end

        function execute_modifiesWorkspace_returnsUpdatedWorkspace(testCase)
            fcn = @(w) deal("done", setfield(w, 'counter', 1));
            node = agentgraph.FunctionNode("n", fcn);
            ws = struct();

            [~, wsOut] = node.execute(ws);

            testCase.verifyEqual(wsOut.counter, 1);
        end

        function execute_withObserver_callsNodeRunningThenDone(testCase)
            obs = MockObserver();
            node = agentgraph.FunctionNode("n", @(w) deal("ok",w));
            ws = struct();

            node.execute(ws, Observer=obs);

            testCase.verifyLength(obs.Log, 2);
            testCase.verifyEqual(obs.Log{1}{1}, 'nodeRunning');
            testCase.verifyEqual(obs.Log{1}{2}, "n");
            testCase.verifyEqual(obs.Log{2}{1}, 'nodeDone');
            testCase.verifyEqual(obs.Log{2}{2}, "n");
        end

        function execute_fcnThrows_rethrowsError(testCase)
            fcn = @throwBoom;
            node = agentgraph.FunctionNode("n", fcn);
            ws = struct();

            testCase.verifyError( ...
                @() node.execute(ws), "test:boom");
        end

        function execute_fcnThrows_withObserver_callsNodeError(testCase)
            obs = MockObserver();
            fcn = @throwBoom;
            node = agentgraph.FunctionNode("n", fcn);
            ws = struct();

            try
                node.execute(ws, Observer=obs);
            catch
            end

            errorEntries = obs.Log(cellfun(@(x) strcmp(x{1}, 'nodeError'), obs.Log));
            testCase.verifyNotEmpty(errorEntries);
            testCase.verifyEqual(errorEntries{1}{2}, "n");
        end
    end
end

function [result, ws] = throwBoom(~) %#ok<STOUT>
    error("test:boom", "exploded");
end
