classdef tExamples < matlab.unittest.TestCase
% Smoke level tests for the example .m files

%   Copyright 2026 The MathWorks, Inc.

    properties
        TestDir;
        Capture = false; % run in capture or replay mode, cf. recordings/README.md
    end

    methods (TestClassSetup)
        function setUpAndTearDowns(testCase)

            testCase.assumeFalse( ...
                isMATLABReleaseOlderThan("R2024a"), ...
                "Local functions must be defined at the end of the script.");

            % Capture and replay server interactions
            testCase.TestDir = fileparts(mfilename("fullpath"));
            import matlab.unittest.fixtures.PathFixture

            if testCase.Capture
                testCase.applyFixture(PathFixture( ...
                    fullfile(testCase.TestDir,"private","recording-doubles")));
            else
                testCase.applyFixture(PathFixture( ...
                    fullfile(testCase.TestDir,"private","replaying-doubles")));
            end

            testCase.applyFixture(PathFixture( ...
                fullfile(testCase.TestDir,"helpers")));

            % Every example loads its API key from a ".env" file that users
            % create themselves. That file is not in the repository, so
            % shadow loadenv; see private/example-doubles/loadenv.m.
            testCase.applyFixture(PathFixture( ...
                fullfile(testCase.TestDir,"private","example-doubles")));

            % Tools default to ApprovalRequest="once", and the two examples
            % that demonstrate approval leave it there, so they reach the
            % approval dialog: AnalyzeTextDataUsingLLMTool on
            % extractCustomerData, CallMCPClientUsingAIAgent on
            % addTwoNumbers. Apply the double for the whole class, not just
            % for those two, so that it cannot depend on the order the
            % tests run in.
            testCase.applyFixture(PathFixture( ...
                fullfile(testCase.TestDir,"private","ui-doubles")));

            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture( ...
                SuppressedWarningsFixture("MATLAB:graphics:HardwareUnavailable"))
        end
    end

    methods
        function prepareExample(testCase,exampleName)
            % Make one example runnable: change to its own folder, so that
            % it is on the path and resolves its relative paths the way it
            % does for a user, and arm its recording.
            %
            % Each example lives in a folder of its own, named after the
            % example, and so is its recording.
            import matlab.unittest.fixtures.CurrentFolderFixture
            testCase.applyFixture(CurrentFolderFixture( ...
                fullfile(testCase.TestDir,"..","doc","examples",exampleName)));

            aisdk.client.internal.sendRequestWrapper("open", ...
                fullfile(testCase.TestDir,"recordings",exampleName));
        end
    end

    methods(TestMethodSetup)
        function recordOpenFigures(testCase)
            figsBefore = findall(0,'type','figure');
            testCase.addTeardown(@() iCloseNewFigures(figsBefore));
        end
    end

    methods(TestMethodTeardown)
        function closeCapture(~)
            aisdk.client.internal.sendRequestWrapper("close");
        end
    end

    % Integration: multiple components interact, but not System because
    % server responses are recorded/mocked.
    methods(Test, TestTags = {'Integration'})
        function testSolveSimpleMathProblemUsingAIAgent(testCase)
            testCase.prepareExample("SolveSimpleMathProblemUsingAIAgent");
            evalc("SolveSimpleMathProblemUsingAIAgent");
        end

        function testCreateSimpleChatBot(testCase)
            testCase.prepareExample("CreateSimpleChatbot");

            % Set up a fake input command, returning canned user prompts
            count = 0;
            prompts = [
                "What's Bohemian Rhapsody about?"
                "Why the guilt?"
                "end"
                "end"
            ];
            function res = input_(varargin)
                count = count + 1;
                res = prompts(count);
            end
            input = @input_; %#ok<NASGU>

            % To avoid errors about a static workspace, let MATLAB know we
            % want these variables to exist
            api = []; %#ok<NASGU>
            model = []; %#ok<NASGU>
            client = []; %#ok<NASGU>
            session = []; %#ok<NASGU>
            stopWord = []; %#ok<NASGU>
            prompt = []; %#ok<NASGU>
            text = []; %#ok<NASGU>

            % Run the example
            evalc("CreateSimpleChatBot");

            testCase.verifyEqual(count, find(prompts == "end", 1));
        end

        function testAnalyzeTextDataUsingLLMTool(testCase)
            testCase.prepareExample("AnalyzeTextDataUsingLLMTool");
            evalc("AnalyzeTextDataUsingLLMTool");
        end

        function testFitPolynomialToDataUsingAIAgent(testCase)

            testCase.assumeFalse( ...
                isMATLABReleaseOlderThan("R2026b"), ...
                "MATLABWindow exited Unexpected in TeamCity.");

            % Requires Curve Fitting Toolbox
            testCase.assumeTrue( ...
                ~isempty(ver("curvefit")), ...
                "Curve Fitting Toolbox is not installed");

            % The example adds random noise to its data, and the agent's
            % tools then reject fits based on that data. Replaying canned
            % responses only makes sense against the data they were
            % recorded for, so fix the generator.
            generatorState = rng(0,"twister");
            testCase.addTeardown(@() rng(generatorState));

            testCase.prepareExample("FitPolynomialToDataUsingAIAgent");
            evalc("FitPolynomialToDataUsingAIAgent");
        end

        function testOrchestrateMultipleSubagents(testCase)
            testCase.prepareExample("OrchestrateMultipleSubagents");
            evalc("OrchestrateMultipleSubagents");
        end

        function testCallMCPClientUsingAIAgent(testCase)
            % The mcpclient_mex double is a .m file shadowing a MEX file.
            % MEX wins over .m within a single folder, so the double relies
            % on coming earlier on the path, which in turn needs the current
            % folder not to be the repository root. prepareExample changes
            % to the example's own folder, so it is not.
            import matlab.unittest.fixtures.PathFixture
            testCase.applyFixture(PathFixture( ...
                fullfile(testCase.TestDir,"private","mcp-doubles")));
            testCase.prepareExample("CallMCPClientUsingAIAgent");

            % The example expects the MCP server and the model to be given.
            mcpServer = "mock-math-server"; %#ok<NASGU>
            api = "openai"; %#ok<NASGU>
            model = "gpt-4.1-mini"; %#ok<NASGU>

            evalc("CallMCPClientUsingAIAgent");
        end

        function testLabelImagesUsingLLM(testCase)
            testCase.prepareExample("LabelImagesUsingLLM");
            evalc("LabelImagesUsingLLM");
        end
    end
end

function iCloseNewFigures(figsBefore)
% Close only figures that were opened during the test
figsNow = findall(0, 'type', 'figure');
newFigs = setdiff(figsNow, figsBefore);
close(newFigs)
end
