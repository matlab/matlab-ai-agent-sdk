function response = sendRequestWrapper(varargin)
% This function is undocumented and will change in a future release

%   Copyright 2026 The MathWorks, Inc.

% A wrapper around sendRequest to have a test seam
response = aisdk.client.internal.sendRequest(varargin{:});
