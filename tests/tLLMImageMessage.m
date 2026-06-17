classdef tLLMImageMessage < matlab.unittest.TestCase
% Tests for aisdk.LLMImageMessage.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        function constructorFromArray(testCase)
            img = ones(10, 10, 3, "uint8");
            msg = aisdk.LLMImageMessage(img);
            testCase.verifyEqual(msg.Role, "user");
            testCase.verifyEqual(msg.Type, "image");
            testCase.verifyEqual(msg.Content, img);
        end

        function constructorFromFilePath(testCase)
            img = ones(10, 10, 3, "uint8");
            tempFile = [tempname, '.png'];
            imwrite(img, tempFile);
            testCase.addTeardown(@() delete(tempFile));

            msg = aisdk.LLMImageMessage(tempFile);
            testCase.verifyEqual(msg.Type, "image");
            testCase.verifyEqual(size(msg.Content), size(img));
            testCase.verifyClass(msg.Content, "uint8");
        end

        function constructorSetsDetail(testCase)
            img = ones(10, 10, 3, "uint8");
            msg = aisdk.LLMImageMessage(img, Detail="high");
            testCase.verifyEqual(msg.Detail, "high");
        end

        function defaultDetailIsAuto(testCase)
            img = ones(10, 10, 3, "uint8");
            msg = aisdk.LLMImageMessage(img);
            testCase.verifyEqual(msg.Detail, "auto");
        end

        function acceptsGrayscale(testCase)
            img = ones(10, 10, 1, "uint8");
            msg = aisdk.LLMImageMessage(img);
            testCase.verifyEqual(size(msg.Content), [10 10]);
        end

        function acceptsLogical(testCase)
            img = true(10);
            msg = aisdk.LLMImageMessage(img);
            testCase.verifyClass(msg.Content, "logical");
        end

        function heterogeneousArrayWithText(testCase)
            textMsg = aisdk.LLMTextMessage("hello");
            imgMsg = aisdk.LLMImageMessage(uint8(randi(255, 4, 4, 3)));
            msgs = [textMsg, imgMsg];
            testCase.verifyEqual(numel(msgs), 2);
            testCase.verifyEqual(msgs(1).Type, "text");
            testCase.verifyEqual(msgs(2).Type, "image");
        end

        function contentPreviewInDisplay(testCase)
            img = ones(10, 15, 3, "uint8");
            msg = aisdk.LLMImageMessage(img);
            output = formattedDisplayText(msg);
            testCase.verifySubstring(output, "10x15x3");
        end

        function constructorRejectsEmptyArray_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMImageMessage(uint8([])), ...
                "llms:message:InvalidImageContent");
        end

        function constructorRejectsInvalidDimensions_throwsError(testCase)
            img = uint8(ones(255, 4, 4, 2));
            testCase.verifyError( ...
                @() aisdk.LLMImageMessage(img), ...
                "llms:message:InvalidImageContent");
        end

        function constructorRejectsNonImageSource_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMImageMessage({1,2,3}), ...
                "llms:message:InvalidImageSource");
        end

        function constructorAcceptsFourChannel_storesContent(testCase)
            img = ones(10, 10, 4, "uint8");
            msg = aisdk.LLMImageMessage(img);
            testCase.verifyEqual(msg.Content, img);
        end

        function displayShowsDetail_whenNonAuto(testCase)
            img = ones(10, 10, 3, "uint8");
            msg = aisdk.LLMImageMessage(img, Detail="high");
            output = formattedDisplayText(msg);
            testCase.verifySubstring(output, "high");
        end

        function constructorFromNonImageFile_throwsError(testCase)
            fixture = fullfile(fileparts(mfilename("fullpath")), ...
                "resources", "fixtures", "not_an_image.html");
            testCase.verifyError( ...
                @() aisdk.LLMImageMessage(fixture), ...
                "llms:message:NotAnImage");
        end

        function constructorFromNonexistentFile_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMImageMessage("C:\nonexistent\fake.png"), ...
                "MATLAB:imagesci:imread:fileDoesNotExist");
        end

        function constructorFromURL_downloadFails_noWarning(testCase)
            failingDownload = @(~,~) error("test:downloadFailed", "simulated failure");
            testCase.verifyWarningFree( ...
                @() testCase.verifyError( ...
                    @() aisdk.LLMImageMessage("https://example.com/not_real.jpg", ...
                        DownloadFcn=failingDownload), ...
                    "llms:message:NotAnImage"));
        end
    end

end
