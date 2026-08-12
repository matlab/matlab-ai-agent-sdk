function allTools = createSerdesTools()
%CREATESERDESTOOLS  Build the SerDes LLM tool array from tools/ directory.
%
%   allTools = createSerdesTools() returns an array of aisdk.LLMTool objects
%   registered from all .m files under demos/serdes/tools/. Errors from
%   missing toolboxes are rethrown; other schema conversion failures (e.g.
%   struct-typed args) are skipped with a warning.

    toolsDir = fullfile(fileparts(mfilename('fullpath')), "tools");
    addpath(toolsDir);

    toolFiles = dir(fullfile(toolsDir, '*.m'));
    allTools = aisdk.llms.tool.LLMTool.empty(1, 0);
    for i = 1:numel(toolFiles)
        [~, toolName] = fileparts(toolFiles(i).name);
        try
            allTools(end+1) = aisdk.LLMTool(str2func(toolName), Workspace="agent"); %#ok<AGROW>
        catch ex
            if startsWith(ex.identifier, "MATLAB:undefinedVarOrClass") ...
                    || startsWith(ex.identifier, "MATLAB:UndefinedFunction")
                rethrow(ex);
            end
            warning("agentgraph:ToolSkipped", ...
                "Skipping tool '%s': %s", toolName, ex.message);
        end
    end
end
