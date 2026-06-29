classdef LLMToolResultMessage < aisdk.llms.message.LLMMessage
%LLMToolResultMessage The result of a tool call, returned to the model.
%
%   msg = aisdk.LLMToolResultMessage(RESULT) creates a tool result message.
%
%   msg = aisdk.LLMToolResultMessage(RESULT, ToolCallID=ID) creates a tool
%   result message with the specified tool call identifier.
%
%   msg = aisdk.LLMToolResultMessage(__, Name=N) specifies the name of the
%   tool that produced the result.
%
%   LLMToolResultMessage Properties:
%       Role                 - Always "tool".
%
%       Type                 - Always "text".
%
%       Result               - The result returned by the tool.
%
%       Name                 - Name of the tool that produced the result.
%
%       ToolCallID           - Identifier matching the original tool call.

%   Copyright 2026 The MathWorks, Inc.

    properties
        %RESULT   The result returned by the tool.
        Result(1,1) string

        %NAME   Name of the tool that produced the result.
        Name(1,1) string = ""

        %TOOLCALLID   Identifier matching the original tool call.
        ToolCallID {aisdk.llms.internal.mustBeValidToolCallID} = ""
    end

    methods
        function this = LLMToolResultMessage(result, nvp)
            arguments
                result(1,1) string
                nvp.ToolCallID {aisdk.llms.internal.mustBeValidToolCallID} = ""
                nvp.Name(1,1) string = ""
            end

            this@aisdk.llms.message.LLMMessage("tool", "text");
            this.Result = result;
            this.Name = nvp.Name;
            this.ToolCallID = nvp.ToolCallID;
        end
    end

    methods (Access = protected)
        function txt = contentPreview(this)
            txt = this.truncateForDisplay(this.Result);
        end
    end

end
