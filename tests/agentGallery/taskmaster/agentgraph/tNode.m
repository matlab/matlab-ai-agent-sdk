classdef tNode < matlab.unittest.TestCase
%TNODE  Access contract shared by concrete graph nodes.

% Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addToPath(testCase)
            repoRoot = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'agentGallery', 'taskmaster')));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function Node_setName_afterConstruction_throwsSetProhibited(testCase)
            node = agentgraph.FunctionNode("A", @(w) deal("a", w));

            testCase.verifyError(@() setName(node), ...
                "MATLAB:class:SetProhibited");
        end

        function Node_setDescription_afterConstruction_throwsSetProhibited(testCase)
            node = agentgraph.FunctionNode("A", @(w) deal("a", w));

            testCase.verifyError(@() setDescription(node), ...
                "MATLAB:class:SetProhibited");
        end
    end
end

function setName(node)
node.Name = "B";
end

function setDescription(node)
node.Description = "Changed";
end
