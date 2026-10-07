function [outerNodes, outerEdges] = simulationGraphDefinition(client)
%SIMULATIONGRAPHDEFINITION Two graph levels with one nested taskmaster.

% Copyright 2026 The MathWorks, Inc.

arguments
    client
end

innerNodes = [
    agentgraph.FunctionNode("configureModel", @configureModel, ...
        Description="Set the spring load, stiffness, and displacement limit.")
    agentgraph.FunctionNode("solveModel", @solveModel, ...
        Description="Calculate displacement from the configured spring model.")
    agentgraph.FunctionNode("checkResult", @checkResult, ...
        Description="Check whether displacement is within the limit.")
];
innerEdges = [
    "configureModel", "solveModel"
    "solveModel", "checkResult"
];
innerGraph = agentgraph.AgentGraph(innerNodes, innerEdges, Name="inner");
innerRouter = agentgraph.taskmaster(innerGraph, client, ...
    SystemPrompt=string(fileread(fullfile(fileparts(mfilename("fullpath")), ...
    "prompts", "inner.md"))));

outerNodes = [
    agentgraph.AgentNode("runSimulation", innerRouter, ...
        Description="Run and check the spring simulation.")
    agentgraph.FunctionNode("reportResult", @reportResult, ...
        Description="Report the checked displacement and limit.")
];
outerEdges = ["runSimulation", "reportResult"];
end

function [result, workspace] = configureModel(workspace)
workspace.forceN = 8;
workspace.stiffnessNPerMm = 4;
workspace.limitMm = 3;
result = "Model configured with 8 N load, 4 N/mm stiffness, and 3 mm limit.";
end

function [result, workspace] = solveModel(workspace)
workspace.displacementMm = workspace.forceN / workspace.stiffnessNPerMm;
result = "Calculated displacement: " + workspace.displacementMm + " mm.";
end

function [result, workspace] = checkResult(workspace)
workspace.passed = workspace.displacementMm <= workspace.limitMm;
if workspace.passed
    result = "The displacement is within the limit.";
else
    result = "The displacement exceeds the limit.";
end
end

function [result, workspace] = reportResult(workspace)
if workspace.passed
    verdict = "PASS";
else
    verdict = "FAIL";
end
result = verdict + ": displacement " + workspace.displacementMm + ...
    " mm; limit " + workspace.limitMm + " mm.";
end
