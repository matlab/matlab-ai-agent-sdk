classdef tFunctionNode < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addToPath(testCase)
            repoRoot = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'demos', 'serdes')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'demos', 'serdes', 'agentgraph', 'helpers')));
        end
    end

    methods (Test, TestTags = {'Unit'})

        function constructor_setsNameAndFcn(testCase)
            fcn = @(w) deal("ok",w);
            node = agentgraph.FunctionNode("myNode", fcn);

            testCase.verifyEqual(node.Name, "myNode");
            testCase.verifyEqual(node.Fcn, fcn);
        end

        function execute_simpleFcn_returnsStringResult(testCase)
            node = agentgraph.FunctionNode("n", @(w) deal("hello",w));
            ws = struct();

            [result, ~] = node.execute("task", ws, [], []);

            testCase.verifyEqual(result, "hello");
        end

        function execute_numericResult_convertedToString(testCase)
            node = agentgraph.FunctionNode("n", @(w) deal(42,w));
            ws = struct();

            [result, ~] = node.execute("task", ws, [], []);

            testCase.verifyEqual(result, "42");
        end

        function execute_modifiesWorkspace_returnsUpdatedWorkspace(testCase)
            fcn = @(w) deal("done", setfield(w, 'counter', 1));
            node = agentgraph.FunctionNode("n", fcn);
            ws = struct();

            [~, wsOut] = node.execute("task", ws, [], []);

            testCase.verifyEqual(wsOut.counter, 1);
        end

        function execute_withObserver_callsNodeRunningThenDone(testCase)
            obs = MockObserver();
            node = agentgraph.FunctionNode("n", @(w) deal("ok",w));
            ws = struct();

            node.execute("task", ws, [], [], obs);

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
                @() node.execute("task", ws, [], []), "test:boom");
        end

        function execute_fcnThrows_withObserver_callsNodeError(testCase)
            obs = MockObserver();
            fcn = @throwBoom;
            node = agentgraph.FunctionNode("n", fcn);
            ws = struct();

            try
                node.execute("task", ws, [], [], obs);
            catch
            end

            errorEntries = obs.Log(cellfun(@(x) strcmp(x{1}, 'nodeError'), obs.Log));
            testCase.verifyNotEmpty(errorEntries);
            testCase.verifyEqual(errorEntries{1}{2}, "n");
        end
    end
end

function [result, ws] = throwBoom(~, ~) %#ok<STOUT>
    error("test:boom", "exploded");
end
