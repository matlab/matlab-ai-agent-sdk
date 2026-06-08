function mustBeVerbosity(value)
%mustBeVerbosity Validate Verbosity value.

% Copyright 2026 The MathWorks, Inc.

mustBeMember(value, aisdk.llms.client.internal.verbosityValues);
end
