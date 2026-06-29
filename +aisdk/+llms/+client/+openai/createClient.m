function client = createClient(modelName, varargin)
%   Copyright 2026 The MathWorks, Inc.
    client = aisdk.llms.client.OpenAIClient(modelName, varargin{:});
end
