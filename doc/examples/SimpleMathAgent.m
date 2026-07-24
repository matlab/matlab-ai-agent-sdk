%[text] # Solve Quadratic Equation Using an Agent
%[text] This example contains four steps:
%[text] - Define two mathematical tools for the agent to use
%[text] - Create an agent with the ability to call these tools
%[text] - Run the agent to solve a quadratic equation
%[text] - Display the agent's reasoning and final answer \
%%
%[text] ## Define Tools
%[text] Create tools for solving quadratic equations and finding the smallest real number.
function result = solveQuadraticEquation(a, b, c)
% Compute roots of ax^2 + bx + c = 0
    arguments
        a(1,1) double
        b(1,1) double
        c(1,1) double
    end
    r = roots([a b c]);
    result = jsonencode(string(r));
end

function result = findSmallestReal(x1, x2)
% Find smallest real number from two numbers
    arguments
        x1(1,1) string
        x2(1,1) string
    end
    allRoots = [str2double(x1) str2double(x2)];
    realRoots = allRoots(imag(allRoots)==0);
    if isempty(realRoots)
        result = "No real numbers.";
    else
        result = jsonencode(min(realRoots));
    end
end

quadraticTool = aisdk.LLMTool(@solveQuadraticEquation, ...
    RequiresApproval="never"); %[control:dropdown:tool1]{"position":[22,29]}

smallestTool = aisdk.LLMTool(@findSmallestReal, ...
    RequiresApproval="never"); %[control:dropdown:tool2]{"position":[22,29]}
%%
%[text] ## Create Agent
%[text] Create an LLM client and agent with a system prompt.
api = "openai"; %[control:dropdown:api]{"position":[7,15]}
model = "gpt-4.1-mini"; %[control:dropdown:model]{"position":[9,23]}
client = aisdk.LLMClient(api, model);

systemPrompt = "You are a mathematical reasoning agent. " + ...
    "Think step-by-step, use tools when needed, and provide a final answer.";

agent = aisdk.AIAgent(client, SystemPrompt=systemPrompt, Tools=[quadraticTool, smallestTool]);
%%
%[text] ## Run Agent
%[text] Ask the agent to find the smallest root. The agent will automatically reason through the steps.
userPrompt = "What is the smallest root of x^2+2x-3=0?";
disp("User: " + userPrompt) %[output:734686e1]

response = run(agent, userPrompt, MaxIterations=10); %[output:7087b699]
disp("Agent: " + response) %[output:56d3774a]
%[text] *Copyright 2026 The MathWorks, Inc.*

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":35}
%---
%[control:dropdown:tool1]
%   data: {"defaultValue":"\"never\"","itemLabels":["always","once","never"],"items":["\"always\"","\"once\"","\"never\""],"label":"RequiresApproval","run":"Section"}
%---
%[control:dropdown:tool2]
%   data: {"defaultValue":"\"never\"","itemLabels":["always","once","never"],"items":["\"always\"","\"once\"","\"never\""],"label":"RequiresApproval","run":"Section"}
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
%   data: {"dataType":"text","outputData":{"text":"[think]\n[call function solveQuadraticEquation with inputs {\"a\":1,\"b\":2,\"c\":-3}]\n[function return] {\"result\":\"[\\\"-3\\\",\\\"1\\\"]\"}\n[think]\n[call function findSmallestReal with inputs {\"x1\":\"-3\",\"x2\":\"1\"}]\n[function return] {\"result\":\"-3\"}\n[think]\nThe smallest root of the equation x^2 + 2x - 3 = 0 is -3.\n","truncated":false}}
%---
%[output:56d3774a]
%   data: {"dataType":"text","outputData":{"text":"Agent: The smallest root of the equation x^2 + 2x - 3 = 0 is -3.\n","truncated":false}}
%---
