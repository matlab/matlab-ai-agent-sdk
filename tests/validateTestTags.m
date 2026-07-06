function missingTag = validateTestTags(suite)
%validateTestTags Verify that all tests have at least one required tag.
%   validateTestTags discovers all tests and fails if any are missing a
%   required tag (Unit, Integration, or System).
%
%   missingTag = validateTestTags(suite) accepts an existing test suite,
%   prints diagnostics, and returns the list of untagged test names without
%   asserting. This allows callers to collect all diagnostics before failing.

% Copyright 2026 The MathWorks, Inc.

if nargin == 0
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    suite = testsuite(repoRoot, IncludeSubfolders=true);
end

% Every test must have at least one of these classification tags
requiredTags = ["Unit", "Integration", "System"];

% Find tests missing a required tag
missingTag = {};
for i = 1:numel(suite)
    tags = string(suite(i).Tags);
    if ~any(ismember(requiredTags, tags))
        missingTag{end+1} = suite(i).Name; %#ok<SAGROW>
    end
end

% Report results
if ~isempty(missingTag)
    fprintf('\n=== TESTS MISSING REQUIRED TAG ===\n\n');
    for i = 1:numel(missingTag)
        fprintf('  %s\n', missingTag{i});
    end
    fprintf('\n%d test(s) are missing a classification tag.\n', numel(missingTag));
    fprintf('Each test must have at least one of: Unit, Integration, System.\n');
    fprintf('Add TestTags to their methods block, e.g.:\n');
    fprintf('  methods(Test, TestTags = {''Unit''})\n\n');
end

% When called standalone (no output requested), assert directly
if nargout == 0
    assert(isempty(missingTag), ...
        '%d test(s) are missing a required tag (Unit, Integration, or System). See list above.', ...
        numel(missingTag));
    fprintf('All %d tests are tagged.\n', numel(suite));
end
end
