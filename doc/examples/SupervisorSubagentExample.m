%[text] # Supervisor-Subagent Example
%[text] This replicates this LangChain/LangGraph example: [https://github.com/langchain-ai/langgraph-supervisor-py](https://github.com/langchain-ai/langgraph-supervisor-py)
%%
%[text] Set up a client.
api = "openai"; %[control:dropdown:41f3]{"position":[7,15]}
model = "gpt-4.1-mini"; %[control:dropdown:58ac]{"position":[9,23]}

client = aisdk.LLMClient(api, model);
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
      "Think step by step. DO NOT DO MATH YOURSELF";
topLevelTools = aisdk.LLMTool(@runMathAgent, ...
    InputArguments=aisdk.LLMToolArgument("Prompt", DataType="string", NameValue=true, Description="Arithmetic operation in natural language"), ...
    RequiresApproval="never", ...
    Workspace="agent");
topLevelTools(end+1) = aisdk.LLMTool(@runSearchAgent, ...
    InputArguments=aisdk.LLMToolArgument("Prompt", DataType="string", NameValue=true), ...
    RequiresApproval="never", ...
    Workspace="agent");

topLevelAgent = aisdk.AIAgent(client, SystemPrompt=systemPrompt, ...
    Tools=topLevelTools);
%%
%[text] Run a task. You should see several queries to the "research" agent to get the FAANG headcounts, then some calls to the maths agent for the arithmetic.
prompt = "What's the total headcount of FAANG companies using 2024 data? Use whatever information you have available.";
observation = topLevelAgent.run(prompt); %[output:25f21bc6]
%%
disp(observation) %[output:44223368]
%[text] *Copyright 2026 The MathWorks, Inc.*

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":40}
%---
%[control:dropdown:41f3]
%   data: {"defaultValue":"\"openai\"","itemLabels":["openai","ollama"],"items":["\"openai\"","\"ollama\""],"label":"provider","run":"AllSections"}
%---
%[control:dropdown:58ac]
%   data: {"defaultValue":"\"gpt-4.1-mini\"","itemLabels":["gpt-4.1-mini","qwen3"],"items":["\"gpt-4.1-mini\"","\"qwen3\""],"label":"model","run":"AllSections"}
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
%[output:25f21bc6]
%   data: {"dataType":"text","outputData":{"text":"[think]\n[call function runSearchAgent with inputs {\"Prompt\":\"Current employee headcount of Facebook (Meta) in 2024\"}]\n[think]\n[call function web_search with inputs {\"query\":\"current employee headcount of Facebook (Meta) in 2024\"}]\n[function return] {\"txt\":\"Here are the headcounts for each of the FAANG companies in 2024:\\\\n1. **Facebook (Meta)**: 100000 employees.\\\\n2. **Apple**: 200000 employees.\\\\n3. **Amazon**: 1500000 employees.\\\\n4. **Netflix**: 10,000 employees.\\\\n5. **Google (Alphabet)**: 180,000 employees.\"}\n[think]\nThe current employee headcount of Facebook (Meta) in 2024 is approximately 100,000 employees.\n[function return] {\"observation\":\"The current employee headcount of Facebook (Meta) in 2024 is approximately 100,000 employees.\"}\n[call function runSearchAgent with inputs {\"Prompt\":\"Current employee headcount of Apple in 2024\"}]\n[think]\n[call function web_search with inputs {\"query\":\"Apple employee headcount 2024\"}]\n[function return] {\"txt\":\"Here are the headcounts for each of the FAANG companies in 2024:\\\\n1. **Facebook (Meta)**: 100000 employees.\\\\n2. **Apple**: 200000 employees.\\\\n3. **Amazon**: 1500000 employees.\\\\n4. **Netflix**: 10,000 employees.\\\\n5. **Google (Alphabet)**: 180,000 employees.\"}\n[think]\nThe current employee headcount of Apple in 2024 is approximately 200,000 employees.\n[function return] {\"observation\":\"The current employee headcount of Apple in 2024 is approximately 200,000 employees.\"}\n[call function runSearchAgent with inputs {\"Prompt\":\"Current employee headcount of Amazon in 2024\"}]\n[think]\n[call function web_search with inputs {\"query\":\"Amazon employee headcount 2024\"}]\n[function return] {\"txt\":\"Here are the headcounts for each of the FAANG companies in 2024:\\\\n1. **Facebook (Meta)**: 100000 employees.\\\\n2. **Apple**: 200000 employees.\\\\n3. **Amazon**: 1500000 employees.\\\\n4. **Netflix**: 10,000 employees.\\\\n5. **Google (Alphabet)**: 180,000 employees.\"}\n[think]\nAs of 2024, Amazon has approximately 1,500,000 employees.\n[function return] {\"observation\":\"As of 2024, Amazon has approximately 1,500,000 employees.\"}\n[call function runSearchAgent with inputs {\"Prompt\":\"Current employee headcount of Netflix in 2024\"}]\n[think]\n[call function web_search with inputs {\"query\":\"Netflix employee headcount 2024\"}]\n[function return] {\"txt\":\"Here are the headcounts for each of the FAANG companies in 2024:\\\\n1. **Facebook (Meta)**: 100000 employees.\\\\n2. **Apple**: 200000 employees.\\\\n3. **Amazon**: 1500000 employees.\\\\n4. **Netflix**: 10,000 employees.\\\\n5. **Google (Alphabet)**: 180,000 employees.\"}\n[think]\nThe current employee headcount of Netflix in 2024 is approximately 10,000 employees.\n[function return] {\"observation\":\"The current employee headcount of Netflix in 2024 is approximately 10,000 employees.\"}\n[call function runSearchAgent with inputs {\"Prompt\":\"Current employee headcount of Google (Alphabet) in 2024\"}]\n[think]\n[call function web_search with inputs {\"query\":\"Google Alphabet employee headcount 2024\"}]\n[function return] {\"txt\":\"Here are the headcounts for each of the FAANG companies in 2024:\\\\n1. **Facebook (Meta)**: 100000 employees.\\\\n2. **Apple**: 200000 employees.\\\\n3. **Amazon**: 1500000 employees.\\\\n4. **Netflix**: 10,000 employees.\\\\n5. **Google (Alphabet)**: 180,000 employees.\"}\n[think]\nThe current employee headcount of Google (Alphabet) in 2024 is approximately 180,000 employees.\n[function return] {\"observation\":\"The current employee headcount of Google (Alphabet) in 2024 is approximately 180,000 employees.\"}\n[think]\n[call function runMathAgent with inputs {\"Prompt\":\"Calculate the total headcount of FAANG companies by adding 100000 (Meta) + 200000 (Apple) + 1500000 (Amazon) + 10000 (Netflix) + 180000 (Google).\"}]\n[think]\n[call function add with inputs {\"a\":100000,\"b\":200000}]\n[function return] {\"x\":300000}\n[call function add with inputs {\"a\":1.5E+6,\"b\":10000}]\n[function return] {\"x\":1.51E+6}\n[call function add with inputs {\"a\":180000,\"b\":0}]\n[function return] {\"x\":180000}\n[think]\n[call function add with inputs {\"a\":300000,\"b\":1.51E+6}]\n[function return] {\"x\":1.81E+6}\n[think]\n[call function add with inputs {\"a\":1.81E+6,\"b\":180000}]\n[function return] {\"x\":1.99E+6}\n[think]\nThe total headcount of FAANG companies (Meta, Apple, Amazon, Netflix, Google) is 1,990,000.\n[function return] {\"observation\":\"The total headcount of FAANG companies (Meta, Apple, Amazon, Netflix, Google) is 1,990,000.\"}\n[think]\nThe total headcount of FAANG companies in 2024 is approximately 1,990,000 employees. This includes around 100,000 employees at Meta (Facebook), 200,000 at Apple, 1,500,000 at Amazon, 10,000 at Netflix, and 180,000 at Google (Alphabet).\n","truncated":false}}
%---
%[output:44223368]
%   data: {"dataType":"text","outputData":{"text":"The total headcount of FAANG companies in 2024 is approximately 1,990,000 employees. This includes around 100,000 employees at Meta (Facebook), 200,000 at Apple, 1,500,000 at Amazon, 10,000 at Netflix, and 180,000 at Google (Alphabet).\n","truncated":false}}
%---
