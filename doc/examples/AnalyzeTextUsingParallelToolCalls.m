%[text] # Analyze Text Data Using Parallel Function Calls with ChatGPT™
%[text] This example shows how to detect multiple function calls in a single user prompt and use this to extract information from text data.
%[text] Function calls allow you to describe a function to ChatGPT in a structured way. When you pass a function to the model together with a prompt, the model detects how often the function needs to be called in the context of the prompt. If the function is called at least once, then the model creates a JSON object containing the function and argument to request.
%[text] This example contains four steps:
%[text] - Create a client specifying which model you're going to call.
%[text] - Create an "LLM tool" to extract data out of the text.
%[text] - Create an unstructured text document containing fictional customer data.
%[text] - Set up and run an agent to perform this task. \
%%
%[text] ## Select LLM to Call
%[text] Specify the model to be `"gpt-4.1-mini"`, which supports parallel function calls.
api = "openai"; %[control:dropdown:3f83]{"position":[7,15]}
model = "gpt-4.1-mini"; %[control:dropdown:6e80]{"position":[9,23]}
llm = aisdk.LLMClient(api, model) %[output:1b130a97]
%%
%[text] ## Tools
%[text] Define the function that extracts data from the customer record.
function [observation, workspace] = extractCustomerData(workspace, name, age, email)
%Extract structured customer data from text
    arguments
        workspace(1,1) struct
        name(1,1) string
        age(1,1) double
        email(1,1) string
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

extractionTool = aisdk.LLMTool(@extractCustomerData, ...
    RequiresApproval="never", ... %[control:dropdown:2476]{"position":[22,29]}
    Workspace = "agent");
%%
%[text] ## Extracting data from text
%[text] Create an agent object. 
agent = aisdk.AIAgent(llm, ...
    SystemPrompt="You are an AI assistant designed to extract customer data and return it in a given format.", ...
    Tools=extractionTool);
%%
%[text] The customer record contains fictional information. 
record = ["Customer John Doe, 35 years old. Email: johndoe@email.com"; ...
    "Jane Smith, age 28. Email address: janesmith@email.com";
    "Customer named Alex Lee, 29, with email alexlee@email.com";
    "Evelyn Carter, 32, email: evelyncarter32@email.com";
    "Jackson Briggs is 45 years old. Contact email: jacksonb45@email.com";
    "Aria Patel, 27 years old. Email contact: apatel27@email.com";
    "Liam Tanaka, aged 28. Email: liam.tanaka@email.com";
    "Sofia Russo, 24 years old, email: sofia.russo124@email.com"];
record = join(record);
%[text] Generate a response and extract the data.
resp = run(agent,"Extract data from the record: " + record); %[output:7f3522b1]
disp(resp) %[output:0952152a]
%[text] The text response often contains the data in a fairly structured format already. The tool has also stored the data in the agent "workspace":
agent.Workspace.customerData %[output:1cb1e815]
%%
%[text] ## Calling another function
%[text] Define a function that filters the customer data by age.
function [json, data] = searchCustomerData(data, minAge, maxAge)
% Get the customers who match the specified and age
    arguments
        data 
        minAge(1,1) double
        maxAge(1,1) double
    end
    data.filteredCustomerData = data.customerData(data.customerData.age >= minAge & data.customerData.age <= maxAge,:);
    json = jsonencode(data.filteredCustomerData);
end
filteringTool = aisdk.LLMTool(@searchCustomerData, ...
    RequiresApproval="never", ... %[control:dropdown:2ead]{"position":[22,29]}
    Workspace = "agent");
%%
%[text] Run the agent using this tool. 
prompt = "Who are our customers who are both under 30 and older than 27? " + ...
    "Use the tools provided."; % qwen3 needed this second instruction
