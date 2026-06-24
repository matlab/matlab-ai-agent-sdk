function client = LLMClient(api, modelName, varargin)
%LLMClient Create an LLM client for chat completions.
%
%   CLIENT = LLMClient(API, MODELNAME) creates a client object for the
%   specified API ("openai" or "ollama") and MODELNAME.
%
%   CLIENT = LLMClient(API, MODELNAME, Name=Value) creates a client object
%   with the specified name-value pairs passed to the underlying client class.
%
%   Environment variables are provider-specific:
%     - For "openai": OPENAI_API_KEY and OPENAI_API_ENDPOINT
%     - For "ollama": OLLAMA_API_KEY and OLLAMA_API_ENDPOINT
%
%   Example:
%       client = LLMClient("openai", "gpt-4o", Temperature=0.7)
%       client = LLMClient("ollama", "llama2", TopK=40)
%
%   See also: aisdk.llms.client.OpenAIClient, aisdk.llms.client.OllamaClient

% Copyright 2026 The MathWorks, Inc.

%#function aisdk.llms.client.openai.createClient
%#function aisdk.llms.client.ollama.createClient

arguments
    api       (1,1) string {mustBeProvider(api)}
    modelName (1,1) string
end

arguments (Repeating)
    varargin
end

client = feval("aisdk.llms.client." + api + ".createClient", modelName, varargin{:});
end

function mustBeProvider(api)
    if ~isempty(which("aisdk.llms.client." + api + ".createClient"))
        return
    end
    mustBeMember(api, ["openai", "ollama"]);
end
