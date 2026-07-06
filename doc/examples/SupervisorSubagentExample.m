%[text] # Supervisor-Subagent Example
%[text] This replicates this LangChain/LangGraph example: [https://github.com/langchain-ai/langgraph-supervisor-py](https://github.com/langchain-ai/langgraph-supervisor-py)
%%
%[text] Create tools for addition, multiplication and a "web search" (not to be confused with Responses API server-side tools).
function x = add(a, b)
arguments
    a (1,1) double
    b (1,1) double
end
    x = a + b;
end

function x = multiply(a,b)
arguments
    a
    b
end
    x = a * b;
end

function txt = web_search(query)
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
%[text] Create two subagents: one for maths, the other for "research" (i.e. web searches).
function [observation, workspace] = runMathAgent(workspace, NVP)
    arguments
        workspace 
        NVP.Prompt
    end
    % "math"
    mathTools = aisdk.LLMTool(@add, Description="add two numbers together", InputArguments=struct("a", 1, "b", 2));
    mathTools(end+1) = aisdk.LLMTool(@multiply, Description="multiply two numbers together", InputArguments=struct("a", 1, "b", 2));

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
    arguments
        workspace 
        NVP.Prompt
    end
    searchTools = aisdk.LLMTool(@web_search, ...
        Description="Search the web for information.", ...
        InputArguments= struct("Query", "What's the population of UK?"), ...
        RequiresApproval="always"); %[control:dropdown:6c3a]{"position":[26,34]}

     api = "openai"; %[control:dropdown:524c]{"position":[12,20]}
    model = "gpt-4.1-mini"; %[control:dropdown:3923]{"position":[13,27]}

    llmOpts = aisdk.LLMClient(api,  model);
    subAgent = aisdk.AIAgent(llmOpts, SystemPrompt="You are a world class researcher with access to web search. Do not do any math. Just answer each query, briefly and to the point. ", ...
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
    Description="Use this tool to do basic arithmetic", ...
    InputArguments=aisdk.LLMToolArgument("Prompt", DataType="string", NameValue=true, Description="Arithmetic operation in natural language"), ...
    RequiresApproval="never", ...
    Workspace="agent");
topLevelTools(end+1) = aisdk.LLMTool(@runSearchAgent, ...
    Description="Use this tool to perform web searches", ...
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
obs = topLevelAgent.run(prompt); %[output:25f21bc6]
%%
disp(obs) %[output:0373281e]
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
%   data: {"dataType":"text","outputData":{"text":"[think]\n[call function runSearchAgent with inputs {\"Prompt\":\"latest headcount of Facebook (Meta) as of 2024\"}]\n[think]\n[call function web_search with inputs {\"Query\":\"latest headcount of Facebook Meta 2024\"}]\n[function return] \"Here are the headcounts for each of the FAANG companies in 2024:\\\\n1. **Facebook (Meta)**: 100000 employees.\\\\n2. **Apple**: 200000 employees.\\\\n3. **Amazon**: 1500000 employees.\\\\n4. **Netflix**: 10,000 employees.\\\\n5. **Google (Alphabet)**: 180,000 employees.\"\n[think]\nAs of 2024, Facebook (Meta) has approximately 100,000 employees.\n[function return] \"As of 2024, Facebook (Meta) has approximately 100,000 employees.\"\n[call function runSearchAgent with inputs {\"Prompt\":\"latest headcount of Amazon as of 2024\"}]\n[think]\n[call function web_search with inputs {\"Query\":\"Amazon headcount 2024\"}]\n[function return] \"Here are the headcounts for each of the FAANG companies in 2024:\\\\n1. **Facebook (Meta)**: 100000 employees.\\\\n2. **Apple**: 200000 employees.\\\\n3. **Amazon**: 1500000 employees.\\\\n4. **Netflix**: 10,000 employees.\\\\n5. **Google (Alphabet)**: 180,000 employees.\"\n[think]\nAs of 2024, Amazon has approximately 1,500,000 employees.\n[function return] \"As of 2024, Amazon has approximately 1,500,000 employees.\"\n[call function runSearchAgent with inputs {\"Prompt\":\"latest headcount of Apple as of 2024\"}]\n[think]\n[call function web_search with inputs {\"Query\":\"Apple employee headcount 2024\"}]\n[function return] \"Here are the headcounts for each of the FAANG companies in 2024:\\\\n1. **Facebook (Meta)**: 100000 employees.\\\\n2. **Apple**: 200000 employees.\\\\n3. **Amazon**: 1500000 employees.\\\\n4. **Netflix**: 10,000 employees.\\\\n5. **Google (Alphabet)**: 180,000 employees.\"\n[think]\nAs of 2024, Apple has approximately 200,000 employees.\n[function return] \"As of 2024, Apple has approximately 200,000 employees.\"\n[call function runSearchAgent with inputs {\"Prompt\":\"latest headcount of Netflix as of 2024\"}]\n[think]\n[call function web_search with inputs {\"Query\":\"Netflix latest headcount 2024\"}]\n[function return] \"Here are the headcounts for each of the FAANG companies in 2024:\\\\n1. **Facebook (Meta)**: 100000 employees.\\\\n2. **Apple**: 200000 employees.\\\\n3. **Amazon**: 1500000 employees.\\\\n4. **Netflix**: 10,000 employees.\\\\n5. **Google (Alphabet)**: 180,000 employees.\"\n[think]\nAs of 2024, Netflix has approximately 10,000 employees.\n[function return] \"As of 2024, Netflix has approximately 10,000 employees.\"\n[call function runSearchAgent with inputs {\"Prompt\":\"latest headcount of Google (Alphabet) as of 2024\"}]\n[think]\n[call function web_search with inputs {\"Query\":\"Google Alphabet latest headcount 2024\"}]\n[function return] \"Here are the headcounts for each of the FAANG companies in 2024:\\\\n1. **Facebook (Meta)**: 100000 employees.\\\\n2. **Apple**: 200000 employees.\\\\n3. **Amazon**: 1500000 employees.\\\\n4. **Netflix**: 10,000 employees.\\\\n5. **Google (Alphabet)**: 180,000 employees.\"\n[think]\nAs of 2024, Google (Alphabet) has a headcount of approximately 180,000 employees.\n[function return] \"As of 2024, Google (Alphabet) has a headcount of approximately 180,000 employees.\"\n[think]\n[call function runMathAgent with inputs {\"Prompt\":\"Sum of headcounts: Meta 100,000, Amazon 1,500,000, Apple 200,000, Netflix 10,000, Google 180,000\"}]\n[think]\n[call function add with inputs {\"a\":100000,\"b\":1.5E+6}]\n[function return] 1.6E+6\n[call function add with inputs {\"a\":200000,\"b\":10000}]\n[function return] 210000\n[think]\n[call function add with inputs {\"a\":1.6E+6,\"b\":210000}]\n[function return] 1.81E+6\n[think]\n[call function add with inputs {\"a\":1.81E+6,\"b\":180000}]\n[function return] 1.99E+6\n[think]\nThe total sum of the headcounts for Meta, Amazon, Apple, Netflix, and Google is 1,990,000.\n[function return] \"The total sum of the headcounts for Meta, Amazon, Apple, Netflix, and Google is 1,990,000.\"\n[think]\nThe total headcount of FAANG companies in 2024 is approximately 1,990,000 employees.\n","truncated":false}}
%---
%[output:0373281e]
%   data: {"dataType":"text","outputData":{"text":"The total headcount of FAANG companies in 2024 is approximately 1,990,000 employees.\n","truncated":false}}
%---