resp2 = run(agent, prompt, Tools=filteringTool); %[output:22c8241f]
disp(resp2) %[output:2f3157b2]
agent.Workspace.filteredCustomerData %[output:134df723]
%[text] *Copyright 2026 The MathWorks, Inc.*

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":40}
%---
%[control:dropdown:3f83]
%   data: {"defaultValue":"\"openai\"","itemLabels":["openai","ollama"],"items":["\"openai\"","\"ollama\""],"label":"provider","run":"Section"}
%---
%[control:dropdown:6e80]
%   data: {"defaultValue":"\"gpt-4.1-mini\"","itemLabels":["gpt-4.1-mini","qwen3"],"items":["\"gpt-4.1-mini\"","\"qwen3\""],"label":"model","run":"Section"}
%---
%[control:dropdown:2476]
%   data: {"defaultValue":"\"always\"","itemLabels":["always","once","never"],"items":["\"always\"","\"once\"","\"never\""],"label":"RequiresApproval","run":"Section"}
%---
%[control:dropdown:2ead]
%   data: {"defaultValue":"\"always\"","itemLabels":["always","once","never"],"items":["\"always\"","\"once\"","\"never\""],"label":"RequiresApproval","run":"Section"}
%---
%[output:1b130a97]
%   data: {"dataType":"textualVariable","outputData":{"name":"llm","value":"  <a href=\"matlab:helpPopup('aisdk.llms.client.OpenAIClient')\" style=\"font-weight:bold\">OpenAIClient<\/a> with properties:\n\n                 API: \"openai\"\n           ModelName: \"gpt-4.1-mini\"\n             BaseURL: \"https:\/\/api.openai.com\/v1\/chat\/completions\"\n        MaxNumTokens: Inf\n     ReasoningEffort: \"auto\"\n       StopSequences: []\n           StreamFcn: []\n             TimeOut: 120\n      ResponseFormat: \"text\"\n           Verbosity: \"auto\"\n         Temperature: \"auto\"\n                TopP: \"auto\"\n     PresencePenalty: \"auto\"\n    FrequencyPenalty: \"auto\"\n"}}
%---
%[output:7f3522b1]
%   data: {"dataType":"text","outputData":{"text":"[think]\n[call function extractCustomerData with inputs {\"name\":\"John Doe\",\"age\":35,\"email\":\"johndoe@email.com\"}]\n[function return] {\"observation\":\"Extracted data for John Doe\"}\n[call function extractCustomerData with inputs {\"name\":\"Jane Smith\",\"age\":28,\"email\":\"janesmith@email.com\"}]\n[function return] {\"observation\":\"Extracted data for Jane Smith\"}\n[call function extractCustomerData with inputs {\"name\":\"Alex Lee\",\"age\":29,\"email\":\"alexlee@email.com\"}]\n[function return] {\"observation\":\"Extracted data for Alex Lee\"}\n[call function extractCustomerData with inputs {\"name\":\"Evelyn Carter\",\"age\":32,\"email\":\"evelyncarter32@email.com\"}]\n[function return] {\"observation\":\"Extracted data for Evelyn Carter\"}\n[call function extractCustomerData with inputs {\"name\":\"Jackson Briggs\",\"age\":45,\"email\":\"jacksonb45@email.com\"}]\n[function return] {\"observation\":\"Extracted data for Jackson Briggs\"}\n[call function extractCustomerData with inputs {\"name\":\"Aria Patel\",\"age\":27,\"email\":\"apatel27@email.com\"}]\n[function return] {\"observation\":\"Extracted data for Aria Patel\"}\n[call function extractCustomerData with inputs {\"name\":\"Liam Tanaka\",\"age\":28,\"email\":\"liam.tanaka@email.com\"}]\n[function return] {\"observation\":\"Extracted data for Liam Tanaka\"}\n[call function extractCustomerData with inputs {\"name\":\"Sofia Russo\",\"age\":24,\"email\":\"sofia.russo124@email.com\"}]\n[function return] {\"observation\":\"Extracted data for Sofia Russo\"}\n[think]\nI have extracted the customer data as follows:\n1. John Doe, 35 years old, email: johndoe@email.com\n2. Jane Smith, 28 years old, email: janesmith@email.com\n3. Alex Lee, 29 years old, email: alexlee@email.com\n4. Evelyn Carter, 32 years old, email: evelyncarter32@email.com\n5. Jackson Briggs, 45 years old, email: jacksonb45@email.com\n6. Aria Patel, 27 years old, email: apatel27@email.com\n7. Liam Tanaka, 28 years old, email: liam.tanaka@email.com\n8. Sofia Russo, 24 years old, email: sofia.russo124@email.com\n\nIf you need the data in a specific format or file, please let me know!\n","truncated":false}}
%---
%[output:0952152a]
%   data: {"dataType":"text","outputData":{"text":"I have extracted the customer data as follows:\n1. John Doe, 35 years old, email: johndoe@email.com\n2. Jane Smith, 28 years old, email: janesmith@email.com\n3. Alex Lee, 29 years old, email: alexlee@email.com\n4. Evelyn Carter, 32 years old, email: evelyncarter32@email.com\n5. Jackson Briggs, 45 years old, email: jacksonb45@email.com\n6. Aria Patel, 27 years old, email: apatel27@email.com\n7. Liam Tanaka, 28 years old, email: liam.tanaka@email.com\n8. Sofia Russo, 24 years old, email: sofia.russo124@email.com\n\nIf you need the data in a specific format or file, please let me know!\n","truncated":false}}
%---
%[output:1cb1e815]
%   data: {"dataType":"tabular","outputData":{"columnNames":["name","age","email"],"columns":3,"dataTypes":["string","double","string"],"header":"8×3 table","name":"ans","rows":8,"type":"table","value":[["\"John Doe\"","35","\"johndoe@email.com\""],["\"Jane Smith\"","28","\"janesmith@email.com\""],["\"Alex Lee\"","29","\"alexlee@email.com\""],["\"Evelyn Carter\"","32","\"evelyncarter32@email.com\""],["\"Jackson Briggs\"","45","\"jacksonb45@email.com\""],["\"Aria Patel\"","27","\"apatel27@email.com\""],["\"Liam Tanaka\"","28","\"liam.tanaka@email.com\""],["\"Sofia Russo\"","24","\"sofia.russo124@email.com\""]]}}
%---
%[output:22c8241f]
%   data: {"dataType":"text","outputData":{"text":"[think]\n[call function searchCustomerData with inputs {\"minAge\":28,\"maxAge\":29}]\n[function return] {\"json\":\"[{\\\"name\\\":\\\"Jane Smith\\\",\\\"age\\\":28,\\\"email\\\":\\\"janesmith@email.com\\\"},{\\\"name\\\":\\\"Alex Lee\\\",\\\"age\\\":29,\\\"email\\\":\\\"alexlee@email.com\\\"},{\\\"name\\\":\\\"Liam Tanaka\\\",\\\"age\\\":28,\\\"email\\\":\\\"liam.tanaka@email.com\\\"}]\"}\n[think]\nThe customers who are older than 27 and under 30 are:\n1. Jane Smith, 28 years old, email: janesmith@email.com\n2. Alex Lee, 29 years old, email: alexlee@email.com\n3. Liam Tanaka, 28 years old, email: liam.tanaka@email.com\n","truncated":false}}
%---
%[output:2f3157b2]
%   data: {"dataType":"text","outputData":{"text":"The customers who are older than 27 and under 30 are:\n1. Jane Smith, 28 years old, email: janesmith@email.com\n2. Alex Lee, 29 years old, email: alexlee@email.com\n3. Liam Tanaka, 28 years old, email: liam.tanaka@email.com\n","truncated":false}}
%---
%[output:134df723]
%   data: {"dataType":"tabular","outputData":{"columnNames":["name","age","email"],"columns":3,"dataTypes":["string","double","string"],"header":"3×3 table","name":"ans","rows":3,"type":"table","value":[["\"Jane Smith\"","28","\"janesmith@email.com\""],["\"Alex Lee\"","29","\"alexlee@email.com\""],["\"Liam Tanaka\"","28","\"liam.tanaka@email.com\""]]}}
%---
