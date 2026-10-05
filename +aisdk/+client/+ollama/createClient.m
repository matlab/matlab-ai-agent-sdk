function client = createClient(modelName, varargin)
%   Copyright 2026 The MathWorks, Inc.
    client = aisdk.client.OllamaClient(modelName, varargin{:});
end
