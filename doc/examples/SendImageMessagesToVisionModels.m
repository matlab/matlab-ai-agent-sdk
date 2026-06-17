%[text] # Send Image Messages to Vision Models
%[text] Examples of sending images to vision-capable models using `LLMMessage`.
%%
%[text] ## Setup
client = aisdk.LLMClient("openai", "gpt-4.1-mini");
%%
%[text] ## 1. Image from a file path
%[text] Send a local image file alongside a text prompt.
msgs = [aisdk.LLMMessage("Describe what you see in this image."), ...
        aisdk.LLMMessage("peppers.png", Type="image")];

[resp, messages] = generate(client, msgs);
disp(resp)
%%
%[text] ## 2. Image from a MATLAB array
%[text] Generate or load an image in MATLAB and send it directly.
img = imread("peppers.png");
imshow(img)
title("Image sent to the model")
%%
msgs = [aisdk.LLMMessage("What colors dominate this image?"), ...
        aisdk.LLMMessage(img)];

resp = generate(client, msgs);
disp(resp)
%%
%[text] ## 3. Image from a URL
%[text] Pass a URL directly — the image is downloaded and decoded at construction.
msgs = [aisdk.LLMMessage("What is in this image?"), ...
        aisdk.LLMMessage("https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/GoldenGateBridge-001.jpg/1280px-GoldenGateBridge-001.jpg", Type="image")];

resp = generate(client, msgs);
disp(resp)
%%
%[text] ## 4. MATLAB-generated plot
%[text] Create a plot, save it, then ask the model to interpret it.
x = linspace(0, 2*pi, 100);
y = sin(x);
fig = figure;
plot(x, y, "LineWidth", 2)
title("sin(x)")
xlabel("x")
ylabel("y")

plotFile = [tempname, '.png'];
exportgraphics(fig, plotFile);
close(fig)

msgs = [aisdk.LLMMessage("What mathematical function does this plot show?"), ...
        aisdk.LLMMessage(plotFile, Type="image")];

resp = generate(client, msgs);
disp(resp)
delete(plotFile);
%%
%[text] ## 5. Interleaved text and images
%[text] Send multiple images with text labels. Order is preserved.
img1 = uint8(255 * ones(100, 100, 3));  % white square
img2 = uint8(zeros(100, 100, 3));       % black square

msgs = [aisdk.LLMMessage("Here is image A:"), ...
        aisdk.LLMMessage(img1), ...
        aisdk.LLMMessage("Here is image B:"), ...
        aisdk.LLMMessage(img2), ...
        aisdk.LLMMessage("What is the difference between A and B?")];

resp = generate(client, msgs);
disp(resp)
%%
%[text] ## 6. With OpenAI detail control
%[text] Use `Detail` to request high-resolution processing.
msgs = [aisdk.LLMMessage("Read any text visible in this image."), ...
        aisdk.LLMMessage("peppers.png", Type="image", Detail="high")];

resp = generate(client, msgs);
disp(resp)
%%
%[text] ## 7. Inspect the stored image
%[text] `Content` holds the decoded MATLAB array — use it with any image function.
msgs = [aisdk.LLMMessage("Describe this image."), ...
        aisdk.LLMMessage("peppers.png", Type="image")];

imgMsg = msgs(2);
disp("Size:  " + strjoin(string(size(imgMsg.Content)), "x"))
disp("Class: " + class(imgMsg.Content))
info = whos("imgMsg");
disp("Bytes: " + info.bytes)
imshow(imgMsg.Content)
title("Stored in msgs(2).Content")
%%
%[text] ## 8. Grayscale image
%[text] Grayscale and logical images are also accepted.
gray = im2gray(imread("peppers.png"));
msgs = [aisdk.LLMMessage("Describe this grayscale image."), ...
        aisdk.LLMMessage(gray)];

resp = generate(client, msgs);
disp(resp)
%%
%[text] ## 9. Display in a message array
%[text] Image messages display alongside text messages.
msgs = [aisdk.LLMMessage("Look at this"), ...
        aisdk.LLMMessage(uint8(randi(255, 50, 50, 3))), ...
        aisdk.LLMMessage("What do you see?")];
disp(msgs)
%[text] *Copyright 2026 The MathWorks, Inc.*

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright"}
%---
