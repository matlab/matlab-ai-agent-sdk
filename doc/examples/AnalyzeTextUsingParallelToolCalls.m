%[text] # Analyze Text Data Using Parallel Function Calls with ChatGPT™
%[text] This example shows how to detect multiple function calls in a single user prompt and use this to extract information from text data.
%[text] Function calls allow you to describe a function to ChatGPT in a structured way. When you pass a function to the model together with a prompt, the model detects how often the function needs to be called in the context of the prompt. If the function is called at least once, then the model creates a JSON object containing the function and argument to request.
%[text] This example contains four steps:
%[text] - Create a client specifying which model you're going to call.
%[text] - Create an "LLM tool" to extract data out of the text.
%[text] - Create an unstructured text document containing fictional customer data.
%[text] - Set up and run an agent to perform this task.
%%
%[text] ## Select LLM to Call
%[text] Specify the model to be `"gpt-4.1-mini"`, which supports parallel function calls.
api = "openai"; %[control:dropdown:3f83]{"position":[7,15]}
model = "gpt-4.1-mini"; %[control:dropdown:6e80]{"position":[9,23]}
llm = aisdk.LLMClient(api, model) %[output:1b130a97]
%%
%[text] ## Tools
%[text] Define the function that extracts data from the customer record.
function [obs, workspace] = extractCustomerData(workspace, name, age, email)
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
    obs = "Extracted data for " + name;
end

structuredInput = struct( ...
    name="Jane Goodall", ...
    age=91, ...
    email="unknown");
inputsSpec = aisdk.LLMToolArgument(structuredInput);
extractionTool = aisdk.LLMTool(@extractCustomerData, ...
    Description="Extract structured customer data from text", ...
    InputArguments=inputsSpec, ...
    RequiresApproval="never", ... %[control:dropdown:2476]{"position":[21,28]}
    Workspace = "agent");
%%
%[text] ## Extracting data from text
%[text] Create an agent object. 
agent = aisdk.AIAgent(llm, ...
    "You are an AI assistant designed to extract customer data and return it in a given format.", ...
    extractionTool);
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
resp = run(agent,"Extract data from the record: " + record);
disp(resp) %[output:7f3522b1]
%[text] The text response often contains the data in a fairly structured format already. The tool has also stored the data in the agent "workspace":
agent.Workspace.customerData %[output:2bf1a91a]
%%
%[text] ## Calling another function
%[text] Define a function that filters the customer data by age.
function [json, data] = searchCustomerData(data, minAge, maxAge)
    data.filteredCustomerData = data.customerData(data.customerData.age >= minAge & data.customerData.age <= maxAge,:);
    json = jsonencode(data.filteredCustomerData);
end
inputsSpec2 = struct("minAge", 1, "maxAge", 99);

filteringTool = aisdk.LLMTool(@searchCustomerData, ...
    Description="Get the customers who match the specified and age", ...
    InputArguments=inputsSpec2, ...
    RequiresApproval="never", ... %[control:dropdown:2ead]{"position":[21,28]}
    Workspace = "agent");
%%
%[text] Run the agent using this tool. 
prompt = "Who are our customers who are both under 30 and older than 27? " + ...
    "Use the tools provided."; % qwen3 needed this second instruction
resp2 = run(agent, prompt, Tools=filteringTool);
disp(resp2) %[output:1bff45ab]
agent.Workspace.filteredCustomerData %[output:015c50a1]
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
%   data: {"defaultValue":"\"Never\"","itemLabels":["\"Never\"","\"Always\""],"items":["\"Never\"","\"Always\""],"label":"RequiresApproval","run":"Section"}
%---
%[control:dropdown:2ead]
%   data: {"defaultValue":"\"Never\"","itemLabels":["\"Never\"","\"Always\""],"items":["\"Never\"","\"Always\""],"label":"RequiresApproval","run":"Section"}
%---
%[output:1b130a97]
%   data: {"dataType":"textualVariable","outputData":{"name":"llm","value":"  <a href=\"matlab:helpPopup('aisdk.llms.client.OpenAIClient')\" style=\"font-weight:bold\">OpenAIClient<\/a> with properties:\n\n         Temperature: \"auto\"\n                TopP: \"auto\"\n       StopSequences: [1×0 string]\n        MaxNumTokens: Inf\n     PresencePenalty: \"auto\"\n    FrequencyPenalty: \"auto\"\n      NumCompletions: 1\n                Seed: []\n      ResponseFormat: \"text\"\n     ReasoningEffort: \"auto\"\n           Verbosity: \"auto\"\n             TimeOut: 120\n           StreamFcn: []\n           ModelName: \"gpt-4.1-mini\"\n            Endpoint: \"https:\/\/api.openai.com\/v1\/chat\/completions\"\n"}}
%---
%[output:7f3522b1]
%   data: {"dataType":"text","outputData":{"text":"Here is the extracted customer data:\n\n1. John Doe, 35 years old, johndoe@email.com\n2. Jane Smith, 28 years old, janesmith@email.com\n3. Alex Lee, 29 years old, alexlee@email.com\n4. Evelyn Carter, 32 years old, evelyncarter32@email.com\n5. Jackson Briggs, 45 years old, jacksonb45@email.com\n6. Aria Patel, 27 years old, apatel27@email.com\n7. Liam Tanaka, 28 years old, liam.tanaka@email.com\n8. Sofia Russo, 24 years old, sofia.russo124@email.com\n\nLet me know if you need any further processing or formatting.\n","truncated":false}}
%---
%[output:2bf1a91a]
%   data: {"dataType":"tabular","outputData":{"columnNames":["name","age","email"],"columns":3,"dataTypes":["string","double","string"],"header":"8×3 table","name":"ans","rows":8,"type":"table","value":[["\"John Doe\"","35","\"johndoe@email.com\""],["\"Jane Smith\"","28","\"janesmith@email.com\""],["\"Alex Lee\"","29","\"alexlee@email.com\""],["\"Evelyn Carter\"","32","\"evelyncarter32@email.com\""],["\"Jackson Briggs\"","45","\"jacksonb45@email.com\""],["\"Aria Patel\"","27","\"apatel27@email.com\""],["\"Liam Tanaka\"","28","\"liam.tanaka@email.com\""],["\"Sofia Russo\"","24","\"sofia.russo124@email.com\""]]}}
%---
%[output:1bff45ab]
%   data: {"dataType":"text","outputData":{"text":"The customers who are both under 30 and older than 27 are:\n\n1. Jane Smith, 28 years old, janesmith@email.com\n2. Alex Lee, 29 years old, alexlee@email.com\n3. Liam Tanaka, 28 years old, liam.tanaka@email.com\n","truncated":false}}
%---
%[output:015c50a1]
%   data: {"dataType":"tabular","outputData":{"columnNames":["name","age","email"],"columns":3,"dataTypes":["string","double","string"],"header":"3×3 table","name":"ans","rows":3,"type":"table","value":[["\"Jane Smith\"","28","\"janesmith@email.com\""],["\"Alex Lee\"","29","\"alexlee@email.com\""],["\"Liam Tanaka\"","28","\"liam.tanaka@email.com\""]]}}
%---
