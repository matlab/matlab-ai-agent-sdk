function client = createClient(modelName, varargin)
%   Copyright 2026 The MathWorks, Inc.
    client = aisdk.client.OpenAIClient(modelName, varargin{:});
end
