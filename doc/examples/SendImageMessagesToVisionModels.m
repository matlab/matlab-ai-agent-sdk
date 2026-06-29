%[text] # Send Image Messages to Vision Models
%[text] Examples of sending images to vision-capable models using `LLMMessage`.
%%
%[text] ## Setup
client = aisdk.LLMClient("openai", "gpt-4.1-mini");
%%
%[text] ## 1. Image from a file path
%[text] Send a local image file alongside a text prompt.
msgs = [aisdk.LLMTextMessage("Describe what you see in this image."), ...
        aisdk.LLMImageMessage("peppers.png")];

[resp, messages] = generate(client, msgs);
disp(resp)
%%
%[text] ## 2. Image from a MATLAB array
%[text] Generate or load an image in MATLAB and send it directly.
img = imread("peppers.png");
imshow(img)
title("Image sent to the model")
%%
msgs = [aisdk.LLMTextMessage("What colors dominate this image?"), ...
        aisdk.LLMImageMessage(img)];

resp = generate(client, msgs);
disp(resp)
%%
%[text] ## 3. Image from a URL
%[text] Pass a URL directly — the image is downloaded and decoded at construction.
msgs = [aisdk.LLMTextMessage("What is in this image?"), ...
        aisdk.LLMImageMessage("https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/GoldenGateBridge-001.jpg/1280px-GoldenGateBridge-001.jpg")];

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

msgs = [aisdk.LLMTextMessage("What mathematical function does this plot show?"), ...
        aisdk.LLMImageMessage(plotFile)];

resp = generate(client, msgs);
disp(resp)
delete(plotFile);
%%
%[text] ## 5. Interleaved text and images
%[text] Send multiple images with text labels. Order is preserved.
img1 = uint8(255 * ones(100, 100, 3));  % white square
img2 = uint8(zeros(100, 100, 3));       % black square

msgs = [aisdk.LLMTextMessage("Here is image A:"), ...
        aisdk.LLMImageMessage(img1), ...
        aisdk.LLMTextMessage("Here is image B:"), ...
        aisdk.LLMImageMessage(img2), ...
        aisdk.LLMTextMessage("What is the difference between A and B?")];

resp = generate(client, msgs);
disp(resp)
%%
%[text] ## 6. With OpenAI detail control
%[text] Use `Detail` to request high-resolution processing.
msgs = [aisdk.LLMTextMessage("Read any text visible in this image."), ...
        aisdk.LLMImageMessage("peppers.png", Detail="high")];

resp = generate(client, msgs);
disp(resp)
%%
%[text] ## 7. Inspect the stored image
%[text] `Image` holds the decoded MATLAB array — use it with any image function.
msgs = [aisdk.LLMTextMessage("Describe this image."), ...
        aisdk.LLMImageMessage("peppers.png")];

imgMsg = msgs(2);
disp("Size:  " + strjoin(string(size(imgMsg.Image)), "×"))
disp("Class: " + class(imgMsg.Image))
info = whos("imgMsg");
disp("Bytes: " + info.bytes)
imshow(imgMsg.Image)
title("Stored in msgs(2).Image")
%%
%[text] ## 8. Grayscale image
%[text] Grayscale and logical images are also accepted.
gray = im2gray(imread("peppers.png"));
msgs = [aisdk.LLMTextMessage("Describe this grayscale image."), ...
        aisdk.LLMImageMessage(gray)];

resp = generate(client, msgs);
disp(resp)
%%
%[text] ## 9. Display in a message array
%[text] Image messages display alongside text messages.
msgs = [aisdk.LLMTextMessage("Look at this"), ...
        aisdk.LLMImageMessage(uint8(randi(255, 50, 50, 3))), ...
        aisdk.LLMTextMessage("What do you see?")];
disp(msgs)
%[text] *Copyright 2026 The MathWorks, Inc.*

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright"}
%---
