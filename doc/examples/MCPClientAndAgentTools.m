%[text] # MCP Client and Agent Tools
%[text] This requires `mcpHTTPClient` that is available [here](https://github.com/matlab-deep-learning/mcpHTTPClient).
%%
%[text] This also requires an MCP server, e.g. one set running using [this Python MCP SDK example](https://github.com/modelcontextprotocol/python-sdk/blob/main/examples/snippets/servers/streamable_starlette_mount.py).
endpoint = "http://127.0.0.1:8000/math/mcp";
myMCPClient = mcpHTTPClient(endpoint) %[output:05762e2e]
%%
%[text] View the tools returned by the MCP client:
toolsAsStructs = myMCPClient.ServerTools %[output:6c954cc4]
jsonencode(toolsAsStructs{2}.inputSchema, 'PrettyPrint', true) %[output:403e4326]
%%
%[text] We can generate tools from the MCP tools specs by providing a handle to the myMCPClient call method along with the tool descriptions:
tools = aisdk.LLMTool(myMCPClient) %[output:61bf847d]
%%
%[text] ### Set Up Client and an Agent
api = "openai"; %[control:dropdown:76b7]{"position":[7,15]}
model = "gpt-4.1-mini"; %[control:dropdown:13b4]{"position":[9,23]}
client = aisdk.LLMClient(api, model);
sysPrompt = "You are a helpful assistant who has some tools to perform arithmetic operations. Only answer arithmetic questions " ...
    + "about integers. Only use the given tools to answer those questions. If the tools don't look right for the job, say you don't " + ...
    "know the answer";
agent = aisdk.AIAgent(client, SystemPrompt=sysPrompt, Tools=tools);
%%
%[text] ### Use Tools Through the Agent
response = agent.run("What's 123 + 100100100?") %[output:210a5e38] %[output:467f06b2]
%%
%[text] ### Look at the history to see how the answer was found
agent.Messages %[output:673c6999]
%[text] *Copyright 2026 The MathWorks, Inc.*

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":40}
%---
%[control:dropdown:76b7]
%   data: {"defaultValue":"\"openai\"","itemLabels":["openai","ollama"],"items":["\"openai\"","\"ollama\""],"label":"provider","run":"Section"}
%---
%[control:dropdown:13b4]
%   data: {"defaultValue":"\"gpt-4.1-mini\"","itemLabels":["gpt-4.1-mini","qwen3"],"items":["\"gpt-4.1-mini\"","\"qwen3\""],"label":"model","run":"Section"}
%---
%[output:05762e2e]
%   data: {"dataType":"textualVariable","outputData":{"name":"myMCPClient","value":"  mcpHTTPClient with properties:\n\n       Endpoint: \"http:\/\/127.0.0.1:8000\/math\/mcp\"\n    ServerTools: {[1×1 struct]  [1×1 struct]}\n"}}
%---
%[output:6c954cc4]
%   data: {"dataType":"tabular","outputData":{"columns":2,"header":"1×2 cell array","name":"toolsAsStructs","rows":1,"type":"cell","value":[["1×1 struct","1×1 struct"]]}}
%---
%[output:403e4326]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"    '{\n       \"properties\": {\n         \"a\": {\n           \"title\": \"A\",\n           \"type\": \"integer\"\n         },\n         \"b\": {\n           \"title\": \"B\",\n           \"type\": \"integer\"\n         }\n       },\n       \"required\": [\n         \"a\",\n         \"b\"\n       ],\n       \"title\": \"addTwoNumbersArguments\",\n       \"type\": \"object\"\n     }'\n"}}
%---
%[output:61bf847d]
%   data: {"dataType":"textualVariable","outputData":{"name":"tools","value":"  1×2 MCPTool array with properties:\n\n    Name\n    Description\n    InputSchema\n    OutputSchema\n    RequiresApproval\n    DisplayTitle\n    Annotations\n"}}
%---
%[output:210a5e38]
%   data: {"dataType":"text","outputData":{"text":"[think]\n[call function addTwoNumbers with inputs {\"a\":123,\"b\":1.001001E+8}]\n[function return] \"100100223\"\n[think]\n123 + 100100100 = 100100223\n","truncated":false}}
%---
%[output:467f06b2]
%   data: {"dataType":"textualVariable","outputData":{"name":"response","value":"\"123 + 100100100 = 100100223\""}}
%---
%[output:673c6999]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"  1×4 LLMMessage array with messages:\n\n    1    User         Text         \"What's 123 + 100100100?\"\n    2    Assistant    Tool Call    \"addTwoNumbers({\"a\":123,\"b\":1.001001E+8})\"\n    3    Tool         Text         \"100100223\"\n    4    Assistant    Text         \"123 + 100100100 = 100100223\"\n"}}
%---
