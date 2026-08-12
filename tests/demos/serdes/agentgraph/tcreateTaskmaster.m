classdef tcreateTaskmaster < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addToPath(testCase)
            repoRoot = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'demos', 'serdes')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'tests', 'helpers')));
        end
    end

    methods (Test, TestTags = {'Unit'})

        function createTaskmaster_returnsAIAgent(testCase)
            [~, taskmaster] = buildTaskmaster();

            testCase.verifyClass(taskmaster, 'aisdk.AIAgent');
        end

        function createTaskmaster_hasRunToGoalTool(testCase)
            [~, taskmaster] = buildTaskmaster();

            tools = taskmaster.Tools;
            testCase.verifyLength(tools, 1);
            testCase.verifyEqual(tools.Name, "runToGoal");
        end

        function createTaskmaster_systemPromptContainsNodeRoles(testCase)
            [~, taskmaster] = buildTaskmaster();

            testCase.verifySubstring(taskmaster.SystemPrompt, "- A: First stage");
            testCase.verifySubstring(taskmaster.SystemPrompt, "- B: Second stage");
        end

        function createTaskmaster_runToGoal_validNode_returnsObservation(testCase)
            tokenInfo = struct("Tokens", struct( ...
                "NumInputTokens", 50, "NumOutputTokens", 20, ...
                "NumTotalTokens", 70, "NumCachedInputTokens", 0));
            toolCallMsg = aisdk.LLMToolCallMessage( ...
                "runToGoal", struct("goalNode","B"), ToolCallID="call_1");
            doneMsg = aisdk.LLMTextMessage("Done.", Role="assistant");

            outputs = repmat({{"Done.", doneMsg, tokenInfo}}, 1, 5);
            outputs{1} = {"", toolCallMsg, tokenInfo};

            [~, taskmaster] = buildTaskmaster(outputs);

            taskmaster.Workspace.agentGraphPrompt = "Run the pipeline";
            response = taskmaster.run("Execute goal B", DisplayMode="off");

            testCase.verifySubstring(string(response), "Done.");
        end
    end
end

function [client, taskmaster] = buildTaskmaster(generateOutputs)
    arguments
        generateOutputs cell = {}
    end
    client = MockClient();
    client.GenerateOutputs = generateOutputs;
    nodes = [
        agentgraph.FunctionNode("A", @(w) deal("resultA",w))
        agentgraph.FunctionNode("B", @(w) deal("resultB",w))
    ];
    nodes(1).Description = "First stage";
    nodes(2).Description = "Second stage";
    edges = ["A","B"];
    graph = agentgraph.AgentGraph(nodes, edges);
    allTools = aisdk.llms.tool.LLMTool.empty(1,0);
    workspace = struct();

    taskmaster = agentgraph.createTaskmaster(client, graph, allTools, workspace);
end
