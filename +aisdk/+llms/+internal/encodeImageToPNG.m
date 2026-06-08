function bytes = encodeImageToPNG(imgArray)
%ENCODEIMAGETOPNG Encode a MATLAB image array to PNG bytes.
%   BYTES = aisdk.llms.internal.encodeImageToPNG(IMGARRAY) writes IMGARRAY to a
%   temporary PNG file and returns the raw bytes as a uint8 column vector.

%   Copyright 2026 The MathWorks, Inc.

    tempFile = [tempname, '.png'];
    imwrite(imgArray, tempFile, 'png');
    fid = fopen(tempFile, 'r');
    closeAndDelete = onCleanup(@() iCloseAndDelete(fid, tempFile));
    bytes = fread(fid, '*uint8');
end

function iCloseAndDelete(fid, filePath)
    fclose(fid);
    if isfile(filePath)
        delete(filePath);
    end
end
