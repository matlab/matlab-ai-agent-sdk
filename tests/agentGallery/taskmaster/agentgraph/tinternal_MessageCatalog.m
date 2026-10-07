classdef tinternal_MessageCatalog < matlab.unittest.TestCase
%TINTERNAL_MESSAGECATALOG  Internal checks on agentgraph.internal.MessageCatalog.
%
%   Internal, not API: downstream code must not depend on what is asserted here.
%   Hole substitution is asserted through AgentGraph in tAgentGraph, where it is
%   a guarantee; what is left here is the mistyped-id path, which no public call
%   can reach.

%   Copyright 2026 The MathWorks, Inc.

    methods (TestClassSetup)
        function addToPath(testCase)
            repoRoot = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'agentGallery', 'taskmaster')));
        end
    end

    methods (Test, TestTags = {'Unit', 'Internal'})

        function throwError_withUnknownId_throws(testCase)
            % Fails on the lookup rather than throwing the id it was handed.
            testCase.verifyError( ...
                @() agentgraph.internal.MessageCatalog.throwError("agentgraph:noSuchId"), ...
                "MATLAB:dictionary:ScalarKeyNotFound");
        end
    end
end
