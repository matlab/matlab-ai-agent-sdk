%[text] # MCP Client and Agent Tools
%[text] This requires `mcpHTTPClient` that is available [here](https://github.com/matlab-deep-learning/mcpHTTPClient).
%%
%[text] This also requires an MCP server, e.g. one set running using [this Python MCP SDK example](https://github.com/modelcontextprotocol/python-sdk/blob/main/examples/snippets/servers/streamable_starlette_mount.py).
endpoint = "http://127.0.0.1:8000/math/mcp";
myMCPClient = mcpHTTPClient(endpoint) %[output:969747a2]
%%
%[text] View the tools returned by the MCP client:
toolsAsStructs = myMCPClient.ServerTools %[output:2307681b]
jsonencode(toolsAsStructs{2}.inputSchema, 'PrettyPrint', true) %[output:3c758688]
%%
%[text] We can generate tools from the MCP tools specs by providing a handle to the myMCPClient call method along with the tool descriptions:
tools = aisdk.LLMTool(myMCPClient) %[output:03ea0287]
%%
%[text] MCP tools default to `ApprovalRequest="once"`, so the agent asks for approval before it first calls each of them. These tools only do arithmetic, so allow the agent to call them without approval:
[tools.ApprovalRequest] = deal("never");
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
response = agent.run("What's 123 + 100100100?") %[output:55282d5c] %[output:767663f5]
%%
%[text] ### Look at the history to see how the answer was found
agent.Messages %[output:7690a2b3]
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
%[output:969747a2]
%   data: {"dataType":"textualVariable","outputData":{"name":"myMCPClient","value":"  <a href=\"matlab:helpPopup('mcpHTTPClient')\" style=\"font-weight:bold\">mcpHTTPClient<\/a> with properties:\n\n       Endpoint: \"http:\/\/127.0.0.1:8000\/math\/mcp\"\n    ServerTools: {[1×1 struct]  [1×1 struct]}\n"}}
%---
%[output:2307681b]
%   data: {"dataType":"tabular","outputData":{"columns":2,"header":"1×2 cell array","name":"toolsAsStructs","rows":1,"type":"cell","value":[["1×1 struct","1×1 struct"]]}}
%---
%[output:3c758688]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"    '{\n       \"properties\": {\n         \"a\": {\n           \"title\": \"A\",\n           \"type\": \"integer\"\n         },\n         \"b\": {\n           \"title\": \"B\",\n           \"type\": \"integer\"\n         }\n       },\n       \"required\": [\n         \"a\",\n         \"b\"\n       ],\n       \"title\": \"addTwoNumbersArguments\",\n       \"type\": \"object\"\n     }'\n"}}
%---
%[output:03ea0287]
%   data: {"dataType":"textualVariable","outputData":{"name":"tools","value":"  1×2 LLMTool array with tools:\n\n         <strong>Syntax<\/strong>                 <strong>Description<\/strong>             <strong>Type<\/strong>      <strong>Workspace<\/strong>\n    <strong>________________<\/strong>    <strong>___________________________<\/strong>    <strong>_______<\/strong>    <strong>_________<\/strong>\n\n    add_two(…)          Increment an integer by two    MCPTool     \"none\"  \n    addTwoNumbers(…)    Add two numbers together       MCPTool     \"none\"  \n"}}
%---
%[output:55282d5c]
%   data: {"dataType":"text","outputData":{"text":"[think]\n[call function addTwoNumbers with inputs {\"a\":123,\"b\":1.001001E+8}]\n[function return] \"100100223\"\n[think]\n123 + 100100100 equals 100100223.\n","truncated":false}}
%---
%[output:767663f5]
%   data: {"dataType":"textualVariable","outputData":{"name":"response","value":"\"123 + 100100100 equals 100100223.\""}}
%---
%[output:7690a2b3]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"  1×4 <a href=\"matlab:helpPopup('aisdk.message.LLMMessage')\" style=\"font-weight:bold\">LLMMessage<\/a> array with messages:\n\n    1    User         Text         \"What's 123 + 100100100?\"\n    2    Assistant    Tool Call    \"addTwoNumbers({\"a\":123,\"b\":1.001001E+8})\"\n    3    Tool         Text         \"100100223\"\n    4    Assistant    Text         \"123 + 100100100 equals 100100223.\"\n"}}
%---
