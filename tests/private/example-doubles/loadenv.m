function loadenv(~)
% Test double that shadows the MATLAB built-in and does nothing.
%
% The examples load their API keys from a ".env" file that users create
% themselves, so it is not in the repository and loadenv(".env") would
% error with MATLAB:io:common:file:FileNotFound. The tests instead take
% credentials from the environment of the MATLAB session, which is also
% what a recording run needs, so the no-op suits both capture and replay.

%   Copyright 2026 The MathWorks, Inc.

end
