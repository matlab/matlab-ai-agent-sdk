%[text] # Solve Quadratic Equation Using an Agent
%[text] This example contains four steps:
%[text] - Define two mathematical tools for the agent to use
%[text] - Create an agent with the ability to call these tools
%[text] - Run the agent to solve a quadratic equation
%[text] - Display the agent's reasoning and final answer
%%
%[text] ## Define Tools
%[text] Create tools for solving quadratic equations and finding the smallest real number.
function obs = solveQuadraticEquation(a, b, c)
    arguments
        a(1,1) double
        b(1,1) double
        c(1,1) double
    end
    r = roots([a b c]);
    obs = jsonencode(string(r));
end

function obs = findSmallestReal(x1, x2)
    arguments
        x1(1,1) string
        x2(1,1) string
    end
    allRoots = [str2double(x1) str2double(x2)];
    realRoots = allRoots(imag(allRoots)==0);
    if isempty(realRoots)
        obs = "No real numbers.";
    else
        obs = jsonencode(min(realRoots));
    end
end

quadraticTool = aisdk.LLMTool(@solveQuadraticEquation, ...
    Description="Compute roots of ax^2 + bx + c = 0", ...
    InputArguments=struct("a", 1, "b", 2, "c", -3), ...
    RequiresApproval="never"); %[control:dropdown:tool1]{"position":[21,28]}

smallestTool = aisdk.LLMTool(@findSmallestReal, ...
    Description="Find smallest real number from two numbers", ...
    InputArguments=struct("x1", "1", "x2", "-3"), ...
    RequiresApproval="never"); %[control:dropdown:tool2]{"position":[21,28]}
%%
%[text] ## Create Agent
%[text] Create an LLM client and agent with a system prompt.
api = "openai"; %[control:dropdown:api]{"position":[7,15]}
model = "gpt-4.1-mini"; %[control:dropdown:model]{"position":[9,23]}
client = aisdk.LLMClient(api, model);

systemPrompt = "You are a mathematical reasoning agent. " + ...
    "Think step-by-step, use tools when needed, and provide a final answer.";

agent = aisdk.AIAgent(client, systemPrompt, [quadraticTool, smallestTool]);
%%
%[text] ## Run Agent
%[text] Ask the agent to find the smallest root. The agent will automatically reason through the steps.
userPrompt = "What is the smallest root of x^2+2x-3=0?";
disp("User: " + userPrompt) %[output:734686e1]

response = run(agent, userPrompt, MaxIterations=10);
disp("Agent: " + response) %[output:7087b699]
%[text] *Copyright 2026 The MathWorks, Inc.*

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":35}
%---
%[control:dropdown:tool1]
%   data: {"defaultValue":"\"Never\"","itemLabels":["\"Never\"","\"Always\""],"items":["\"Never\"","\"Always\""],"label":"RequiresApproval","run":"Section"}
%---
%[control:dropdown:tool2]
%   data: {"defaultValue":"\"Never\"","itemLabels":["\"Never\"","\"Always\""],"items":["\"Never\"","\"Always\""],"label":"RequiresApproval","run":"Section"}
%---
%[control:dropdown:api]
%   data: {"defaultValue":"\"openai\"","itemLabels":["openai","ollama"],"items":["\"openai\"","\"ollama\""],"label":"provider","run":"Section"}
%---
%[control:dropdown:model]
%   data: {"defaultValue":"\"gpt-4.1-mini\"","itemLabels":["gpt-4.1-mini","qwen3"],"items":["\"gpt-4.1-mini\"","\"qwen3\""],"label":"model","run":"Section"}
%---
%[output:734686e1]
%   data: {"dataType":"text","outputData":{"text":"User: What is the smallest root of x^2+2x-3=0?\n","truncated":false}}
%---
%[output:7087b699]
%   data: {"dataType":"text","outputData":{"text":"Agent: The smallest root of the equation x^2 + 2x - 3 = 0 is -3.\n","truncated":false}}
%---
