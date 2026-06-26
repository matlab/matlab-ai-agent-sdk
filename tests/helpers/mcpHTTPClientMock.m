classdef mcpHTTPClientMock < mcpHTTPClient
%mcpHTTPClientMock Concrete mock of mcpHTTPClient for testing.

%   Copyright 2026 The MathWorks, Inc.

    properties
        ServerTools
    end

    properties (Access = private)
        CallToolFcn
    end

    methods
        function this = mcpHTTPClientMock(serverTools, callToolFcn)
            arguments
                serverTools(1,:) cell
                callToolFcn = @(name, varargin) "mock_result"
            end
            this.ServerTools = serverTools;
            this.CallToolFcn = callToolFcn;
        end

        function result = callTool(this, name, varargin)
            result = this.CallToolFcn(name, varargin{:});
        end
    end
end
