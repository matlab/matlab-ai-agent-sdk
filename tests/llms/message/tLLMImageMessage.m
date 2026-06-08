classdef tLLMImageMessage < matlab.unittest.TestCase
% Tests for aisdk.llms.message.LLMImageMessage.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        function constructorFromArray(testCase)
            img = ones(10, 10, 3, "uint8");
            msg = aisdk.llms.message.LLMImageMessage(img, "user");
            testCase.verifyEqual(msg.Role, "user");
            testCase.verifyEqual(msg.Type, "image");
            testCase.verifyEqual(msg.Content, img);
        end

        function constructorFromFilePath(testCase)
            img = ones(10, 10, 3, "uint8");
            tempFile = [tempname, '.png'];
            imwrite(img, tempFile);
            testCase.addTeardown(@() delete(tempFile));

            msg = aisdk.llms.message.LLMImageMessage(tempFile, "user");
            testCase.verifyEqual(msg.Type, "image");
            testCase.verifyEqual(size(msg.Content), size(img));
            testCase.verifyClass(msg.Content, "uint8");
        end

        function constructorSetsDetail(testCase)
            img = ones(10, 10, 3, "uint8");
            msg = aisdk.llms.message.LLMImageMessage(img, "user", Detail="high");
            testCase.verifyEqual(msg.Detail, "high");
        end

        function defaultDetailIsAuto(testCase)
            img = ones(10, 10, 3, "uint8");
            msg = aisdk.llms.message.LLMImageMessage(img, "user");
            testCase.verifyEqual(msg.Detail, "auto");
        end

        function acceptsGrayscale(testCase)
            img = ones(10, 10, 1, "uint8");
            msg = aisdk.llms.message.LLMImageMessage(img, "user");
            testCase.verifyEqual(size(msg.Content), [10 10]);
        end

        function acceptsLogical(testCase)
            img = true(10);
            msg = aisdk.llms.message.LLMImageMessage(img, "user");
            testCase.verifyClass(msg.Content, "logical");
        end

        function heterogeneousArrayWithText(testCase)
            textMsg = aisdk.llms.message.LLMTextMessage("hello", "user");
            imgMsg = aisdk.llms.message.LLMImageMessage(uint8(randi(255, 4, 4, 3)), "user");
            msgs = [textMsg, imgMsg];
            testCase.verifyEqual(numel(msgs), 2);
            testCase.verifyEqual(msgs(1).Type, "text");
            testCase.verifyEqual(msgs(2).Type, "image");
        end

        function contentPreviewInDisplay(testCase)
            img = ones(10, 15, 3, "uint8");
            msg = aisdk.llms.message.LLMImageMessage(img, "user");
            output = formattedDisplayText(msg);
            testCase.verifySubstring(output, "10x15x3");
        end

        function constructorRejectsEmptyArray_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.message.LLMImageMessage(uint8([]), "user"), ...
                "llms:message:InvalidImageContent");
        end

        function constructorRejectsInvalidDimensions_throwsError(testCase)
            img = uint8(ones(255, 4, 4, 2));
            testCase.verifyError( ...
                @() aisdk.llms.message.LLMImageMessage(img, "user"), ...
                "llms:message:InvalidImageContent");
        end

        function constructorRejectsNonImageSource_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.message.LLMImageMessage({1,2,3}, "user"), ...
                "llms:message:InvalidImageSource");
        end

        function constructorAcceptsFourChannel_storesContent(testCase)
            img = ones(10, 10, 3, "uint8");
            msg = aisdk.llms.message.LLMImageMessage(img, "user");
            testCase.verifyEqual(msg.Content, img);
        end

        function displayShowsDetail_whenNonAuto(testCase)
            img = ones(10, 10, 3, "uint8");
            msg = aisdk.llms.message.LLMImageMessage(img, "user", Detail="high");
            output = formattedDisplayText(msg);
            testCase.verifySubstring(output, "high");
        end
    end

end
