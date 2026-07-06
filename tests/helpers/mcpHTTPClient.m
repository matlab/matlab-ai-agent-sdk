classdef (Abstract) mcpHTTPClient < handle
%mcpHTTPClient Minimal stub for mocking the mcpHTTPClient interface.

%   Copyright 2026 The MathWorks, Inc.

    properties
        ServerTools
    end

    methods (Abstract)
        result = callTool(obj, name, varargin)
    end
end
