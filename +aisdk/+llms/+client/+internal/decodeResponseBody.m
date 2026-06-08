function data = decodeResponseBody(data)
%decodeResponseBody Decode raw response body to a MATLAB struct.
%   Handles three cases:
%   1. Already decoded (struct/cell) — pass through.
%   2. Raw bytes (numeric) — interpret as UTF-8, convert to string.
%   3. String — attempt JSON decode; if that fails, try NDJSON (newline-delimited).

%   Copyright 2026 The MathWorks, Inc.

if isnumeric(data)
    data = native2unicode(data(:).', "UTF-8");
end

if ischar(data) || isstring(data)
    try
        data = jsondecode(data);
        return
    catch
        % JSON decode failed — fall through to NDJSON attempt
    end
    json = "[" + replace(strtrim(data), newline, ',') + "]";
    try
        data = jsondecode(json);
    catch
        % NDJSON decode also failed — return data as-is
    end
end
end
