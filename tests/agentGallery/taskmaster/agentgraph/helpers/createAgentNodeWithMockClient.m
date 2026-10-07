function [node, client] = createAgentNodeWithMockClient(name, runs)
%CREATEAGENTNODEWITHMOCKCLIENT  Agent node with a client that records inputs.

% Copyright 2026 The MathWorks, Inc.

arguments
    name (1,1) string
    runs (1,1) double {mustBeInteger, mustBePositive} = 1
end

client = MockClient();
tokenInfo = struct("Tokens", struct( ...
    "NumInputTokens", 1, "NumOutputTokens", 1, ...
    "NumTotalTokens", 2, "NumCachedInputTokens", 0));
row = {"recorded", aisdk.LLMTextMessage("recorded", Role="assistant"), tokenInfo};
client.GenerateOutputs = repmat({row}, runs, 1);
agent = aisdk.AIAgent(client, DisplayMode="off", MaxIterations=1);
node = agentgraph.AgentNode(name, agent, Description="Record the request");
end
