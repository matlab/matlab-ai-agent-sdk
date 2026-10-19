%[text] # Analyze Text Data Using LLM Tool
%[text] This example shows how to use tool calling to create a table of customer information from a text data set containing that information in natural language.
%[text] Running this example requires an OpenAI® API key, but you can change the code to use a different API instead by changing the part of the code that calls the [`aisdk.LLMClient`](file:../../functions/aisdk.LLMClient.md) function.
%%
%[text] ## Connect to OpenAI
%[text] Using the OpenAI Chat Completions API requires an OpenAI API key. For information on how to obtain one, as well as pricing, terms and conditions of use, and available models, see the [OpenAI documentation](https://platform.openai.com/docs/overview).
%[text] Set your key as an environment variable in a `.env` file:
%[text] ```matlabCodeExample
%[text] OPENAI_API_KEY=<your key>
%[text] ```
%[text] Then add the file to the path and load it in MATLAB®.
loadenv(".env")
%[text] Specify the API and model name. Create the LLM client by using the `aisdk.LLMClient` function.
api = "openai";
model = "gpt-4.1-mini";
llm = aisdk.LLMClient(api,model) %[output:94863371]
%%
%[text] ## Create LLM Tool
%[text] Define a function that extracts data from the customer record. To let the tool work on large amounts of customer data, configure the tool to use data from the agent workspace as input or output data.
%[text] - The first input argument of the function must be a structure array representing the input agent workspace. Call the argument `workspace`.
%[text] - The last output argument of the function must be a structure array representing the updated agent workspace after the tool call.
%[text] - To allow the agent to understand the outcome of the tool call, add another output argument, `observation`, that contains a natural language description of the outcome of the tool call.
%[text] - To let the tool infer information about its input arguments automatically, add an `arguments` block at the top of the function. \
function [observation,workspace] = extractCustomerData(workspace,name,age,email)
%Extract structured customer data from text
    arguments
        workspace (1,1) struct
        name (1,1) string
        age (1,1) double
        email (1,1) string
    end
    if ~isfield(workspace, "customerData")
        workspace.customerData = struct2table(struct( ...
            name=name, ...
            age=age, ...
            email=email));
    else
        workspace.customerData(end+1, :) = {name, age, email};
    end
    observation = "Extracted data for " + name;
end
%[text] Create an LLM tool from the `extractCustomerData` function by using the [`aisdk.LLMTool`](file:../../functions/aisdk.LLMTool.md) function.
extractionTool = aisdk.LLMTool(@extractCustomerData,Workspace = "agent");
%%
%[text] ## Create Agent
%[text] Create an agent object. 
agent = aisdk.AIAgent(llm, ...
    SystemPrompt="You are an AI assistant designed to extract customer data and return it in a given format.", ...
    Tools=extractionTool);
%%
%[text] ## Run Agent
%[text] Define the text data that contains fictional customer information.
record = ["Customer John Doe, 35 years old. Email: johndoe@email.com"; ...
    "Jane Smith, age 28. Email address: janesmith@email.com";
    "Customer named Alex Lee, 29, with email alexlee@email.com";
    "Evelyn Carter, 32, email: evelyncarter32@email.com";
    "Jackson Briggs is 45 years old. Contact email: jacksonb45@email.com";
    "Aria Patel, 27 years old. Email contact: apatel27@email.com";
    "Liam Tanaka, aged 28. Email: liam.tanaka@email.com";
    "Sofia Russo, 24 years old, email: sofia.russo124@email.com"];
record = join(record);
%[text] Ask the agent to extract the customer data from the text data. When prompted by the dialog window, approve the tool call by selecting **Always Approve**.
resp = run(agent,"Extract data from the record: " + record); %[output:83e4f8fa] %[output:9cbdbf86]
%[text] The text response often contains the data in a fairly structured format already. The tool has also stored the data in the agent workspace:
agent.Workspace.customerData %[output:7593e778]
%[text] *Copyright 2026 The MathWorks, Inc.*

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":40}
%---
%[output:94863371]
%   data: {"dataType":"textualVariable","outputData":{"name":"llm","value":"  <a href=\"matlab:helpPopup('aisdk.client.OpenAIClient')\" style=\"font-weight:bold\">OpenAIClient<\/a> with properties:\n\n                 API: \"openai\"\n           ModelName: \"gpt-4.1-mini\"\n             BaseURL: \"https:\/\/api.openai.com\/v1\/chat\/completions\"\n        MaxNumTokens: Inf\n     ReasoningEffort: \"auto\"\n       StopSequences: []\n           StreamFcn: []\n             TimeOut: 120\n      ResponseFormat: \"text\"\n           Verbosity: \"auto\"\n         Temperature: \"auto\"\n                TopP: \"auto\"\n     PresencePenalty: \"auto\"\n    FrequencyPenalty: \"auto\"\n         ContextSize: NaN\n"}}
%---
%[output:83e4f8fa]
%   data: {"dataType":"text","outputData":{"text":"[think]\n","truncated":false}}
%---
%[output:9cbdbf86]
%   data: {"dataType":"text","outputData":{"text":"[user permanently approved tool calls to extractCustomerData]\n[call function extractCustomerData with inputs {\"name\":\"John Doe\",\"age\":35,\"email\":\"johndoe@email.com\"}]\n[function return] {\"observation\":\"Extracted data for John Doe\"}\n[call function extractCustomerData with inputs {\"name\":\"Jane Smith\",\"age\":28,\"email\":\"janesmith@email.com\"}]\n[function return] {\"observation\":\"Extracted data for Jane Smith\"}\n[call function extractCustomerData with inputs {\"name\":\"Alex Lee\",\"age\":29,\"email\":\"alexlee@email.com\"}]\n[function return] {\"observation\":\"Extracted data for Alex Lee\"}\n[call function extractCustomerData with inputs {\"name\":\"Evelyn Carter\",\"age\":32,\"email\":\"evelyncarter32@email.com\"}]\n[function return] {\"observation\":\"Extracted data for Evelyn Carter\"}\n[call function extractCustomerData with inputs {\"name\":\"Jackson Briggs\",\"age\":45,\"email\":\"jacksonb45@email.com\"}]\n[function return] {\"observation\":\"Extracted data for Jackson Briggs\"}\n[call function extractCustomerData with inputs {\"name\":\"Aria Patel\",\"age\":27,\"email\":\"apatel27@email.com\"}]\n[function return] {\"observation\":\"Extracted data for Aria Patel\"}\n[call function extractCustomerData with inputs {\"name\":\"Liam Tanaka\",\"age\":28,\"email\":\"liam.tanaka@email.com\"}]\n[function return] {\"observation\":\"Extracted data for Liam Tanaka\"}\n[call function extractCustomerData with inputs {\"name\":\"Sofia Russo\",\"age\":24,\"email\":\"sofia.russo124@email.com\"}]\n[function return] {\"observation\":\"Extracted data for Sofia Russo\"}\n[think]\nI have extracted the customer data as follows:\n- John Doe, 35 years old, email: johndoe@email.com\n- Jane Smith, 28 years old, email: janesmith@email.com\n- Alex Lee, 29 years old, email: alexlee@email.com\n- Evelyn Carter, 32 years old, email: evelyncarter32@email.com\n- Jackson Briggs, 45 years old, email: jacksonb45@email.com\n- Aria Patel, 27 years old, email: apatel27@email.com\n- Liam Tanaka, 28 years old, email: liam.tanaka@email.com\n- Sofia Russo, 24 years old, email: sofia.russo124@email.com\n\nIf you need the data in a specific format or further assistance, please let me know.\n","truncated":false}}
%---
%[output:7593e778]
%   data: {"dataType":"tabular","outputData":{"columnNames":["name","age","email"],"columns":3,"dataTypes":["string","double","string"],"header":"8×3 table","name":"ans","rows":8,"type":"table","value":[["\"John Doe\"","35","\"johndoe@email.com\""],["\"Jane Smith\"","28","\"janesmith@email.com\""],["\"Alex Lee\"","29","\"alexlee@email.com\""],["\"Evelyn Carter\"","32","\"evelyncarter32@email.com\""],["\"Jackson Briggs\"","45","\"jacksonb45@email.com\""],["\"Aria Patel\"","27","\"apatel27@email.com\""],["\"Liam Tanaka\"","28","\"liam.tanaka@email.com\""],["\"Sofia Russo\"","24","\"sofia.russo124@email.com\""]]}}
%---
