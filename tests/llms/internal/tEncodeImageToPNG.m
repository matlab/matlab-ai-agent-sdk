classdef tEncodeImageToPNG < matlab.unittest.TestCase
% Tests for aisdk.llms.internal.encodeImageToPNG.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        function returnsUint8Bytes(testCase)
            img = uint8(randi(255, 8, 8, 3));
            bytes = aisdk.llms.internal.encodeImageToPNG(img);
            testCase.verifyClass(bytes, 'uint8');
            testCase.verifyGreaterThan(numel(bytes), 0);
        end

        function roundtripPreservesImage(testCase)
            img = uint8(randi(255, 10, 10, 3));
            bytes = aisdk.llms.internal.encodeImageToPNG(img);

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
