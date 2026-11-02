classdef tLLMImageMessage < matlab.unittest.TestCase
% Tests for aisdk.LLMImageMessage.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        InvalidImageContent = struct( ...
            "emptyArray", struct("Image", uint8([]), "ErrorID", "MATLAB:expectedNonempty"), ...
            "sparseArray", struct("Image", sparse(10, 10), "ErrorID", "MATLAB:expectedNonsparse"), ...
            "signedInteger", struct("Image", int16(ones(10, 10, 3)), "ErrorID", "MATLAB:invalidType"), ...
            "uint64", struct("Image", uint64(ones(10, 10, 3)), "ErrorID", "MATLAB:invalidType"), ...
            "invalidDimensions", struct("Image", uint8(ones(255, 4, 4, 2)), "ErrorID", "aisdk:message:InvalidImageDimensions"), ...
            "fourChannelShape", struct("Image", ones(10, 10, 4, "uint8"), "ErrorID", "aisdk:message:InvalidImageDimensions"), ...
            "logicalRGB", struct("Image", true(10, 10, 3), "ErrorID", "aisdk:message:InvalidLogicalImageDimensions"));
    end

    methods (Test, TestTags = {'Unit'})
        function constructorFromArray(testCase)
            img = ones(10, 10, 3, "uint8");
            msg = aisdk.LLMImageMessage(img);
            testCase.verifyEqual(msg.Role, "user");
            testCase.verifyEqual(msg.Image, img);
        end

        function constructorFromFilePath(testCase)
            img = ones(10, 10, 3, "uint8");
            tempFile = [tempname, '.png'];
            imwrite(img, tempFile);
            testCase.addTeardown(@() delete(tempFile));

            msg = aisdk.LLMImageMessage(tempFile);
            testCase.verifyEqual(size(msg.Image), size(img));
            testCase.verifyClass(msg.Image, "uint8");
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
            testCase.verifyEqual(size(msg.Image), [10 10]);
        end

        function acceptsLogical(testCase)
            img = true(10);
            msg = aisdk.LLMImageMessage(img);
            testCase.verifyClass(msg.Image, "logical");
        end

        function heterogeneousArrayWithText(testCase)
            textMsg = aisdk.LLMTextMessage("hello");
            imgMsg = aisdk.LLMImageMessage(uint8(randi(255, 4, 4, 3)));
            msgs = [textMsg, imgMsg];
            testCase.verifyEqual(numel(msgs), 2);
            testCase.verifyClass(msgs(1), "aisdk.LLMTextMessage");
            testCase.verifyClass(msgs(2), "aisdk.LLMImageMessage");
        end

        function contentPreviewInDisplay(testCase)
            img = ones(10, 15, 3, "uint8");
            msg = aisdk.LLMImageMessage(img);
            output = formattedDisplayText(msg);
            testCase.verifySubstring(output, "10×15×3");
        end

        function constructor_withInvalidImageContent_throwsError(testCase, InvalidImageContent)
            testCase.verifyError( ...
                @() aisdk.LLMImageMessage(InvalidImageContent.Image), ...
                InvalidImageContent.ErrorID);
        end

        function constructor_withNonImageSource_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.LLMImageMessage({1,2,3}), ...
                "aisdk:message:InvalidImageSource");
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
                "aisdk:message:NotAnImage");
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
                    "aisdk:message:NotAnImage"));
        end
    end

end
