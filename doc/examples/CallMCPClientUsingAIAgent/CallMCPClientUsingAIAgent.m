%[text] # Call MCP Client Using AI Agent
%[text] This example shows how to create and run an AI agent that uses tools provided by an MCP server.
%[text] To run this example, you need:
%[text] - an MCP server `mcpServer`,
%[text] - access to an LLM API `api`,
%[text] - access to a model `model`. \
%%
%[text] ## Create Tool From MCP Server
%[text] To create one or more AI tools from the tools provided by an MCP server, first connect to the MCP server by using the [`aisdk.MCPClient`](file:../../functions/aisdk.MCPClient.md) function. Then, use the client as the input to the [`aisdk.LLMTool`](file:../../functions/aisdk.LLMTool.md) function.
%[text] Create an MCP client from the MCP server `mcpServer`.
mcpClient = aisdk.MCPClient(mcpServer);
%[text] Extract the tools from the MCP server by using the `Tools` property.
tools = mcpClient.Tools;
%[text] If the MCP server provides more than one tool, then `tools` is an array of [`MCPTool`](file:../../functions/MCPTool.md) objects.
%[text] ## Create Agent
%[text] Create an LLM client `client` from the API `api` and the model `model` by using the [`aisdk.LLMClient`](file:../../functions/aisdk.LLMClient.md) function.
client = aisdk.LLMClient(api,model);
%[text] Create an AI agent from the LLM client and the MCP tools `tools`.
agent = aisdk.AIAgent(client,Tools=tools);
%%
%[text] ## Run Agent
%[text] Ask the agent a question and run it. The agent can use the MCP tools to answer the question. For example, if the MCP tools contain a tool called `addTwoNumbers`, you can ask the agent to add two numbers together by using the tool.
response = run(agent,"What's 123 + 100100100."); %[output:55282d5c] %[output:767663f5]
%%
%[text] ## Inspect Message History
%[text] Inspect the message history to confirm that the agent used a tool to answer the query.
agent.Messages %[output:7690a2b3]
%[text] *Copyright 2026 The MathWorks, Inc.*

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":40}
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
