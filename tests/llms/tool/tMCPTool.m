classdef tMCPTool < matlab.unittest.TestCase
% Tests for aisdk.llms.tool.MCPTool.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        DisplayTitleCase = struct( ...
            "topLevelTitleWinsOverNames", struct( ...
                "toolDef", struct("name", "myTool", "title", "My Tool", ...
                    "description", "desc", "inputSchema", struct()), ...
                "expected", "My Tool"), ...
            "topLevelTitleWinsOverAnnotations", struct( ...
                "toolDef", struct("name", "myTool", "title", "Top Level", ...
                    "description", "desc", "inputSchema", struct(), ...
                    "annotations", struct("title", "Annotated Title")), ...
                "expected", "Top Level"), ...
            "annotationsTitleWinsOverName", struct( ...
                "toolDef", struct("name", "myTool", "description", "desc", ...
                    "inputSchema", struct(), "annotations", struct("title", "Annotated Title")), ...
                "expected", "Annotated Title"), ...
            "fallbackToName", struct( ...
                "toolDef", struct("name", "myTool", "description", "desc", ...
                    "inputSchema", struct()), ...
                "expected", "myTool"));
    end

    methods (Test, TestTags = {'Unit'})
        function constructor_singleTool_createsOneMCPTool(testCase)
            mockClient = makeMockClient({ ...
                struct("name", "myTool", "description", "Does stuff", ...
                    "inputSchema", struct("type", "object"))});

            tools = aisdk.llms.tool.MCPTool(mockClient);
            testCase.verifyNumElements(tools, 1);
            testCase.verifyEqual(tools.Name, "myTool");
            testCase.verifyEqual(tools.Description, "Does stuff");
        end

        function constructor_multipleTools_createsArray(testCase)
            mockClient = makeMockClient({ ...
                struct("name", "tool1", "description", "First", "inputSchema", struct()), ...
                struct("name", "tool2", "description", "Second", "inputSchema", struct()), ...
                struct("name", "tool3", "description", "Third", "inputSchema", struct())});

            tools = aisdk.llms.tool.MCPTool(mockClient);
            testCase.verifyNumElements(tools, 3);
        end

        function constructor_setsInputSchemaDirectly(testCase)
            schema = struct("type", "object", ...
                "properties", struct("x", struct("type", "number")));
            mockClient = makeMockClient({ ...
                struct("name", "myTool", "description", "desc", "inputSchema", schema)});

            tools = aisdk.llms.tool.MCPTool(mockClient);
            testCase.verifyEqual(tools.InputArguments, schema);
        end

        function constructor_default_setsRequiresApprovalNever(testCase)
            mockClient = makeMockClient({ ...
                struct("name", "myTool", "description", "desc", "inputSchema", struct())});

            tools = aisdk.llms.tool.MCPTool(mockClient);
            testCase.verifyEqual(tools.RequiresApproval, aisdk.llms.tool.RequiresApproval.never);
        end

        function call_structArgs_passesAsNVPairs(testCase)
            captured = {};
            mockClient = makeMockClient({ ...
                struct("name", "myTool", "description", "desc", "inputSchema", struct())}, ...
                @(name, varargin) captureAndReturn(varargin));

            tools = aisdk.llms.tool.MCPTool(mockClient);
            tools.evaluate(struct("x", 1, "y", 2));

            testCase.verifyEqual(captured, {"x", 1, "y", 2});

            function result = captureAndReturn(args)
                captured = args;
                result = "done";
            end
        end

        function call_emptyStruct_invokesWithNoArgs(testCase)
            captured = {};
            mockClient = makeMockClient({ ...
                struct("name", "myTool", "description", "desc", "inputSchema", struct())}, ...
                @(name, varargin) captureAndReturn(varargin));

            tools = aisdk.llms.tool.MCPTool(mockClient);
            tools.evaluate(struct());

            testCase.verifyEmpty(captured);

            function result = captureAndReturn(args)
                captured = args;
                result = "done";
            end
        end

        function constructor_setsDisplayTitle_accordingToCorrectPrecedence(testCase, DisplayTitleCase)
            mockClient = makeMockClient({DisplayTitleCase.toolDef});
            tools = aisdk.llms.tool.MCPTool(mockClient);
            testCase.verifyEqual(tools.DisplayTitle, DisplayTitleCase.expected);
        end

        function constructor_setsAnnotationsFromAnnotations(testCase)
            annotations = struct("readOnlyHint", true, "destructiveHint", false);
            mockClient = makeMockClient({ ...
                struct("name", "myTool", "description", "desc", ...
                    "inputSchema", struct(), "annotations", annotations)});

            tools = aisdk.llms.tool.MCPTool(mockClient);
            testCase.verifyEqual(tools.Annotations, annotations);
        end

        function constructor_noAnnotations_leavesAnnotationsEmpty(testCase)
            mockClient = makeMockClient({ ...
                struct("name", "myTool", "description", "desc", "inputSchema", struct())});

            tools = aisdk.llms.tool.MCPTool(mockClient);
            testCase.verifyEqual(tools.Annotations, struct());
        end

        function constructor_extraArguments_errors(testCase)
            mockClient = makeMockClient({ ...
                struct("name", "myTool", "description", "desc", "inputSchema", struct())});

            testCase.verifyError( ...
                @() aisdk.llms.tool.MCPTool(mockClient, "extra"), ...
                "MATLAB:TooManyInputs");
        end
    end
end

function mockClient = makeMockClient(serverTools, callToolFcn)
    arguments
        serverTools(1,:) cell
        callToolFcn = @(name, varargin) "mock_result"
    end
    mockClient = struct("ServerTools", {serverTools}, "callTool", callToolFcn);
end
