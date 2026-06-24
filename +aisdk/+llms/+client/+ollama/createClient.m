function client = createClient(modelName, varargin)
    client = aisdk.llms.client.OllamaClient(modelName, varargin{:});
end
