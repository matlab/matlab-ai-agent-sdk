function client = LLMClient(api, modelName, varargin)
%LLMClient Create an LLM client
%
%   CLIENT = LLMClient(API, MODELNAME) creates a client object for the
%   specified API and MODELNAME. API is one of:
%     - "openai": aisdk.client.OpenAIClient,
%       using the OpenAI Chat Completions API
%     - "openai-responses": aisdk.client.OpenAIResponsesClient, using the
%       OpenAI Responses API
%     - "ollama": aisdk.client.OllamaClient
%
%   CLIENT = LLMClient(API, MODELNAME, Name=Value) creates a client object
%   with the specified name-value pairs passed to the underlying client class.
%
%   Environment variables are provider-specific:
%     - For the OpenAI APIs: OPENAI_API_KEY and OPENAI_API_ENDPOINT
%     - For "ollama": OLLAMA_API_KEY and OLLAMA_API_ENDPOINT
%
%   Example:
%       client = LLMClient("openai", "gpt-4o", Temperature=0.7)
%       client = LLMClient("openai-responses", "gpt-5.4-mini", ReasoningEffort="low")
%       client = LLMClient("ollama", "llama2", TopK=40)
%
%   See also: aisdk.client.OpenAIClient, aisdk.client.OpenAIResponsesClient,
%             aisdk.client.OllamaClient

% Copyright 2026 The MathWorks, Inc.

%#function aisdk.client.openai.createClient
%#function aisdk.client.openairesponses.createClient
%#function aisdk.client.ollama.createClient

arguments
    api       (1,1) string {mustBeProvider(api)}
    modelName (1,1) string
end

arguments (Repeating)
    varargin
end

client = feval("aisdk.client." + factoryNamespace(api) + ".createClient", modelName, varargin{:});
end

function mustBeProvider(api)
    if ~isempty(which("aisdk.client." + factoryNamespace(api) + ".createClient"))
        return
    end
    mustBeMember(api, ["openai", "openai-responses", "ollama"]);
end

function namespace = factoryNamespace(api)
    % Namespace names cannot contain hyphens.
    switch api
        case "openai-responses"
            namespace = "openairesponses";
        otherwise
            namespace = api;
    end
end
