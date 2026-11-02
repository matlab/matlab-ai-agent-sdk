classdef tEncodeImageToPNG < matlab.unittest.TestCase
% Tests for aisdk.internal.encodeImageToPNG.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        SupportedNumericImageClass = {'single', 'double', 'uint8', 'uint16'};
        SupportedImageSize = struct( ...
            "grayscale", [2 3], ...
            "truecolorRGB", [2 3 3]);
    end

    methods (Test, TestTags = {'Unit'})
        function returnsUint8Bytes(testCase)
            img = uint8(randi(255, 8, 8, 3));
            bytes = aisdk.internal.encodeImageToPNG(img);
            testCase.verifyClass(bytes, 'uint8');
            testCase.verifyGreaterThan(numel(bytes), 0);
        end

        function encodesSupportedNumericClassesAndShapes( ...
                testCase, SupportedNumericImageClass, SupportedImageSize)
            img = cast(zeros(SupportedImageSize), SupportedNumericImageClass);

            bytes = aisdk.internal.encodeImageToPNG(img);

            verifyPNGBytes(testCase, bytes);
        end

        function encodesLogicalGrayscale(testCase)
            img = false(2, 3);

            bytes = aisdk.internal.encodeImageToPNG(img);

            verifyPNGBytes(testCase, bytes);
        end

        function roundtripPreservesImage(testCase)
            img = uint8(randi(255, 10, 10, 3));
            bytes = aisdk.internal.encodeImageToPNG(img);

            tempFile = [tempname, '.png'];
            testCase.addTeardown(@() delete(tempFile));
            fid = fopen(tempFile, 'w');
            fwrite(fid, bytes, 'uint8');
            fclose(fid);

            recovered = imread(tempFile);
            testCase.verifyEqual(recovered, img);
        end
    end

end

function verifyPNGBytes(testCase, bytes)
    % Fixed eight-byte PNG file signature present at the start of every PNG.
    pngFileSignature = uint8([137; 80; 78; 71; 13; 10; 26; 10]);
    testCase.verifyClass(bytes, 'uint8');
    testCase.verifyEqual(bytes(1:8), pngFileSignature);
end
