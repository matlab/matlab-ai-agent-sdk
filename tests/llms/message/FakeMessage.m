classdef FakeMessage < aisdk.llms.message.LLMMessage
% Test helper: message with a non-standard role and type.

%   Copyright 2026 The MathWorks, Inc.

    methods
        function this = FakeMessage(role, type)
            this@aisdk.llms.message.LLMMessage(role, type);
        end
    end

    methods (Access = protected)
        function txt = contentPreview(~)
            txt = "";
        end
    end

end
