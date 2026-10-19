%[text] # Solve Simple Math Problem Using AI Agent
%[text] This example shows how to solve a simple math problem by using an AI agent.
%[text] Running this example requires an OpenAI® API key, but you can change the code to use a different API instead by changing the part of the code that calls the [`aisdk.LLMClient`](file:../../functions/aisdk.LLMClient.md) function.
%%
%[text] ## Connect to OpenAI
%[text] Using the OpenAI Chat Completions API requires an OpenAI API key. For information on how to obtain one, as well as pricing, terms and conditions of use, and available models, see the [OpenAI documentation](https://platform.openai.com/docs/overview).
%[text] Set your key as an environment variable in a `.env` file:
%[text] ```matlabCodeExample
%[text] OPENAI_API_KEY=<your key>
%[text] ```
%[text] Then add the file to the path and load it in MATLAB.
loadenv(".env")
%[text] Specify the API and model name. Create the LLM client by using the `aisdk.LLMClient` function.
api = "openai";
model = "gpt-4.1-mini";
client = aisdk.LLMClient(api,model);
%%
%[text] ## Define Tools
%[text] The math problem in this example is to find the smallest real root of a third-order polynomial. Start by defining the LLM tools that the agent can use to solve the problem.
%[text] Create a function that solves quadratic equations. To let the [`aisdk.LLMTool`](file:../../functions/aisdk.LLMTool.md) function automatically extract the function description, add a comment at the top of the function that describes the function. To let the `aisdk.LLMTool` function automatically extract information about the input arguments, add an `arguments` block.
function result = solveQuadraticEquation(a,b,c)
% Compute roots of ax^2 + bx + c = 0
    arguments
        a (1,1) double
        b (1,1) double
        c (1,1) double
    end
    r = roots([a b c]);
    result = jsonencode(string(r));
end
%[text] Create a function that finds the smallest real number from a list of two numbers that can be complex.
function result = findSmallestReal(x1,x2)
% Find smallest real number from two numbers
    arguments
        x1 (1,1) string
        x2 (1,1) string
    end
    allRoots = [str2double(x1) str2double(x2)];
    realRoots = allRoots(imag(allRoots)==0);
    if isempty(realRoots)
        result = "No real numbers.";
    else
        result = jsonencode(min(realRoots));
    end
end
%[text] Create LLM tools from these two functions by using the `aisdk.LLMTool` function. 
solveQuadraticEquationTool = aisdk.LLMTool(@solveQuadraticEquation,ApprovalRequest="never");
findSmallestRealTool = aisdk.LLMTool(@findSmallestReal,ApprovalRequest="never");
%%
%[text] ## Create Agent
%[text] Create an LLM client and agent with a system prompt.
systemPrompt = "You are a mathematical reasoning agent. " + ...
    "Think step-by-step, use tools when needed, and provide a final answer.";

agent = aisdk.AIAgent(client, SystemPrompt=systemPrompt, Tools=[solveQuadraticEquationTool, findSmallestRealTool]);
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
%[output:734686e1]
%   data: {"dataType":"text","outputData":{"text":"User: What is the smallest root of x^2+2x-3=0?\n","truncated":false}}
%---
%[output:7087b699]
%   data: {"dataType":"text","outputData":{"text":"[think]\n[call function solveQuadraticEquation with inputs {\"a\":1,\"b\":2,\"c\":-3}]\n[function return] {\"result\":\"[\\\"-3\\\",\\\"1\\\"]\"}\n[think]\n[call function findSmallestReal with inputs {\"x1\":\"-3\",\"x2\":\"1\"}]\n[function return] {\"result\":\"-3\"}\n[think]\nThe smallest root of the equation x^2 + 2x - 3 = 0 is -3.\n","truncated":false}}
%---
%[output:56d3774a]
%   data: {"dataType":"text","outputData":{"text":"Agent: The smallest root of the equation x^2 + 2x - 3 = 0 is -3.\n","truncated":false}}
%---
