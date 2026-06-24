function client = createClient(modelName, varargin)
    client = aisdk.llms.client.OpenAIClient(modelName, varargin{:});
end
