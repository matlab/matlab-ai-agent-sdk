%[text] # MCP Client and Agent Tools
%[text] This requires `mcpHTTPClient` that is available [here](https://github.com/matlab-deep-learning/mcpHTTPClient).
%%
%[text] This also requires an MCP server, e.g. one set running using [this Python MCP SDK example](https://github.com/modelcontextprotocol/python-sdk/blob/main/examples/snippets/servers/streamable_starlette_mount.py).
endpoint = "http://127.0.0.1:8000/math/mcp";
myMCPClient = mcpHTTPClient(endpoint) %[output:4e55ba10]
%%
%[text] View the tools returned by the MCP client:
toolsAsStructs = myMCPClient.ServerTools %[output:349f1b1a]
jsonencode(toolsAsStructs{2}.inputSchema, 'PrettyPrint', true) %[output:6bac51c6]
%%
%[text] We can generate tools from the MCP tools specs by providing a handle to the myMCPClient call method along with the tool descriptions:
tools = aisdk.LLMTool(myMCPClient) %[output:3f3e433f]
%%
%[text] ### Set Up Client and an Agent
api = "openai"; %[control:dropdown:76b7]{"position":[7,15]}
model = "gpt-4.1-mini"; %[control:dropdown:13b4]{"position":[9,23]}
client = aisdk.LLMClient(api, model);
sysPrompt = "You are a helpful assistant who has some tools to perform arithmetic operations. Only answer arithmetic questions " ...
    + "about integers. Only use the given tools to answer those questions. If the tools don't look right for the job, say you don't " + ...
    "know the answer";
agent = aisdk.AIAgent(client, sysPrompt, tools);
%%
%[text] ### Use Tools Through the Agent
response = agent.run("What's 123 + 100100100?") %[output:47ac62a5]
%%
%[text] ### Look at the history to see how the answer was found
agent.Messages %[output:1eb8332f]
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
%[output:4e55ba10]
%   data: {"dataType":"textualVariable","outputData":{"name":"myMCPClient","value":"  <a href=\"matlab:helpPopup('mcpHTTPClient')\" style=\"font-weight:bold\">mcpHTTPClient<\/a> with properties:\n\n       Endpoint: \"http:\/\/127.0.0.1:8000\/math\/mcp\"\n    ServerTools: {[1×1 struct]  [1×1 struct]}\n"}}
%---
%[output:349f1b1a]
%   data: {"dataType":"tabular","outputData":{"columns":2,"header":"1×2 cell array","name":"toolsAsStructs","rows":1,"type":"cell","value":[["1×1 struct","1×1 struct"]]}}
%---
%[output:6bac51c6]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"    '{\n       \"properties\": {\n         \"a\": {\n           \"title\": \"A\",\n           \"type\": \"integer\"\n         },\n         \"b\": {\n           \"title\": \"B\",\n           \"type\": \"integer\"\n         }\n       },\n       \"required\": [\n         \"a\",\n         \"b\"\n       ],\n       \"title\": \"addTwoNumbersArguments\",\n       \"type\": \"object\"\n     }'\n"}}
%---
%[output:3f3e433f]
%   data: {"dataType":"textualVariable","outputData":{"name":"tools","value":"  1×2 <a href=\"matlab:helpPopup('aisdk.llms.tool.MCPTool')\" style=\"font-weight:bold\">MCPTool<\/a> array with properties:\n\n    Name\n    Description\n    InputArguments\n    OutputArguments\n    RequiresApproval\n    DisplayTitle\n    Annotations\n"}}
%---
%[output:47ac62a5]
%   data: {"dataType":"textualVariable","outputData":{"name":"response","value":"\"123 + 100100100 = 100100223.\""}}
%---
%[output:1eb8332f]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"  1×4 <a href=\"matlab:helpPopup('aisdk.llms.message.LLMMessage')\" style=\"font-weight:bold\">LLMMessage<\/a> array with messages:\n\n    1    User         Text         \"What's 123 + 100100100?\"\n    2    Assistant    Tool Call    addTwoNumbers\n    3    Tool         Text         \"100100223\"\n    4    Assistant    Text         \"123 + 100100100 = 100100223\"\n"}}
%---
