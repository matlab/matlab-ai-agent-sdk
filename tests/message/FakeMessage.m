classdef FakeMessage < aisdk.message.LLMMessage
% Test helper: message with a non-standard role.

%   Copyright 2026 The MathWorks, Inc.

    methods
        function this = FakeMessage(role)
            this@aisdk.message.LLMMessage(role);
        end
    end

    methods (Access = protected)
        function txt = contentPreview(~)
            txt = "";
        end
    end

end
