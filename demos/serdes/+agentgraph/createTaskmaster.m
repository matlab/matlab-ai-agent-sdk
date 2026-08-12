function taskmaster = createTaskmaster(client, graph, allTools, workspace)
%CREATETASKMASTER  Build an LLM taskmaster that re-drives a graph to a goal.
%
%   TASKMASTER = AGENTGRAPH.CREATETASKMASTER(CLIENT, GRAPH, ALLTOOLS, WORKSPACE)
%   returns an aisdk.AIAgent whose single tool, runToGoal(goalNode), runs GRAPH
%   up to a goal node (that node + its ancestors) and reports the resulting
%   observation. The taskmaster reads that observation and decides whether to
%   re-drive (iterate) or advance the goal -- a runtime, metric-gated decision
%   the fixed toposort flow cannot express.
%
%   This factory is DOMAIN-AGNOSTIC: it knows only the runToGoal mechanic. All
%   domain knowledge comes from the graph itself -- each node's Description (set
%   in the graph config) tells the taskmaster what that goal node is FOR, so no
%   per-graph hint is written here or at the call site. The run's actual goal
%   and success criteria come from the user prompt (taskmaster.Workspace.goalPrompt,
%   set by the caller before running -- see runDemoTaskmaster.m).
    arguments
        client
        graph (1,1) agentgraph.AgentGraph
        allTools (1,:) aisdk.llms.tool.LLMTool
        workspace struct
    end

    % Stash what runToGoal needs on the workspace.
    workspace.goalGraph  = graph;
    workspace.goalClient = client;
    workspace.goalTools  = allTools;
    workspace.agentGraphPrompt = "";    % set by the caller before running
    workspace.goalLog    = {};          % trajectory of goal-drives

    nodeList  = graph.dependencyString();       % "build -> analyse -> optimize -> plot"
    nodeRoles = graph.describeNodes();   % one "- name: role" line per node

    toolDesc = "Run the graph up to a goal node: runs that node and all its " + ...
        "ancestors (from the start each drive) and returns the resulting " + ...
        "observation. Read the observation and, if the goal is not yet met, " + ...
        "re-drive (pass taskmasterHint to steer the next attempt) or advance to a later " + ...
        "goal node. Valid goalNode values, in dependency order:" + newline + nodeRoles;

    runToGoalTool = aisdk.LLMTool(@runToGoal, ...
        Description=toolDesc, ...
        InputArguments=[ ...
            aisdk.LLMToolArgument("goalNode", DataType="string", Required=true, ...
                Description="Target node to run to. One of: " + nodeList + "."), ...
            aisdk.LLMToolArgument("taskmasterHint", DataType="string", Required=false, ...
                NameValue=true, ...
                Description="Optional hint appended to the agentGraphPrompt " + ...
                    "on this drive, e.g. 'push the key parameter higher'.")], ...
        OutputArguments=aisdk.LLMToolArgument("observation", DataType="string", ...
            Description="What the drive ran and the resulting metrics."), ...
        Workspace="agent", RequiresApproval="never");

    promptDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), "prompts");
    rawPrompt = string(fileread(fullfile(promptDir, "taskmaster.md")));
    systemPrompt = replace(rawPrompt, "{{nodeRoles}}", nodeRoles);

    taskmaster = aisdk.AIAgent(client, ...
        SystemPrompt  = systemPrompt, ...
        Tools         = runToGoalTool, ...
        Workspace     = workspace, ...
        DisplayMode   = "detailed");
end

%% ---- Tool (local function) ----------------------------------------------
function [observation, workspace] = runToGoal(workspace, goalNode, nvp)
%RUNTOGOAL  Taskmaster tool: run the graph to GOALNODE and report the observation.
    arguments
        workspace struct
        goalNode (1,1) string
        nvp.taskmasterHint (1,1) string = ""
    end

    graph = workspace.goalGraph;

    % Friendly validation: the SDK has no schema enum for goalNode, so guard here
    % and return a retryable message rather than letting dfsearch crash.
    validNodes = graph.executionOrder();
    if ~ismember(goalNode, validNodes)
        observation = sprintf("'%s' is not a node. Valid nodes: %s.", ...
            goalNode, strjoin(validNodes, ", "));
        return;
    end

    % Which nodes this drive will run (goal + ancestors).
    willRun = graph.executionOrder(goalNode);

    agentGraphPrompt = workspace.agentGraphPrompt;
    if agentGraphPrompt == ""
        agentGraphPrompt = "Complete your stage for this task.";
    end
    if nvp.taskmasterHint ~= ""
        agentGraphPrompt = agentGraphPrompt + newline + "Hint: " + nvp.taskmasterHint;
    end

    [result, workspace] = graph.run( ...
        workspace.goalClient, agentGraphPrompt, workspace, workspace.goalTools, ...
        GoalNode=goalNode);

    % Log the drive (trajectory surfaced after the run).
    entry.goalNode = goalNode;
    entry.ranNodes = willRun;
    workspace.goalLog{end+1} = entry;

    observation = sprintf("Ran to '%s' (executed: %s).%s%s", ...
        goalNode, strjoin(willRun, ", "), newline, result);
end
