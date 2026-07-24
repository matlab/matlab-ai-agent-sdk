%[text] # Supervisor-Subagent Example
%[text] This replicates this LangChain/LangGraph example: [https://github.com/langchain-ai/langgraph-supervisor-py](https://github.com/langchain-ai/langgraph-supervisor-py)
%%
%[text] Create tools for addition, multiplication and a "web search" (not to be confused with Responses API server-side tools).
function x = add(a, b)
% Add two numbers together
arguments
    a (1,1) double
    b (1,1) double
end
    x = a + b;
end

function x = multiply(a,b)
% Multiply two numbers together
arguments
    a(1,1) double
    b(1,1) double
end
    x = a * b;
end

function txt = web_search(query)
% Search the internet
arguments
    query(1,1) string % fake input for a fake web search
end
txt = "Here are the headcounts for each of the FAANG companies in 2024:\n" + ...
        "1. **Facebook (Meta)**: 100000 employees.\n" + ...
        "2. **Apple**: 200000 employees.\n" + ...
        "3. **Amazon**: 1500000 employees.\n" + ...
        "4. **Netflix**: 10,000 employees.\n" + ...
        "5. **Google (Alphabet)**: 180,000 employees.";
end

%%
%[text] Create two sub-agents: one for math, the other for "research" (i.e. web searches).
function [observation, workspace] = runMathAgent(workspace, NVP)
% Sub-agent for mathematical tasks
    arguments
        workspace 
        NVP.Prompt
    end
    % "math"
    mathTools = aisdk.LLMTool(@add);
    mathTools(end+1) = aisdk.LLMTool(@multiply);

    api = "openai"; %[control:dropdown:159e]{"position":[11,19]}
    model = "gpt-4.1-mini"; %[control:dropdown:3e32]{"position":[13,27]}

    llmOpts = aisdk.LLMClient(api, model);
    subAgent = aisdk.AIAgent(llmOpts, SystemPrompt="You are a math expert. Always use one tool at a time.", ...
       Tools=mathTools, ...
       Workspace=workspace);
    observation = subAgent.run(NVP.Prompt);
    workspace = subAgent.Workspace;
end

function [observation, workspace] = runSearchAgent(workspace, NVP)
% Sub-agent for economic and financial research
    arguments
        workspace 
        NVP.Prompt(1,1) string
    end
    searchTools = aisdk.LLMTool(@web_search, ...
        RequiresApproval="always"); %[control:dropdown:6c3a]{"position":[26,34]}

    api = "openai"; %[control:dropdown:524c]{"position":[11,19]}
    model = "gpt-4.1-mini"; %[control:dropdown:3923]{"position":[13,27]}

    llmOpts = aisdk.LLMClient(api,  model);
    subAgent = aisdk.AIAgent(llmOpts, ...
       SystemPrompt="You are a world class researcher with access to web search. Do not do any math. Just answer each query, briefly and to the point. ", ...
       Tools=searchTools, ...
       Workspace=workspace);
    observation = subAgent.run(NVP.Prompt);
    workspace = subAgent.Workspace;
end

%%
%[text] Set up a *supervisor agent* that can delegate to one of the two sub-agents, depending on the task.
systemPrompt =  "You are a team supervisor managing a research expert and a math expert. " + ...
      "Think step by step. DO NOT DO MATHS YOURSELF";
topLevelTools = aisdk.LLMTool(@runMathAgent, ...
    InputArguments=aisdk.LLMToolArgument("Prompt", DataType="string", NameValue=true, Description="Arithmetic operation in natural language"), ...
    RequiresApproval="never", ...
    Workspace="agent");
topLevelTools(end+1) = aisdk.LLMTool(@runSearchAgent, ...
    InputArguments=aisdk.LLMToolArgument("Prompt", DataType="string", NameValue=true), ...
    RequiresApproval="never", ...
    Workspace="agent");

api = "openai"; %[control:dropdown:140b]{"position":[7,15]}
model = "gpt-4.1-mini"; %[control:dropdown:16ae]{"position":[9,23]}


client = aisdk.LLMClient(api, model);
topLevelAgent = aisdk.AIAgent(client, SystemPrompt=systemPrompt, ...
    Tools=topLevelTools);
%%
%[text] Run a task. You should see several queries to the "research" agent to get the FAANG headcounts, then some calls to the maths agent for the arithmetic.
prompt = "What's the total headcount of FAANG companies using 2024 data? Use whatever information you have available.";
observation = topLevelAgent.run(prompt); %[output:25f21bc6]
%%
disp(observation) %[output:907b667c]
%[text] *Copyright 2026 The MathWorks, Inc.*

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":40}
%---
%[control:dropdown:159e]
%   data: {"defaultValue":"\"openai\"","itemLabels":["openai","ollama"],"items":["\"openai\"","\"ollama\""],"label":"provider","run":"AllSections"}
%---
%[control:dropdown:3e32]
%   data: {"defaultValue":"\"gpt-4.1-mini\"","itemLabels":["gpt-4.1-mini","qwen3"],"items":["\"gpt-4.1-mini\"","\"qwen3\""],"label":"model","run":"AllSections"}
%---
%[control:dropdown:6c3a]
%   data: {"defaultValue":"\"never\"","itemLabels":["always","once","never"],"items":["\"always\"","\"once\"","\"never\""],"label":"RequiresApproval","run":"AllSections"}
%---
%[control:dropdown:524c]
%   data: {"defaultValue":"\"openai\"","itemLabels":["openai","ollama"],"items":["\"openai\"","\"ollama\""],"label":"provider","run":"AllSections"}
%---
%[control:dropdown:3923]
%   data: {"defaultValue":"\"gpt-4.1-mini\"","itemLabels":["gpt-4.1-mini","qwen3"],"items":["\"gpt-4.1-mini\"","\"qwen3\""],"label":"model","run":"AllSections"}
%---
%[control:dropdown:140b]
%   data: {"defaultValue":"\"openai\"","itemLabels":["openai","ollama"],"items":["\"openai\"","\"ollama\""],"label":"provider","run":"AllSections"}
%---
%[control:dropdown:16ae]
%   data: {"defaultValue":"\"gpt-4.1-mini\"","itemLabels":["gpt-4.1-mini","qwen3"],"items":["\"gpt-4.1-mini\"","\"qwen3\""],"label":"model","run":"AllSections"}
%---
%[output:25f21bc6]
%   data: {"dataType":"text","outputData":{"text":"[think]\n[call function runSearchAgent with inputs {\"Prompt\":\"Current total headcount of Facebook (Meta) in 2024\"}]\n[think]\n[call function web_search with inputs {\"query\":\"Meta (Facebook) total headcount 2024\"}]\n[function return] {\"txt\":\"Here are the headcounts for each of the FAANG companies in 2024:\\\\n1. **Facebook (Meta)**: 100000 employees.\\\\n2. **Apple**: 200000 employees.\\\\n3. **Amazon**: 1500000 employees.\\\\n4. **Netflix**: 10,000 employees.\\\\n5. **Google (Alphabet)**: 180,000 employees.\"}\n[think]\nThe current total headcount of Facebook (Meta) in 2024 is approximately 100,000 employees.\n[function return] {\"observation\":\"The current total headcount of Facebook (Meta) in 2024 is approximately 100,000 employees.\"}\n[call function runSearchAgent with inputs {\"Prompt\":\"Current total headcount of Amazon in 2024\"}]\n[think]\n[call function web_search with inputs {\"query\":\"Amazon total headcount 2024\"}]\n[function return] {\"txt\":\"Here are the headcounts for each of the FAANG companies in 2024:\\\\n1. **Facebook (Meta)**: 100000 employees.\\\\n2. **Apple**: 200000 employees.\\\\n3. **Amazon**: 1500000 employees.\\\\n4. **Netflix**: 10,000 employees.\\\\n5. **Google (Alphabet)**: 180,000 employees.\"}\n[think]\nAs of 2024, Amazon's total headcount is approximately 1,500,000 employees.\n[function return] {\"observation\":\"As of 2024, Amazon's total headcount is approximately 1,500,000 employees.\"}\n[call function runSearchAgent with inputs {\"Prompt\":\"Current total headcount of Apple in 2024\"}]\n[think]\n[call function web_search with inputs {\"query\":\"Apple total headcount 2024\"}]\n[function return] {\"txt\":\"Here are the headcounts for each of the FAANG companies in 2024:\\\\n1. **Facebook (Meta)**: 100000 employees.\\\\n2. **Apple**: 200000 employees.\\\\n3. **Amazon**: 1500000 employees.\\\\n4. **Netflix**: 10,000 employees.\\\\n5. **Google (Alphabet)**: 180,000 employees.\"}\n[think]\nThe current total headcount of Apple in 2024 is approximately 200,000 employees.\n[function return] {\"observation\":\"The current total headcount of Apple in 2024 is approximately 200,000 employees.\"}\n[call function runSearchAgent with inputs {\"Prompt\":\"Current total headcount of Netflix in 2024\"}]\n[think]\n[call function web_search with inputs {\"query\":\"Netflix total headcount 2024\"}]\n[function return] {\"txt\":\"Here are the headcounts for each of the FAANG companies in 2024:\\\\n1. **Facebook (Meta)**: 100000 employees.\\\\n2. **Apple**: 200000 employees.\\\\n3. **Amazon**: 1500000 employees.\\\\n4. **Netflix**: 10,000 employees.\\\\n5. **Google (Alphabet)**: 180,000 employees.\"}\n[think]\nAs of 2024, Netflix has approximately 10,000 employees.\n[function return] {\"observation\":\"As of 2024, Netflix has approximately 10,000 employees.\"}\n[call function runSearchAgent with inputs {\"Prompt\":\"Current total headcount of Google (Alphabet) in 2024\"}]\n[think]\n[call function web_search with inputs {\"query\":\"Google Alphabet total headcount 2024\"}]\n[function return] {\"txt\":\"Here are the headcounts for each of the FAANG companies in 2024:\\\\n1. **Facebook (Meta)**: 100000 employees.\\\\n2. **Apple**: 200000 employees.\\\\n3. **Amazon**: 1500000 employees.\\\\n4. **Netflix**: 10,000 employees.\\\\n5. **Google (Alphabet)**: 180,000 employees.\"}\n[think]\nThe current total headcount of Google (Alphabet) in 2024 is approximately 180,000 employees.\n[function return] {\"observation\":\"The current total headcount of Google (Alphabet) in 2024 is approximately 180,000 employees.\"}\n[think]\n[call function runMathAgent with inputs {\"Prompt\":\"Add the total headcount of Facebook (Meta) 100,000, Amazon 1,500,000, Apple 200,000, Netflix 10,000, and Google (Alphabet) 180,000.\"}]\n[think]\n[call function add with inputs {\"a\":100000,\"b\":1.5E+6}]\n[function return] {\"x\":1.6E+6}\n[call function add with inputs {\"a\":200000,\"b\":10000}]\n[function return] {\"x\":210000}\n[call function add with inputs {\"a\":180000,\"b\":0}]\n[function return] {\"x\":180000}\n[think]\n[call function add with inputs {\"a\":1.6E+6,\"b\":210000}]\n[function return] {\"x\":1.81E+6}\n[think]\n[call function add with inputs {\"a\":1.81E+6,\"b\":180000}]\n[function return] {\"x\":1.99E+6}\n[think]\nThe total headcount of Facebook (Meta), Amazon, Apple, Netflix, and Google (Alphabet) combined is approximately 1,990,000 employees.\n[function return] {\"observation\":\"The total headcount of Facebook (Meta), Amazon, Apple, Netflix, and Google (Alphabet) combined is approximately 1,990,000 employees.\"}\n[think]\nThe total headcount of the FAANG companies in 2024 is approximately 1,990,000 employees. This includes about 100,000 employees at Facebook (Meta), 1,500,000 at Amazon, 200,000 at Apple, 10,000 at Netflix, and 180,000 at Google (Alphabet).\n","truncated":false}}
%---
%[output:907b667c]
%   data: {"dataType":"text","outputData":{"text":"The total headcount of the FAANG companies in 2024 is approximately 1,990,000 employees. This includes about 100,000 employees at Facebook (Meta), 1,500,000 at Amazon, 200,000 at Apple, 10,000 at Netflix, and 180,000 at Google (Alphabet).\n","truncated":false}}
%---
