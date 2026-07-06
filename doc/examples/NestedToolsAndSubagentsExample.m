%[text] # Nested Tools and Subagents Example
%[text] This is a somewhat artificial example with a "tool provider" tool that return to a top level agents either arithmetic operation tools or a string manipulation tools, depending on what it's been asked to do. It then works out the solution to the user problem using those newly-acquired tools in a subagent.
%[text] ## Implement Functions for Tools to Use
%[text] 
function [output, workspace] = toolProvider(workspace, type)
    arguments
        workspace(1,1) struct
        type(1,1) string
    end
    if type == "string"
        tools = aisdk.LLMTool(@concatenateStrings, ...
            Description="Tool for concatenating two strings", ...
            InputArguments=struct(a="abc", b="xyz"));
    elseif type == "number"
        tools = aisdk.LLMTool(@sumOfTwoNumbers, ...
            Description="Tool for computing the sum of two numbers", ...
            InputArguments=struct(a=1, b=2));
        tools(end+1) = aisdk.LLMTool(@getRandomInteger, ...
            Description="Tool for providing a random integer between 1 and 10");
    else
        output.error = "No suitable tools found";
        return;
    end
    output = "Added tools :" + join([tools.Name], ", ");
    workspace.Tools = tools;
end

function str = concatenateStrings(a, b)
    arguments
        a(1,1) string
        b(1,1) string
    end
    str = a+b;
end

function c = sumOfTwoNumbers(a, b)
    arguments
        a(1,1) double
        b(1,1) double
    end
    c = a+b;
end

function x = getRandomInteger()
    x = randi(10,1);
end

function [obs, workspace] = subAgent(workspace, systemPrompt, prompt)
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
    obs = subAgent.run(prompt);
    workspace = subAgent.Workspace;
end
%%
%[text] ## **Set up tools and the "system prompt" for the reAct loop**
topLevelTools = aisdk.LLMTool(@toolProvider, ...
    Description="Tool for acquiring tools for either string manipulations or arithmetic operations. Use input 'string' for string manipulation tools and  'number' for arithmetic operations.", ...
    InputArguments=aisdk.LLMToolArgument("ToolType", "DataType", "string"), ...
    Workspace="agent");
topLevelTools(end+1) = aisdk.LLMTool(@subAgent, ...
    Description="Tool for delegating jobs to a sub-process with a set of tools", ...
    InputArguments=struct("SystemPrompt", "abc", "Prompt", "abc"), ...
    Workspace="agent");
topLevelPrompt = "You are an assistant who has two sets of tools available for either string manipulations or arithmetic operations." + ...
        "You can acquire these tools using the toolProvider tool. " + ...
        "Given a problem, devise a strategy for solving the problem using the tools available to you. " + ...
        "If you are using a tool, delegate the use of that tool to a subagent with instructions of what you want to get done. " +  ...
        "Do not answer directly questions you should use tools for. ";
%%
%[text] ## Run Agent
topLevelClient = aisdk.LLMClient("openai", "gpt-4.1-mini");
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
%   data: {"dataType":"text","outputData":{"text":"[think]\n[call function toolProvider with inputs {\"ToolType\":\"number\"}]\n[function return] \"Added tools :sumOfTwoNumbers, getRandomInteger\"\n[think]\n[call function subAgent with inputs {\"SystemPrompt\":\"You have tools for generating random integers and for summing two numbers.\",\"Prompt\":\"Generate a random integer between 1 and 10.\"}]\n[think]\n[call function getRandomInteger with inputs {}]\n[function return] 7\n[think]\nThe random integer between 1 and 10 that I generated is 7. Would you like me to generate another one?\n[function return] \"The random integer between 1 and 10 that I generated is 7. Would you like me to generate another one?\"\n[call function subAgent with inputs {\"SystemPrompt\":\"You have tools for generating random integers and for summing two numbers.\",\"Prompt\":\"Generate a random integer between 1 and 10.\"}]\n[think]\n[call function getRandomInteger with inputs {}]\n[function return] 8\n[think]\nThe random integer generated between 1 and 10 is 8.\n[function return] \"The random integer generated between 1 and 10 is 8.\"\n[think]\n[call function subAgent with inputs {\"SystemPrompt\":\"You have tools for generating random integers and for summing two numbers.\",\"Prompt\":\"Given the two integers 7 and 8, compute their sum.\"}]\n[think]\n[call function sumOfTwoNumbers with inputs {\"a\":7,\"b\":8}]\n[function return] 15\n[think]\nThe sum of the integers 7 and 8 is 15.\n[function return] \"The sum of the integers 7 and 8 is 15.\"\n[think]\nThe two random integers I generated are 7 and 8. Their sum is 15.\n","truncated":false}}
%---
%[output:654a7ec5]
%   data: {"dataType":"textualVariable","outputData":{"name":"output","value":"\"The two random integers I generated are 7 and 8. Their sum is 15.\""}}
%---
%[output:9c544e7d]
%   data: {"dataType":"text","outputData":{"text":"[think]\n[call function toolProvider with inputs {\"ToolType\":\"string\"}]\n[function return] \"Added tools :concatenateStrings\"\n[think]\n[call function subAgent with inputs {\"SystemPrompt\":\"You have the tool to concatenate strings.\",\"Prompt\":\"Concatenate the strings 'acdc' and 'abba'.\"}]\n[think]\n[call function concatenateStrings with inputs {\"a\":\"acdc\",\"b\":\"abba\"}]\n[function return] \"acdcabba\"\n[think]\nThe concatenated string of 'acdc' and 'abba' is 'acdcabba'.\n[function return] \"The concatenated string of 'acdc' and 'abba' is 'acdcabba'.\"\n[think]\nThe concatenation of the strings 'acdc' and 'abba' is 'acdcabba'.\n","truncated":false}}
%---
%[output:99c8073d]
%   data: {"dataType":"textualVariable","outputData":{"name":"output2","value":"\"The concatenation of the strings 'acdc' and 'abba' is 'acdcabba'.\""}}
%---
