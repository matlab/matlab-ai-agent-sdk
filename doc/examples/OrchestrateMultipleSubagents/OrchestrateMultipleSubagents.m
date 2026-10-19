%[text] # Orchestrate Multiple Subagents
%[text] This example shows how to create an agent with multiple subagents.
%[text] Solving a problem can require two or more distinct skill sets. To solve such a problem with an agent, instead of creating a single agent that combines these skill sets, you can create a subagent for each skill set. Then create an orchestrating agent that delegates tasks to the subagents.   
%[text] Running this example requires an OpenAI® API key, but you can change the code to use a different API instead by changing the parts of the code that call the [`aisdk.LLMClient`](file:../../functions/aisdk.LLMClient.md) function. In particular, you can choose to use different models for each subagent and the orchestrating agent, depending on the requirements of each agent.
%%
%[text] ## Connect to OpenAI
%[text] Using the OpenAI Chat Completions API requires an OpenAI API key. For information on how to obtain one, as well as pricing, terms and conditions of use, and available models, see the [OpenAI documentation](https://platform.openai.com/docs/overview).
%[text] Set your key as an environment variable in a `.env` file:
%[text] ```matlabCodeExample
%[text] OPENAI_API_KEY=<your key>
%[text] ```
%[text] Then add the file to the path and load it in MATLAB®.
loadenv(".env")
%%
%[text] In this example, create one subagent for mathematical tasks, and one subagent for web searching.
%[text] ## Create Math Subagent
%[text] Create a function that adds two numbers. Add a comment at the top of the function and an `arguments` block. This allows the [`aisdk.LLMTool`](file:../../functions/aisdk.LLMTool.md) function to automatically extract the function description and input argument information.
function x = add(a, b)
% Add two numbers together
arguments
    a (1,1) double
    b (1,1) double
end
    x = a + b;
end
%[text] Create a function that multiplies two numbers.
function x = multiply(a,b)
% Multiply two numbers together
arguments
    a (1,1) double
    b (1,1) double
end
    x = a * b;
end
%[text] Create a function that creates and runs the math subagent.
function [observation,workspace] = runMathAgent(workspace,NVP)
% Subagent for mathematical tasks
arguments
    workspace 
    NVP.Prompt
end
api = "openai";
model = "gpt-4.1-mini";
mathClient = aisdk.LLMClient(api,model);

multiplyTool = aisdk.LLMTool(@multiply,ApprovalRequest="never");
addTool = aisdk.LLMTool(@add,ApprovalRequest="never");

mathAgent = aisdk.AIAgent(mathClient, ...
    SystemPrompt="You are a math expert. Always use one tool at a time.", ...
    Tools=[addTool,multiplyTool], ...
    Workspace=workspace);
observation = run(mathAgent,NVP.Prompt);
workspace = mathAgent.Workspace;
end
%[text] Next, create an LLM tool from that function, which you can then provide to the orchestrating agent.
mathSubagent = aisdk.LLMTool(@runMathAgent, ...
    InputArguments = aisdk.LLMToolArgument(...
        "Prompt", ...
        DataType = "string", ...
        NameValue = true, ...
        Description = "Arithmetic operation in natural language"), ...
    ApprovalRequest="never", ...
    Workspace="agent", ...
    DisplayTitle="Math Subagent");
%[text] ## Create Web Search Subagent
%[text] Next, create a subagent that performs a mock web search. In this example, the underlying function takes a string input and returns a fake web search result.
%[text] First, create the mock web search function.
function txt = mockWebSearch(query)
% Search the internet
arguments
    query(1,1) string % input for web search
end
txt = "The headcounts of the five most alliterative companies are:\n" + ...
        "1. **Anderson's Amazing Aqueducts**: 1234 employees.\n" + ...
        "2. **Brussels Bustling Bunsen Burners**: 2222 employees.\n" + ...
        "3. **Clever Cats Cleveland**: 7 employees (not counting the cats).\n" + ...
        "4. **Dorothy and Daughters Diligent Decoders**: 10,042 employees.\n" + ...
        "5. **East Estonia's Erudite Evergreen Emporium**: 180 employees.";
end
%%
%[text] Create a function that creates and runs the web search subagent.
function [observation, workspace] = runWebSearchAgent(workspace, NVP)
% Subagent for web search
    arguments
        workspace 
        NVP.Prompt(1,1) string
    end
    searchTools = aisdk.LLMTool(@mockWebSearch, ...
        ApprovalRequest="never", ...
        DisplayTitle="Web Search Tool");

    api = "openai";
    model = "gpt-4.1-mini";

    llmOpts = aisdk.LLMClient(api,  model);
    subAgent = aisdk.AIAgent(llmOpts, ...
       SystemPrompt="You are a world class researcher with access to web search. Do not do any math. Just answer each query, briefly and to the point. ", ...
       Tools=searchTools, ...
       Workspace=workspace);
    observation = subAgent.run(NVP.Prompt);
    workspace = subAgent.Workspace;
end
%[text] Next, create an LLM tool from that function, which you can then provide to the orchestrating agent.
webSearchSubagent = aisdk.LLMTool(@runWebSearchAgent, ...
    InputArguments = aisdk.LLMToolArgument("Prompt", DataType="string", NameValue=true), ...
    ApprovalRequest = "never", ...
    Workspace = "agent", ...
    DisplayTitle = "Research Subagent");
%%
%[text] ## Create Orchestrating Agent
%[text] Create the orchestrating agent that can delegate tasks to the two subagents.
api = "openai";
model = "gpt-4.1-mini";
client = aisdk.LLMClient(api,model);
systemPrompt =  "You are a team supervisor managing a research expert and a math expert. ";

orchestratingAgent = aisdk.AIAgent(client,SystemPrompt=systemPrompt, ...
    Tools=[mathSubagent,webSearchSubagent]);
%%
%[text] Ask the orchestrating agent a question that requires both subagents.
prompt = "What's the total headcount of the top five most alliterative companies?";
observation = run(orchestratingAgent,prompt); %[output:02d5ebf0]
%%
%[text] View the message history.
orchestratingAgent.Messages %[output:1b6d22fc]
%[text] *Copyright 2026 The MathWorks, Inc.*

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":40}
%---
%[output:02d5ebf0]
%   data: {"dataType":"text","outputData":{"text":"[think]\n[call function runWebSearchAgent with inputs {\"Prompt\":\"Top five most alliterative companies\"}]\n[think]\n[call function mockWebSearch with inputs {\"query\":\"top most alliterative company names\"}]\n[function return] {\"txt\":\"The headcounts of the five most alliterative companies are:\\\\n1. **Anderson's Amazing Aqueducts**: 1234 employees.\\\\n2. **Brussel's Bustling Bunsen Burners**: 2222 employees.\\\\n3. **Clever Cats Cleveland**: 7 employees (not counting the cats).\\\\n4. **Dorothy and Daughters Diligent Decoders**: 10,042 employees.\\\\n5. **East Estonia's Erudite Evergreen Emporium**: 180 employees.\"}\n[think]\nThe top five most alliterative companies are:\n1. Anderson's Amazing Aqueducts\n2. Brussel's Bustling Bunsen Burners\n3. Clever Cats Cleveland\n4. Dorothy and Daughters Diligent Decoders\n5. East Estonia's Erudite Evergreen Emporium\n[function return] {\"observation\":\"The top five most alliterative companies are:\\n1. Anderson's Amazing Aqueducts\\n2. Brussel's Bustling Bunsen Burners\\n3. Clever Cats Cleveland\\n4. Dorothy and Daughters Diligent Decoders\\n5. East Estonia's Erudite Evergreen Emporium\"}\n[think]\n[call function runWebSearchAgent with inputs {\"Prompt\":\"Headcount of Anderson's Amazing Aqueducts\"}]\n[think]\n[call function mockWebSearch with inputs {\"query\":\"Headcount of Anderson's Amazing Aqueducts\"}]\n[function return] {\"txt\":\"The headcounts of the five most alliterative companies are:\\\\n1. **Anderson's Amazing Aqueducts**: 1234 employees.\\\\n2. **Brussel's Bustling Bunsen Burners**: 2222 employees.\\\\n3. **Clever Cats Cleveland**: 7 employees (not counting the cats).\\\\n4. **Dorothy and Daughters Diligent Decoders**: 10,042 employees.\\\\n5. **East Estonia's Erudite Evergreen Emporium**: 180 employees.\"}\n[think]\nAnderson's Amazing Aqueducts has a headcount of 1,234 employees.\n[function return] {\"observation\":\"Anderson's Amazing Aqueducts has a headcount of 1,234 employees.\"}\n[call function runWebSearchAgent with inputs {\"Prompt\":\"Headcount of Brussel's Bustling Bunsen Burners\"}]\n[think]\n[call function mockWebSearch with inputs {\"query\":\"headcount of Brussel's Bustling Bunsen Burners\"}]\n[function return] {\"txt\":\"The headcounts of the five most alliterative companies are:\\\\n1. **Anderson's Amazing Aqueducts**: 1234 employees.\\\\n2. **Brussel's Bustling Bunsen Burners**: 2222 employees.\\\\n3. **Clever Cats Cleveland**: 7 employees (not counting the cats).\\\\n4. **Dorothy and Daughters Diligent Decoders**: 10,042 employees.\\\\n5. **East Estonia's Erudite Evergreen Emporium**: 180 employees.\"}\n[think]\nThe headcount of Brussel's Bustling Bunsen Burners is 2,222 employees.\n[function return] {\"observation\":\"The headcount of Brussel's Bustling Bunsen Burners is 2,222 employees.\"}\n[call function runWebSearchAgent with inputs {\"Prompt\":\"Headcount of Clever Cats Cleveland\"}]\n[think]\n[call function mockWebSearch with inputs {\"query\":\"Clever Cats Cleveland headcount\"}]\n[function return] {\"txt\":\"The headcounts of the five most alliterative companies are:\\\\n1. **Anderson's Amazing Aqueducts**: 1234 employees.\\\\n2. **Brussel's Bustling Bunsen Burners**: 2222 employees.\\\\n3. **Clever Cats Cleveland**: 7 employees (not counting the cats).\\\\n4. **Dorothy and Daughters Diligent Decoders**: 10,042 employees.\\\\n5. **East Estonia's Erudite Evergreen Emporium**: 180 employees.\"}\n[think]\nThe headcount of Clever Cats Cleveland is 7 employees (not counting the cats).\n[function return] {\"observation\":\"The headcount of Clever Cats Cleveland is 7 employees (not counting the cats).\"}\n[call function runWebSearchAgent with inputs {\"Prompt\":\"Headcount of Dorothy and Daughters Diligent Decoders\"}]\n[think]\n[call function mockWebSearch with inputs {\"query\":\"Dorothy and Daughters Diligent Decoders headcount\"}]\n[function return] {\"txt\":\"The headcounts of the five most alliterative companies are:\\\\n1. **Anderson's Amazing Aqueducts**: 1234 employees.\\\\n2. **Brussel's Bustling Bunsen Burners**: 2222 employees.\\\\n3. **Clever Cats Cleveland**: 7 employees (not counting the cats).\\\\n4. **Dorothy and Daughters Diligent Decoders**: 10,042 employees.\\\\n5. **East Estonia's Erudite Evergreen Emporium**: 180 employees.\"}\n[think]\nThe headcount of Dorothy and Daughters Diligent Decoders is 10,042 employees.\n[function return] {\"observation\":\"The headcount of Dorothy and Daughters Diligent Decoders is 10,042 employees.\"}\n[call function runWebSearchAgent with inputs {\"Prompt\":\"Headcount of East Estonia's Erudite Evergreen Emporium\"}]\n[think]\n[call function mockWebSearch with inputs {\"query\":\"East Estonia's Erudite Evergreen Emporium headcount\"}]\n[function return] {\"txt\":\"The headcounts of the five most alliterative companies are:\\\\n1. **Anderson's Amazing Aqueducts**: 1234 employees.\\\\n2. **Brussel's Bustling Bunsen Burners**: 2222 employees.\\\\n3. **Clever Cats Cleveland**: 7 employees (not counting the cats).\\\\n4. **Dorothy and Daughters Diligent Decoders**: 10,042 employees.\\\\n5. **East Estonia's Erudite Evergreen Emporium**: 180 employees.\"}\n[think]\nEast Estonia's Erudite Evergreen Emporium has 180 employees.\n[function return] {\"observation\":\"East Estonia's Erudite Evergreen Emporium has 180 employees.\"}\n[think]\n[call function runMathAgent with inputs {\"Prompt\":\"Add the following numbers: 1234, 2222, 7, 10042, 180.\"}]\n[think]\n[call function add with inputs {\"a\":1234,\"b\":2222}]\n[function return] {\"x\":3456}\n[call function add with inputs {\"a\":7,\"b\":10042}]\n[function return] {\"x\":10049}\n[think]\n[call function add with inputs {\"a\":3456,\"b\":10049}]\n[function return] {\"x\":13505}\n[think]\n[call function add with inputs {\"a\":13505,\"b\":180}]\n[function return] {\"x\":13685}\n[think]\nThe sum of the numbers 1234, 2222, 7, 10042, and 180 is 13685.\n[function return] {\"observation\":\"The sum of the numbers 1234, 2222, 7, 10042, and 180 is 13685.\"}\n[think]\nThe total headcount of the top five most alliterative companies is 13,685 employees.\n","truncated":false}}
%---
%[output:1b6d22fc]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"  1×16 <a href=\"matlab:helpPopup('aisdk.message.LLMMessage')\" style=\"font-weight:bold\">LLMMessage<\/a> array with messages:\n\n    1     User         Text         \"What's the total headcount of the top five most alliterative...\"\n    2     Assistant    Tool Call    \"runWebSearchAgent({\"Prompt\":\"Top five most alliterative comp...\"\n    3     Tool         Text         \"{\"observation\":\"The top five most alliterative companies are...\"\n    4     Assistant    Tool Call    \"runWebSearchAgent({\"Prompt\":\"Headcount of Anderson's Amazing...\"\n    5     Assistant    Tool Call    \"runWebSearchAgent({\"Prompt\":\"Headcount of Brussel's Bustling...\"\n    6     Assistant    Tool Call    \"runWebSearchAgent({\"Prompt\":\"Headcount of Clever Cats Clevel...\"\n    7     Assistant    Tool Call    \"runWebSearchAgent({\"Prompt\":\"Headcount of Dorothy and Daught...\"\n    8     Assistant    Tool Call    \"runWebSearchAgent({\"Prompt\":\"Headcount of East Estonia's Eru...\"\n    9     Tool         Text         \"{\"observation\":\"Anderson's Amazing Aqueducts has a headcount...\"\n    10    Tool         Text         \"{\"observation\":\"The headcount of Brussel's Bustling Bunsen B...\"\n    11    Tool         Text         \"{\"observation\":\"The headcount of Clever Cats Cleveland is 7 ...\"\n    12    Tool         Text         \"{\"observation\":\"The headcount of Dorothy and Daughters Dilig...\"\n    13    Tool         Text         \"{\"observation\":\"East Estonia's Erudite Evergreen Emporium ha...\"\n    14    Assistant    Tool Call    \"runMathAgent({\"Prompt\":\"Add the following numbers: 1234, 222...\"\n    15    Tool         Text         \"{\"observation\":\"The sum of the numbers 1234, 2222, 7, 10042,...\"\n    16    Assistant    Text         \"The total headcount of the top five most alliterative compan...\"\n"}}
%---
