function [response, streamedText] = sendRequestWrapper(varargin)
% This function is undocumented and will change in a future release

%   Copyright 2026 The MathWorks, Inc.

% A wrapper around sendRequest to have a test seam
[response, streamedText] = aisdk.llms.client.internal.sendRequest(varargin{:});
