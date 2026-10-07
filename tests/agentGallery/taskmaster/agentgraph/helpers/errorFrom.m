function err = errorFrom(fcn)
%ERRORFROM  Run FCN and return the MException it threw, or an empty one.
%   verifyError does not hand back the MException, and a test asserting on the
%   message text needs it. Qualifying is left to the caller, so this cannot fail
%   a test: assert the result is non-empty before reading it.

% Copyright 2026 The MathWorks, Inc.

    err = MException.empty;  % MATLAB requires err assigned before "catch err"
    try
        fcn();
    catch err  %#ok<CTCH>
    end
end
