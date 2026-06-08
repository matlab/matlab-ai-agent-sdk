classdef(Abstract) ToolResponseMixin
%ToolResponseMixin Mixin for messages that carry a tool response.
%
%   ToolResponseMixin Properties:
%       Name                 - Name of the tool that produced the result.
%
%       ToolCallID           - Identifier matching the original tool call.

%   Copyright 2026 The MathWorks, Inc.

    properties
        %NAME   Name of the tool that produced the result.
        Name(1,1) string

        %TOOLCALLID   Identifier matching the original tool call.
        %   May be [] when the provider does not return one.
        ToolCallID {aisdk.llms.internal.mustBeValidToolCallID} = []
    end

end