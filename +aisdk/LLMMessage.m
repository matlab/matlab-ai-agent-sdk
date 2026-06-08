function msg = LLMMessage(content, nvp)
%LLMMessage Create an LLM message.
%
%   MSG = LLMMessage(TEXT) creates a user text message.
%
%   MSG = LLMMessage(IMGARRAY) creates a user image message from a MATLAB
%   image array (numeric or logical).
%
%   MSG = LLMMessage(SOURCE, Type="image") creates a user image message
%   from a file path or URL.
%
%   MSG = LLMMessage(SOURCE, Type="image", Detail=D) sets the image
%   resolution detail level ("auto", "low", "high", or "original").
%
%   MSG = LLMMessage(TEXT, Role=R) creates a text message with the
%   specified role ("user", "assistant", or "tool").
%
%   MSG = LLMMessage(TEXT, Type=T, Role=R) creates a message with the
%   specified type and role.
%
%   MSG = LLMMessage(CONTENT, Type="tool-call", Name=N, ToolCallID=ID)
%   creates a tool call message.
%
%   MSG = LLMMessage(CONTENT, Type="tool-result", Name=N, ToolCallID=ID)
%   creates a tool result message.
%
%   Example:
%       msg = LLMMessage("Hello!")
%       msg = LLMMessage(imread("peppers.png"))
%       msg = LLMMessage("photo.jpg", Type="image")
%       msg = LLMMessage("photo.jpg", Type="image", Detail="low")
%       msg = LLMMessage("I am an assistant message!", Role="assistant")
%
%   See also: aisdk.llms.message.LLMTextMessage, aisdk.llms.message.LLMImageMessage

% Copyright 2026 The MathWorks, Inc.

arguments
    content
    nvp.Type(1,1) string {mustBeMember(nvp.Type, ["auto","text","image","tool-call","tool-result"])} = "auto"
    nvp.Role(1,1) string {mustBeMember(nvp.Role, ["user","assistant","tool"])} = "user"
    nvp.Detail(1,1) string {mustBeMember(nvp.Detail, ["auto","low","high","original"])} = "auto"
    nvp.Name(1,1) string = missing
    nvp.ToolCallID = missing
    nvp.Arguments(1,1) struct = struct()
end

% Infer type from content when Type="auto".
if nvp.Type == "auto"
    if (isnumeric(content) || islogical(content)) && ~isscalar(content)
        type = "image";
    else
        type = "text";
    end
else
    type = nvp.Type;
end

switch type
    case "text"
        msg = aisdk.llms.message.LLMTextMessage(content, nvp.Role);
    case "image"
        msg = aisdk.llms.message.LLMImageMessage(content, nvp.Role, Detail=nvp.Detail);
    case "tool-call"
        msg = aisdk.llms.message.LLMToolCallMessage(nvp.Name, nvp.Arguments, nvp.ToolCallID);
    case "tool-result"
        msg = aisdk.llms.message.LLMToolResultMessage(content, nvp.Name, nvp.ToolCallID);
end
end
