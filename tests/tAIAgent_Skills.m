classdef tAIAgent_Skills < matlab.unittest.TestCase
% Tests for AIAgent skills integration.

%   Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addResourcesToPath(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(fileparts(mfilename('fullpath')), "helpers")));
        end
    end

    % Tests that exercise AIAgent alone, with no SkillRegistry involved.
    methods (Test, TestTags = {'Unit'})

        function constructWithoutSkillDirectories_hasNoLoadSkillTool(testCase)
            agent = aisdk.AIAgent(MockClient());
            testCase.verifyError( ...
                @() agent.Tools.select("loadSkill"), ...
                "aisdk:invalidFunctionCall");
        end

        function skills_withoutSkillDirectories_returnsEmpty(testCase)
            agent = aisdk.AIAgent(MockClient());
            testCase.verifyEqual(agent.Skills, string.empty(0, 1));
        end

        function loadSkill_noRegistry_throwsNoSkillsConfigured(testCase)
            agent = aisdk.AIAgent(MockClient(), DisplayMode="off");
            testCase.verifyError( ...
                @() agent.loadSkill("anything"), ...
                "aisdk:skills:NoSkillsConfigured");
        end

    end

    % Tests that pair a real AIAgent with a real SkillRegistry, and in many
    % cases drive the full run loop or touch the filesystem.
    methods (Test, TestTags = {'Integration'})

        %% Construction & tool wiring

        function constructWithSkillDirectories_addsLoadSkillToTools(testCase)
            tmpDir = testCase.createTemporaryFolder();
            skillDir = fullfile(tmpDir, "my-skill");
            mkdir(skillDir);
            writelines(["---"; "name: my-skill"; "description: desc"; "---"; "Body"], ...
                fullfile(skillDir, "SKILL.md"));

            agent = aisdk.AIAgent(MockClient(), SkillDirectories=tmpDir);
            tool = agent.Tools.select("loadSkill");
            testCase.verifyEqual(tool.Name, "loadSkill");
        end

        function constructWithSkillRegistry_addsLoadSkillToTools(testCase)
            reg = testCase.createStubRegistry();
            agent = aisdk.AIAgent(MockClient());
            agent.SkillRegistry = reg;
            tool = agent.Tools.select("loadSkill");
            testCase.verifyEqual(tool.Name, "loadSkill");
        end

        function setSkillDirectoriesAfterConstruction_addsLoadSkillTool(testCase)
            tmpDir = testCase.createTemporaryFolder();
            skillDir = fullfile(tmpDir, "my-skill");
            mkdir(skillDir);
            writelines(["---"; "name: my-skill"; "description: desc"; "---"; "Body"], ...
                fullfile(skillDir, "SKILL.md"));

            agent = aisdk.AIAgent(MockClient());
            agent.SkillDirectories = tmpDir;
            tool = agent.Tools.select("loadSkill");
            testCase.verifyEqual(tool.Name, "loadSkill");
        end

        function setSkillDirectoriesToInvalidPath_preservesPreviousConfiguration(testCase)
            tmpDir = testCase.createTemporaryFolder();
            skillDir = fullfile(tmpDir, "my-skill");
            mkdir(skillDir);
            writelines(["---"; "name: my-skill"; "description: desc"; "---"; "Body"], ...
                fullfile(skillDir, "SKILL.md"));

            agent = aisdk.AIAgent(MockClient(), SkillDirectories=tmpDir);
            missingDir = replace(fullfile(tmpDir, "missing"), filesep, "/");
            testCase.verifyError( ...
                @() testCase.assignSkillDirectories(agent, missingDir), ...
                "aisdk:skills:DirectoryNotFound");
            testCase.verifyEqual(agent.SkillDirectories, string(tmpDir));
            testCase.verifyEqual(agent.Skills, "my-skill");
            testCase.verifyEqual(agent.Tools.select("loadSkill").Name, "loadSkill");
        end

        %% Skills property

        function skills_withSkillDirectories_returnsSkillNames(testCase)
            reg = testCase.createStubRegistry();
            agent = aisdk.AIAgent(MockClient());
            agent.SkillRegistry = reg;
            testCase.verifyEqual(sort(agent.Skills), sort(["valid-skill"; "another-skill"]));
        end

        function skills_afterSettingSkillDirectoriesToEmpty_returnsEmpty(testCase)
            tmpDir = testCase.createTemporaryFolder();
            skillDir = fullfile(tmpDir, "my-skill");
            mkdir(skillDir);
            writelines(["---"; "name: my-skill"; "description: desc"; "---"; "Body"], ...
                fullfile(skillDir, "SKILL.md"));

            agent = aisdk.AIAgent(MockClient(), SkillDirectories=tmpDir);
            testCase.verifyNotEmpty(agent.Skills);
            agent.SkillDirectories = string.empty(1, 0);
            testCase.verifyEmpty(agent.Skills);
        end

        function skills_registryWithNoSkills_returnsEmptyColumn(testCase)
            emptyDiscoverFcn = @(~) string.empty(1,0);
            tmpDir = testCase.createTemporaryFolder();
            reg = aisdk.internal.SkillRegistry(tmpDir, ...
                DiscoverSkillsFcn=emptyDiscoverFcn);
            agent = aisdk.AIAgent(MockClient());
            agent.SkillRegistry = reg;
            testCase.verifyEqual(agent.Skills, string.empty(0, 1));
        end

        %% System prompt

        function systemPrompt_includesSkillCatalog(testCase)
            reg = testCase.createStubRegistry();
            client = MockClient();
            client.GenerateOutputs = {testCase.textResponse("Hello")};
            agent = aisdk.AIAgent(client, SystemPrompt="You are helpful.", ...
                DisplayMode="off");
            agent.SkillRegistry = reg;
            run(agent, "hi");
            msgs = client.GenerateInputs{1};
            systemContent = msgs(1).Text;
            testCase.verifySubstring(systemContent, "valid-skill");
            testCase.verifySubstring(systemContent, "another-skill");
        end

        %% run -- LLM-triggered loadSkill

        function run_llmCallsLoadSkillWithName_returnsSkillBody(testCase)
            reg = testCase.createStubRegistry();
            client = MockClient();
            client.GenerateOutputs = {
                testCase.toolCallResponse("loadSkill", struct('name', 'valid-skill'), "call_1")
                testCase.textResponse("Done.")
            };
            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.SkillRegistry = reg;
            run(agent, "help");
            toolResults = testCase.getToolResults(agent);
            testCase.verifySubstring(toolResults(1).Result, ...
                "This is the body of the valid skill");
        end

        function run_llmCallsLoadSkillWithResourcePath_returnsResourceContent(testCase)
            reg = testCase.createRegistryWithResource();
            client = MockClient();
            client.GenerateOutputs = {
                testCase.toolCallResponse("loadSkill", struct('name', 'valid-skill/references/guide.md'), "call_1")
                testCase.textResponse("Done.")
            };
            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.SkillRegistry = reg;
            run(agent, "help");
            toolResults = testCase.getToolResults(agent);
            testCase.verifySubstring(toolResults(1).Result, ...
                "This is reference content");
        end

        function run_llmCallsLoadSkillUnknownName_returnsErrorResultToLLM(testCase)
            reg = testCase.createStubRegistry();
            client = MockClient();
            client.GenerateOutputs = {
                testCase.toolCallResponse("loadSkill", struct('name', 'nonexistent'), "call_1")
                testCase.textResponse("Sorry.")
            };
            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.SkillRegistry = reg;
            response = run(agent, "help");
            toolResults = testCase.getToolResults(agent);
            testCase.verifyNotEmpty(toolResults);
            testCase.verifyFalse(contains(toolResults(1).Result, ...
                "This is the body of the valid skill"));
            testCase.verifyEqual(response, "Sorry.");
        end

        %% loadSkill method

        function loadSkill_injectsSkillBodyAsToolResult(testCase)
            reg = testCase.createStubRegistry();
            agent = aisdk.AIAgent(MockClient(), DisplayMode="off");
            agent.SkillRegistry = reg;
            agent.loadSkill("valid-skill");
            toolResults = testCase.getToolResults(agent);
            testCase.verifySubstring(toolResults(1).Result, ...
                "This is the body of the valid skill");
        end

        function loadSkill_withDetailedDisplay_printsLoadSkillCall(testCase)
            reg = testCase.createStubRegistry();
            agent = aisdk.AIAgent(MockClient(), DisplayMode="detailed");
            agent.SkillRegistry = reg;
            output = evalc('agent.loadSkill("valid-skill")');
            testCase.verifySubstring(output, "[call function loadSkill");
            testCase.verifySubstring(output, "[function return]");
        end

        function loadSkill_unknownName_throwsSkillNotFound(testCase)
            reg = testCase.createStubRegistry();
            agent = aisdk.AIAgent(MockClient(), DisplayMode="off");
            agent.SkillRegistry = reg;
            testCase.verifyError( ...
                @() agent.loadSkill("nonexistent"), ...
                "aisdk:skills:SkillNotFound");
        end

        function loadSkill_calledTwice_isAdditive(testCase)
            reg = testCase.createStubRegistry();
            agent = aisdk.AIAgent(MockClient(), DisplayMode="off");
            agent.SkillRegistry = reg;
            agent.loadSkill("valid-skill");
            agent.loadSkill("another-skill");
            toolResults = testCase.getToolResults(agent);
            testCase.verifyLength(toolResults, 2);
            testCase.verifySubstring(toolResults(1).Result, ...
                "This is the body of the valid skill");
            testCase.verifySubstring(toolResults(2).Result, ...
                "Body of another skill");
        end

        function loadSkill_calledTwiceWithSameName_hasUniqueToolCallIDs(testCase)
            reg = testCase.createStubRegistry();
            agent = aisdk.AIAgent(MockClient(), DisplayMode="off");
            agent.SkillRegistry = reg;
            agent.loadSkill("valid-skill");
            agent.loadSkill("valid-skill");
            msgs = agent.Messages;
            callMsgs = msgs(arrayfun(@(m) isa(m, 'aisdk.LLMToolCallMessage'), msgs));
            ids = [callMsgs.ToolCallID];
            testCase.verifyEqual(numel(ids), numel(unique(ids)));
        end

        function loadSkill_withResourcePath_injectsResourceContent(testCase)
            reg = testCase.createRegistryWithResource();
            agent = aisdk.AIAgent(MockClient(), DisplayMode="off");
            agent.SkillRegistry = reg;
            agent.loadSkill("valid-skill/references/guide.md");
            toolResults = testCase.getToolResults(agent);
            testCase.verifyLength(toolResults, 1);
            testCase.verifySubstring(toolResults(1).Result, ...
                "This is reference content for the valid skill.");
        end

        function loadSkill_withResourcePath_toolCallIDHasNoPathSeparators(testCase)
            % Bedrock's toolUseId pattern allows only a-zA-Z0-9_.:- so the
            % generated ID must not carry separators from the resource path.
            reg = testCase.createRegistryWithResource();
            agent = aisdk.AIAgent(MockClient(), DisplayMode="off");
            agent.SkillRegistry = reg;
            agent.loadSkill("valid-skill/references/guide.md");
            msgs = agent.Messages;
            callMsgs = msgs(arrayfun(@(m) isa(m, 'aisdk.LLMToolCallMessage'), msgs));
            testCase.verifyMatches(callMsgs(1).ToolCallID, "^[a-zA-Z0-9_.:-]+$");
        end

        function loadSkill_afterStale_rescansAndFindsNewSkill(testCase)
            % run rescans a stale registry, so loadSkill must too — otherwise
            % a skill added after construction errors here but resolves in run.
            callCount = containers.Map('KeyType', 'char', 'ValueType', 'double');
            callCount('n') = 0;
            discoverFcn = @(~) testCase.discoverMoreOnRescan(callCount);

            contents = dictionary( ...
                ["/path/skill-a/SKILL.md", "/path/skill-b/SKILL.md"], ...
                [sprintf("---\nname: skill-a\ndescription: Skill A\n---\nBody A"), ...
                 sprintf("---\nname: skill-b\ndescription: Skill B\n---\nBody B")]);
            fileReadFcn = @(p) contents(string(p));

            timestampCounter = containers.Map('KeyType', 'char', 'ValueType', 'double');
            timestampCounter('n') = 0;
            lastModFcn = @(~) testCase.advancingTimestamp(timestampCounter);

            reg = aisdk.internal.SkillRegistry(pwd, ...
                DiscoverSkillsFcn=discoverFcn, FileReadFcn=fileReadFcn, LastModifiedFcn=lastModFcn);

            agent = aisdk.AIAgent(MockClient(), DisplayMode="off");
            agent.SkillRegistry = reg;
            agent.loadSkill("skill-b");

            toolResults = testCase.getToolResults(agent);
            testCase.verifyLength(toolResults, 1);
            testCase.verifySubstring(toolResults(1).Result, "Body B");
        end

        function loadSkill_emptyRegistry_throwsSkillNotFound(testCase)
            emptyDiscoverFcn = @(~) string.empty(1,0);
            tmpDir = testCase.createTemporaryFolder();
            reg = aisdk.internal.SkillRegistry(tmpDir, ...
                DiscoverSkillsFcn=emptyDiscoverFcn);
            agent = aisdk.AIAgent(MockClient(), DisplayMode="off");
            agent.SkillRegistry = reg;
            testCase.verifyError( ...
                @() agent.loadSkill("anything"), ...
                "aisdk:skills:SkillNotFound");
        end

        %% run -- auto-add on Tools override

        function run_withToolsOverride_stillHasLoadSkillTool(testCase)
            reg = testCase.createStubRegistry();
            client = MockClient();
            client.GenerateOutputs = {testCase.textResponse("Done")};
            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.SkillRegistry = reg;

            userTool = aisdk.LLMTool(@(x) x, Name="myTool", ...
                Description="test", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="string"), ...
                OutputArguments=aisdk.LLMToolArgument("out", DataType="string"));
            run(agent, "do something", Tools=userTool);

            toolsUsed = client.getGenerateTools(1);
            toolNames = [toolsUsed.Name];
            testCase.verifyTrue(ismember("loadSkill", toolNames));
            testCase.verifyTrue(ismember("myTool", toolNames));
        end

        function run_withEmptyToolsOverride_stillHasLoadSkillTool(testCase)
            reg = testCase.createStubRegistry();
            client = MockClient();
            client.GenerateOutputs = {testCase.textResponse("Done")};
            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.SkillRegistry = reg;
            run(agent, "do something", Tools=aisdk.tool.LLMTool.empty(1,0));

            toolsUsed = client.getGenerateTools(1);
            toolNames = [toolsUsed.Name];
            testCase.verifyTrue(ismember("loadSkill", toolNames));
        end

        %% Construction edge cases

        function constructWithSkillRegistryAndUserTools_preservesBoth(testCase)
            reg = testCase.createStubRegistry();
            userTool = aisdk.LLMTool(@(x) x, Name="myTool", ...
                Description="A user tool", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="string"), ...
                OutputArguments=aisdk.LLMToolArgument("out", DataType="string"));
            agent = aisdk.AIAgent(MockClient(), Tools=userTool);
            agent.SkillRegistry = reg;
            testCase.verifyEqual(agent.Tools.select("loadSkill").Name, "loadSkill");
            testCase.verifyEqual(agent.Tools.select("myTool").Name, "myTool");
        end

        function setSkillDirectoriesToEmpty_removesLoadSkillTool(testCase)
            tmpDir = testCase.createTemporaryFolder();
            skillDir = fullfile(tmpDir, "my-skill");
            mkdir(skillDir);
            writelines(["---"; "name: my-skill"; "description: desc"; "---"; "Body"], ...
                fullfile(skillDir, "SKILL.md"));

            agent = aisdk.AIAgent(MockClient(), SkillDirectories=tmpDir);
            agent.SkillDirectories = string.empty(1, 0);
            testCase.verifyError( ...
                @() agent.Tools.select("loadSkill"), ...
                "aisdk:invalidFunctionCall");
        end

        %% System prompt edge cases

        function systemPrompt_noSystemPromptNVP_stillIncludesCatalog(testCase)
            reg = testCase.createStubRegistry();
            client = MockClient();
            client.GenerateOutputs = {testCase.textResponse("Hello")};
            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.SkillRegistry = reg;
            run(agent, "hi");
            msgs = client.GenerateInputs{1};
            systemContent = msgs(1).Text;
            testCase.verifySubstring(systemContent, "valid-skill");
        end

        %% run -- no rescan when not stale

        function run_notStale_doesNotRescan(testCase)
            callCount = containers.Map('KeyType', 'char', 'ValueType', 'double');
            callCount('n') = 0;
            discoverFcn = @(~) testCase.trackingDiscoverFcn(callCount);
            fileReadFcn = @(~) sprintf("---\nname: skill\ndescription: d\n---\nBody");
            lastModFcn = @(~) 1;

            reg = aisdk.internal.SkillRegistry(pwd, ...
                DiscoverSkillsFcn=discoverFcn, FileReadFcn=fileReadFcn, LastModifiedFcn=lastModFcn);

            client = MockClient();
            client.GenerateOutputs = {
                testCase.textResponse("First")
                testCase.textResponse("Second")
            };
            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.SkillRegistry = reg;
            run(agent, "first");
            agent.Messages = aisdk.message.LLMMessage.empty(1, 0);
            run(agent, "second");
            testCase.verifyEqual(callCount('n'), 1);
        end

        %% run -- rescan

        function run_afterStale_rescansAndUpdatesCatalog(testCase)
            callCount = containers.Map('KeyType', 'char', 'ValueType', 'double');
            callCount('n') = 0;
            discoverFcn = @(~) testCase.discoverMoreOnRescan(callCount);

            contents = dictionary( ...
                ["/path/skill-a/SKILL.md", "/path/skill-b/SKILL.md"], ...
                [sprintf("---\nname: skill-a\ndescription: Skill A\n---\nBody A"), ...
                 sprintf("---\nname: skill-b\ndescription: Skill B\n---\nBody B")]);
            fileReadFcn = @(p) contents(string(p));

            timestampCounter = containers.Map('KeyType', 'char', 'ValueType', 'double');
            timestampCounter('n') = 0;
            lastModFcn = @(~) testCase.advancingTimestamp(timestampCounter);

            reg = aisdk.internal.SkillRegistry(pwd, ...
                DiscoverSkillsFcn=discoverFcn, FileReadFcn=fileReadFcn, LastModifiedFcn=lastModFcn);

            client = MockClient();
            client.GenerateOutputs = {
                testCase.textResponse("First")
                testCase.textResponse("Second")
            };
            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.SkillRegistry = reg;
            run(agent, "first");

            agent.Messages = aisdk.message.LLMMessage.empty(1, 0);
            run(agent, "second");
            msgs = client.GenerateInputs{2};
            systemContent = msgs(1).Text;
            testCase.verifySubstring(systemContent, "skill-b");
        end

        function run_withToolsNVPAfterRescan_preservesUserTools(testCase)
            contents = dictionary( ...
                "/path/my-skill/SKILL.md", ...
                sprintf("---\nname: my-skill\ndescription: A skill\n---\nBody"));
            fileReadFcn = @(p) contents(string(p));

            timestampCounter = containers.Map('KeyType', 'char', 'ValueType', 'double');
            timestampCounter('n') = 0;
            lastModFcn = @(~) testCase.advancingTimestamp(timestampCounter);

            reg = aisdk.internal.SkillRegistry(pwd, ...
                DiscoverSkillsFcn=@(~) "/path/my-skill/SKILL.md", ...
                FileReadFcn=fileReadFcn, LastModifiedFcn=lastModFcn);

            client = MockClient();
            client.GenerateOutputs = {
                testCase.textResponse("First")
                testCase.textResponse("Second")
            };
            agent = aisdk.AIAgent(client, DisplayMode="off");
            agent.SkillRegistry = reg;

            userTool = aisdk.LLMTool(@(x) x, Name="myTool", ...
                Description="test", ...
                InputArguments=aisdk.LLMToolArgument("x", DataType="string"), ...
                OutputArguments=aisdk.LLMToolArgument("out", DataType="string"));
            run(agent, "first", Tools=userTool);
            run(agent, "second", Tools=userTool);

            toolsUsed = client.getGenerateTools(2);
            toolNames = [toolsUsed.Name];
            testCase.verifyTrue(ismember("myTool", toolNames));
            testCase.verifyTrue(ismember("loadSkill", toolNames));
        end
    end

    methods (Access = private, Static)
        function assignSkillDirectories(agent, paths)
            agent.SkillDirectories = paths;
        end

        function row = textResponse(text)
            row = {text, ...
                aisdk.LLMTextMessage(text, Role="assistant"), ...
                struct('Tokens', struct('NumInputTokens', 0, 'NumOutputTokens', 0, ...
                'NumTotalTokens', 0, 'NumCachedInputTokens', 0))};
        end

        function row = toolCallResponse(name, args, callID)
            row = {"", ...
                aisdk.LLMToolCallMessage(name, args, ToolCallID=callID), ...
                struct('Tokens', struct('NumInputTokens', 0, 'NumOutputTokens', 0, ...
                'NumTotalTokens', 0, 'NumCachedInputTokens', 0))};
        end
    end

    methods (Access = private)
        function reg = createStubRegistry(testCase) %#ok<MANU>
            paths = ["/path/valid-skill/SKILL.md", "/path/another-skill/SKILL.md"];
            bodyA = sprintf("---\nname: valid-skill\ndescription: A valid skill for testing\n---\nThis is the body of the valid skill.\n\nUse this skill to do valid things.");
            bodyB = sprintf("---\nname: another-skill\ndescription: Another skill without references\n---\nBody of another skill.");
            contents = dictionary(paths, [string(bodyA), string(bodyB)]);
            discoverFcn = @(~) paths;
            fileReadFcn = @(p) contents(string(p));
            reg = aisdk.internal.SkillRegistry(pwd, ...
                DiscoverSkillsFcn=discoverFcn, FileReadFcn=fileReadFcn, LastModifiedFcn=@(~) 1);
        end

        function reg = createRegistryWithResource(testCase)
            tmpDir = testCase.createTemporaryFolder();
            skillDir = fullfile(tmpDir, "valid-skill");
            mkdir(skillDir);
            refsDir = fullfile(skillDir, "references");
            mkdir(refsDir);
            writelines(["---"; "name: valid-skill"; "description: A valid skill"; "---"; "Body"], ...
                fullfile(skillDir, "SKILL.md"));
            writelines("This is reference content for the valid skill.", ...
                fullfile(refsDir, "guide.md"));
            reg = aisdk.internal.SkillRegistry(tmpDir);
        end

        function results = getToolResults(~, agent)
            msgs = agent.Messages;
            results = msgs([msgs.Role] == "tool");
        end

        function skillPaths = discoverMoreOnRescan(~, counter)
            counter('n') = counter('n') + 1;
            if counter('n') <= 1
                skillPaths = "/path/skill-a/SKILL.md";
            else
                skillPaths = ["/path/skill-a/SKILL.md", "/path/skill-b/SKILL.md"];
            end
        end

        function val = advancingTimestamp(~, counter)
            counter('n') = counter('n') + 1;
            val = counter('n');
        end

        function skillPaths = trackingDiscoverFcn(~, counter)
            counter('n') = counter('n') + 1;
            skillPaths = "/path/skill/SKILL.md";
        end
    end
end
