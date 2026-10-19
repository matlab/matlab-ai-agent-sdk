%[text] # Create Simple Chatbot
%[text] This example shows how to create a simple, interactive Chatbot in the MATLAB® Command Window.
%[text] When you run this example, an interactive AI chat starts in the MATLAB Command Window. To leave the chat, type "end" or press **Ctrl+C**.
%[text] Running this example requires an OpenAI® API key, but you can change the code to use a different API instead by changing the part of the code that calls the [`aisdk.LLMClient`](file:../../functions/aisdk.LLMClient.md) function.
%[text] ## Connect to OpenAI
%[text] Using the OpenAI Chat Completions API requires an OpenAI API key. For information on how to obtain one, as well as pricing, terms and conditions of use, and available models, see the [OpenAI documentation](https://platform.openai.com/docs/overview).
%[text] Set your key as an environment variable in a `.env` file:
%[text] ```matlabCodeExample
%[text] OPENAI_API_KEY=<your key>
%[text] ```
%[text] Then add the file to the path and load it in MATLAB.
loadenv(".env")
%[text] Specify the API and model name. Create the LLM client by using the `aisdk.LLMClient` function.
api = "openai";
model = "gpt-4.1-mini";
client = aisdk.LLMClient(api,model);
%[text] To manage the message history in the chat, create an AI agent by using the [`aisdk.AIAgent`](file:../../functions/aisdk.AIAgent.md) function.
session = aisdk.AIAgent(client);
%%
%[text] ## Start Chat
%[text] Define a stop word. When you type the stop word in the chat, the chat closes. You can also close the chat by pressing **Ctrl+C**.
stopWord = "end";
%[text] Define the chat loop.
while true
    prompt = input("User: ", "s");
    prompt = string(prompt);
    disp("User: " + prompt)
    if prompt == stopWord
        disp("AI: Closing the chat. Have a great day!")
        break;
    end
    text = run(session, prompt);    
    disp("AI: " + text)
end
%[text] *Copyright 2026 The MathWorks, Inc.*

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":25.8}
%---
