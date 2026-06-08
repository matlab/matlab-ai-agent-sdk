classdef LLMToolResultMessage < aisdk.llms.message.LLMTextMessage & aisdk.llms.message.ToolResponseMixin
%LLMToolResultMessage The result of a tool call, returned to the model.
%
%   LLMToolResultMessage Properties (inherited):
%       Role                 - Always "tool".
%
%       Type                 - Always "text".
%
%       Content              - The result returned by the tool.
%
%   LLMToolResultMessage Properties:
%       Name                 - Name of the tool that produced the result.
%
%       ToolCallID           - Identifier matching the original tool call.

%   Copyright 2026 The MathWorks, Inc.

    methods
        function this = LLMToolResultMessage(content, name, toolCallID)
            arguments
                content(1,1) string
                name(1,1) string
                toolCallID {aisdk.llms.internal.mustBeScalarStringOrEmpty}
            end

            this@aisdk.llms.message.LLMTextMessage(content, "tool");
            this.Name = name;
            if ischar(toolCallID)
                toolCallID = string(toolCallID);
            end
            this.ToolCallID = toolCallID;
        end
    end

end