classdef LLMToolCallMessage < aisdk.llms.message.LLMMessage
%LLMToolCallMessage A request from the AI model to call a tool.
%
%   msg = aisdk.LLMToolCallMessage(NAME) creates a tool call message.
%
%   msg = aisdk.LLMToolCallMessage(NAME, ARGUMENTS) creates a tool call
%   with the specified arguments struct.
%
%   msg = aisdk.LLMToolCallMessage(NAME, ARGUMENTS, ToolCallID=ID) creates a
%   tool call with a provider-assigned identifier.
%
%   LLMToolCallMessage Properties:
%       Role                 - Always "assistant".
%
%       Type                 - Always "tool-call".
%
%       Content              - Not used for tool call messages.
%
%       Name                 - Name of the tool the model wants to call.
%
%       ToolCallID           - Unique identifier for this tool call.
%
%       Arguments            - Arguments the model is passing to the tool.

%   Copyright 2026 The MathWorks, Inc.

    properties
        %NAME   Name of the tool the model wants to call.
        Name(1,1) string

        %TOOLCALLID   Unique identifier for this tool call.
        %   May be [] when the provider does not return one (e.g. Ollama).
        ToolCallID {aisdk.llms.internal.mustBeValidToolCallID} = []

        %ARGUMENTS   Arguments the model is passing to the tool.
        Arguments(1,1) struct
    end

    methods (Access = protected)
        function groups = getPropertyGroups(obj)
            props = struct( ...
                "Role", obj.Role, ...
                "Type", obj.Type, ...
                "Content", obj.Content, ...
                "Name", obj.Name, ...
                "Arguments", iFormatArgs(obj.Arguments), ...
                "ToolCallID", obj.ToolCallID);
            groups = matlab.mixin.util.PropertyGroup(props);
        end
    end

    methods
        function this = LLMToolCallMessage(name, arguments, nvp)
            arguments
                name(1,1) string {aisdk.llms.internal.mustBeNonzeroLengthTextScalar}
                arguments(1,1) struct = struct()
                nvp.ToolCallID {aisdk.llms.internal.mustBeValidToolCallID} = []
            end

            this@aisdk.llms.message.LLMMessage("assistant", "tool-call");
            this.Name = name;
            this.ToolCallID = nvp.ToolCallID;
            this.Arguments = arguments;
        end
    end

end

function out = iFormatArgs(args)
    if isempty(fieldnames(args))
        out = [];
    else
        out = jsonencode(args);
    end
end
