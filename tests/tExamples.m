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

            import matlab.unittest.fixtures.CurrentFolderFixture
            testCase.applyFixture(CurrentFolderFixture( ...
                fullfile(testCase.TestDir,"..","doc","examples")));

            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture( ...
                SuppressedWarningsFixture("MATLAB:graphics:HardwareUnavailable"))
        end
    end

    methods
        function startCapture(testCase,testName)
            aisdk.llms.client.internal.sendRequestWrapper("open", ...
                fullfile(testCase.TestDir,"recordings",testName));
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
            aisdk.llms.client.internal.sendRequestWrapper("close");
        end
    end

    % Integration: multiple components interact, but not System because
    % server responses are recorded/mocked.
    methods(Test, TestTags = {'Integration'})
        function testSimpleMathAgent(testCase)
            testCase.startCapture("SimpleMathAgent");
            evalc("SimpleMathAgent");
        end

        function testAnalyzeTextUsingParallelToolCalls(testCase)
            testCase.startCapture("AnalyzeTextUsingParallelToolCalls");
            evalc("AnalyzeTextUsingParallelToolCalls");
        end

        function testNestedToolsAndSubagentsExample(testCase)
            testCase.startCapture("NestedToolsAndSubagentsExample");
            evalc("NestedToolsAndSubagentsExample");
        end

        function testSupervisorSubagentExample(testCase)
            import matlab.unittest.fixtures.PathFixture
            testCase.applyFixture(PathFixture( ...
                fullfile(testCase.TestDir,"private","ui-doubles")));
            testCase.startCapture("SupervisorSubagentExample");
            evalc("SupervisorSubagentExample");
        end

        function testSendImageMessagesToVisionModels(testCase)

            testCase.assumeFalse( ...
                isMATLABReleaseOlderThan("R2026b"), ...
                "MATLABWindow exited Unexpected in TeamCity.");

            testCase.startCapture("SendImageMessagesToVisionModels");
            evalc("SendImageMessagesToVisionModels");
        end

        function testMCPClientAndAgentTools(testCase)
            testCase.startCapture("MCPClientAndAgentTools");
            mcpHTTPClient = @(endpoint) createMathMCPMock(); %#ok<NASGU>
            evalc("MCPClientAndAgentTools");
        end

        function testFitPolynomialToDataUsingAIAgent(testCase)
            
            testCase.assumeFalse( ...
                isMATLABReleaseOlderThan("R2026b"), ...
                "MATLABWindow exited Unexpected in TeamCity.");

            % Requires Curve Fitting Toolbox
            testCase.assumeTrue( ...
                ~isempty(ver("curvefit")), ...
                "Curve Fitting Toolbox is not installed");
            
            testCase.startCapture("FitPolynomialToDataUsingAIAgent");
            evalc("FitPolynomialToDataUsingAIAgent");
        end

        function testCreateSimpleChatBotUsingAIAgent(testCase)
            testCase.startCapture("CreateSimpleChatBotUsingAIAgent");
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
            modelName = []; %#ok<NASGU>
            client = []; %#ok<NASGU>
            sysPrompt = []; %#ok<NASGU>
            session = []; %#ok<NASGU>
            stopWord = []; %#ok<NASGU>
            prompt = []; %#ok<NASGU>
            text = []; %#ok<NASGU>

            % Run the example
            evalc("CreateSimpleChatBotUsingAIAgent");

            testCase.verifyEqual(count, find(prompts == "end", 1));
        end
    end
end

function iCloseNewFigures(figsBefore)
% Close only figures that were opened during the test
figsNow = findall(0, 'type', 'figure');
newFigs = setdiff(figsNow, figsBefore);
close(newFigs)
end
