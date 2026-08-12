%[text] # Nested Tools and Subagents Example
%[text] This is a somewhat artificial example with a "tool provider" tool that return to a top level agents either arithmetic operation tools or a string manipulation tools, depending on what it's been asked to do. It then works out the solution to the user problem using those newly-acquired tools in a subagent.
%%
%[text] ## Set Up Client
topLevelClient = aisdk.LLMClient("openai", "gpt-4.1-mini");
%%
%[text] ## Implement Functions for Tools to Use
function [output, workspace] = toolProvider(workspace, type)
% Tool for acquiring tools for either string manipulations or arithmetic operations. Use input 'string' for string manipulation tools and  'number' for arithmetic operations.
    arguments
        workspace(1,1) struct
        type(1,1) string
    end
    if type == "string"
        tools = aisdk.LLMTool(@concatenateStrings);
    elseif type == "number"
        tools = aisdk.LLMTool(@sumOfTwoNumbers);
        tools(end+1) = aisdk.LLMTool(@getRandomInteger);
    else
        output.error = "No suitable tools found";
        return;
    end
    output = "Added tools :" + join([tools.Name], ", ");
    workspace.Tools = tools;
end

function str = concatenateStrings(a, b)
% Concatenate two strings
    arguments
        a(1,1) string
        b(1,1) string
    end
    str = a+b;
end

function c = sumOfTwoNumbers(a, b)
% Compute the sum of two numbers
    arguments
        a(1,1) double
        b(1,1) double
    end
    c = a+b;
end

function x = getRandomInteger()
% Get random integer between 1 and 10
    x = randi(10,1);
end

function [observation, workspace] = subAgent(workspace, systemPrompt, prompt)
% Tool for delegating jobs to a sub-process with a set of tools
    arguments
        workspace(1,1) struct
        systemPrompt
        prompt
    end
    if ~isfield(workspace, "Tools")
        error("Context must contain a Tools field");
    end
    llmOpts = aisdk.LLMClient("openai", "gpt-4.1-mini");
    subAgent = aisdk.AIAgent(llmOpts, SystemPrompt=systemPrompt, ...
        Tools=workspace.Tools, ...
        Workspace=workspace);
    observation = subAgent.run(prompt);
    workspace = subAgent.Workspace;
end
%%
%[text] ## **Set up tools and the "system prompt" for the reAct loop**
topLevelTools = aisdk.LLMTool(@toolProvider, Workspace="agent");
topLevelTools(end+1) = aisdk.LLMTool(@subAgent, Workspace="agent");

topLevelPrompt = "You are an assistant who has two sets of tools available for either string manipulations or arithmetic operations." + ...
        "You can acquire these tools using the toolProvider tool. " + ...
        "Given a problem, devise a strategy for solving the problem using the tools available to you. " + ...
        "If you are using a tool, delegate the use of that tool to a subagent with instructions of what you want to get done. " +  ...
        "Do not answer directly questions you should use tools for. ";
%%
%[text] ## Run Agent
topLevelAgent = aisdk.AIAgent(topLevelClient, SystemPrompt=topLevelPrompt, ...
    Tools=topLevelTools);
prompt = "Create two random integers between 1 and 10, tell me what they are and compute their sum?";
output = topLevelAgent.run(prompt) %[output:542cc9f9] %[output:654a7ec5]
%%
%[text] Run a different prompt to trigger the string manipulation tool.
prompt2 = "Concatenate the strings 'acdc' and 'abba'";
output2 = topLevelAgent.run(prompt2) %[output:9c544e7d] %[output:99c8073d]
%[text] *Copyright 2026 The MathWorks, Inc.*

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":40}
%---
%[output:542cc9f9]
%   data: {"dataType":"text","outputData":{"text":"[think]\n[call function toolProvider with inputs {\"type\":\"number\"}]\n[function return] {\"output\":\"Added tools :sumOfTwoNumbers, getRandomInteger\"}\n[think]\n[call function subAgent with inputs {\"systemPrompt\":\"You have tools for creating random integers and computing sums of two numbers. Use one tool to get two random integers between 1 and 10, then use the sum tool to compute their sum.\",\"prompt\":\"Generate two random integers between 1 and 10, tell me what they are. Then compute their sum.\"}]\n[think]\n[call function getRandomInteger with inputs {}]\n[function return] {\"x\":10}\n[call function getRandomInteger with inputs {}]\n[function return] {\"x\":8}\n[think]\n[call function sumOfTwoNumbers with inputs {\"a\":10,\"b\":8}]\n[function return] {\"c\":18}\n[think]\nThe two random integers are 10 and 8. Their sum is 18.\n[function return] {\"observation\":\"The two random integers are 10 and 8. Their sum is 18.\"}\n[think]\nThe two random integers I created are 10 and 8. Their sum is 18.\n","truncated":false}}
%---
%[output:654a7ec5]
%   data: {"dataType":"textualVariable","outputData":{"name":"output","value":"\"The two random integers I created are 10 and 8. Their sum is 18.\""}}
%---
%[output:9c544e7d]
%   data: {"dataType":"text","outputData":{"text":"[think]\n[call function toolProvider with inputs {\"type\":\"string\"}]\n[function return] {\"output\":\"Added tools :concatenateStrings\"}\n[think]\n[call function subAgent with inputs {\"systemPrompt\":\"You have a tool to concatenate two strings. Use the tool to concatenate the strings 'acdc' and 'abba' and provide the result.\",\"prompt\":\"Concatenate the strings 'acdc' and 'abba'.\"}]\n[think]\n[call function concatenateStrings with inputs {\"a\":\"acdc\",\"b\":\"abba\"}]\n[function return] {\"str\":\"acdcabba\"}\n[think]\nThe concatenated result of the strings 'acdc' and 'abba' is 'acdcabba'.\n[function return] {\"observation\":\"The concatenated result of the strings 'acdc' and 'abba' is 'acdcabba'.\"}\n[think]\nThe concatenated result of the strings 'acdc' and 'abba' is 'acdcabba'.\n","truncated":false}}
%---
%[output:99c8073d]
%   data: {"dataType":"textualVariable","outputData":{"name":"output2","value":"\"The concatenated result of the strings 'acdc' and 'abba' is 'acdcabba'.\""}}
%---
