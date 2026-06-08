classdef terrorMessageCatalog < matlab.unittest.TestCase
% Tests for aisdk.llms.internal.ErrorMessageCatalog.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test)
        function createCatalog_containsExpectedKeys(testCase)
            catalog = aisdk.llms.internal.ErrorMessageCatalog.createCatalog();
            testCase.verifyClass(catalog, 'dictionary');
            testCase.verifyTrue(isKey(catalog, "llms:keyMustBeSpecified"));
        end

        function getMessage_knownId_returnsMessage(testCase)
            msg = aisdk.llms.internal.ErrorMessageCatalog.getMessage( ...
                "llms:mustSetFunctionsForCall");
            testCase.verifyClass(msg, 'string');
            testCase.verifyGreaterThan(strlength(msg), 0);
        end

        function getMessage_withSlot_replacesPlaceholder(testCase)
            msg = aisdk.llms.internal.ErrorMessageCatalog.getMessage( ...
                "llms:keyMustBeSpecified", "MY_API_KEY");
            testCase.verifySubstring(msg, "MY_API_KEY");
        end

        function getMessage_unknownId_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.ErrorMessageCatalog.getMessage( ...
                    "llms:nonexistentId"), ...
                "MATLAB:dictionary:ScalarKeyNotFound");
        end
    end
end
