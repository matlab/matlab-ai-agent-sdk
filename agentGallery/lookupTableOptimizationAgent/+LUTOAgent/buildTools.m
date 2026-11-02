function tools = buildTools()
%buildTools Construct the array of LLMTool objects for the LUTO agent.
%   Registers every .m file in +LUTOAgent/+tools as a tool and lets
%   aisdk.LLMTool auto-detect each one's name, description, and argument
%   schema from the function itself — the H1 help line becomes the tool
%   description the LLM sees, and the arguments block supplies the parameter
%   names, JSON types, and required/name-value flags. The LLM-facing contract
%   therefore lives next to the implementation: to add a tool, drop a file in
%   +tools whose signature is [observation, workspace] = fcn(workspace, ...)
%   and whose H1 line describes what it does.
%
%   All tools share the agent Workspace so problem/solution state persists
%   across the conversation. Read/inspect/save tools run without approval;
%   the mutating tools listed below prompt until permanently approved.

% Copyright 2026 The MathWorks, Inc.

    % Tools that write files or change the user's model. Anything not listed
    % here runs without prompting.
    mutating = ["generateApproximation", "replaceOriginalBlock", "revertReplacement"];

    [fcnNames, toolsDir] = discoverTools();
    checkMutatingToolsExist(fcnNames, mutating, toolsDir);

    approval = repmat("never", size(fcnNames));
    approval(ismember(fcnNames, mutating)) = "once";

    built = cell(1, numel(fcnNames));
    for k = 1:numel(fcnNames)
        built{k} = aisdk.LLMTool(str2func("LUTOAgent.tools." + fcnNames(k)), ...
            Workspace="agent", ApprovalRequest=approval(k));
    end
    tools = [built{:}];
end

% ----------------------------------------------------------------- helpers

function [fcnNames, toolsDir] = discoverTools()
% Names of every tool function in +tools, sorted so the order the LLM sees is
% deterministic across platforms.
    toolsDir = fullfile(fileparts(mfilename("fullpath")), "+tools");
    files = dir(fullfile(toolsDir, "*.m"));
    files = files(~[files.isdir]);
    fcnNames = sort(erase(string({files.name}), ".m" + textBoundary("end")));

    if isempty(fcnNames)
        error("LUTOAgent:buildTools:NoToolsFound", ...
            "No tool functions found in '%s'.", toolsDir);
    end
end

function checkMutatingToolsExist(fcnNames, mutating, toolsDir)
% A rename or move must not silently un-gate a mutating tool.
    missing = setdiff(mutating, fcnNames);
    if ~isempty(missing)
        error("LUTOAgent:buildTools:MissingMutatingTool", ...
            "Approval-gated tool(s) not found in '%s': %s", ...
            toolsDir, strjoin(missing, ", "));
    end
end
