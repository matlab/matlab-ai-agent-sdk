%[text] # Create Simple ChatBot
%[text] When you run this example, an interactive AI chat starts in the MATLAB® Command Window. To leave the chat, type "end" or press **Ctrl+C**.
%[text] This example includes three steps:
%[text] - Define model parameters and a stop word.
%[text] - Create an LLM client object and an agent using this client for managing the history of the chat loop.
%[text] - Set up the chat loop. \
%[text] To run this example, you need a valid API key from a paid OpenAI™ API account.
% loadenv(".env")
%%
%[text] ## Create LLM Client and Agent
api = "openai";
modelName = "gpt-4.1-mini";
client = aisdk.LLMClient(api, modelName);
%[text] Create an instance of `AIAgent` to manage the message history in the chat. Also define the bot behaviour through a system prompt.
sysPrompt = "You are a helpful assistant. You reply in a very concise way, keeping answers limited to short sentences.";
session = aisdk.AIAgent(client, sysPrompt);
%%
%[text] ## Chat loop
%[text] Start the chat and keep it going until it sees the word in `stopWord` (or until you hit **Ctrl+C**).
stopWord = "end";
while true %[output:group:7ff8d64f]
    query = input("User: ", "s");
    query = string(query);
    disp("User: " + query) %[output:41401c71] %[output:9e5e5f67] %[output:8d24b85b]
%[text] If you input the stop word, display a farewell message and exit the loop.
    if query == stopWord
        disp("AI: Closing the chat. Have a great day!") %[output:5869b4a4]
        break;
    end
    text = run(session, query);    
    disp("AI: " + text) %[output:32ab2fe7] %[output:76bc4f07]
end %[output:group:7ff8d64f]
%[text] *Copyright 2026 The MathWorks, Inc.*

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":25.8}
%---
%[output:41401c71]
%   data: {"dataType":"text","outputData":{"text":"User: What's Bohemian Rhapsody about?\n","truncated":false}}
%---
%[output:32ab2fe7]
%   data: {"dataType":"text","outputData":{"text":"AI: \"Bohemian Rhapsody\" is about a young man who confesses to a crime, experiences guilt, and faces existential dilemmas.\n","truncated":false}}
%---
%[output:9e5e5f67]
%   data: {"dataType":"text","outputData":{"text":"User: Why the guilt?\n","truncated":false}}
%---
%[output:76bc4f07]
%   data: {"dataType":"text","outputData":{"text":"AI: The guilt stems from admitting he has killed someone.\n","truncated":false}}
%---
%[output:8d24b85b]
%   data: {"dataType":"text","outputData":{"text":"User: end\n","truncated":false}}
%---
%[output:5869b4a4]
%   data: {"dataType":"text","outputData":{"text":"AI: Closing the chat. Have a great day!\n","truncated":false}}
%---
