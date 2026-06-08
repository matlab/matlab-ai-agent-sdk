classdef tMCPTool < matlab.unittest.TestCase
% Tests for aisdk.llms.tool.MCPTool.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
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
    end
end

function mockClient = makeMockClient(serverTools, callToolFcn)
    arguments
        serverTools(1,:) cell
        callToolFcn = @(name, varargin) "mock_result"
    end
    mockClient = struct("ServerTools", {serverTools}, "callTool", callToolFcn);
end
