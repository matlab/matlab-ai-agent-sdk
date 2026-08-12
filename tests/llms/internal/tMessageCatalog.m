classdef tMessageCatalog < matlab.unittest.TestCase
% Tests for aisdk.llms.internal.MessageCatalog.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function createCatalog_returnsDictionary(testCase)
            catalog = aisdk.llms.internal.MessageCatalog.createCatalog();
            testCase.verifyClass(catalog, 'dictionary');
        end

        function getMessage_noHole_matchesCatalogDirectly(testCase)
            catalog = aisdk.llms.internal.MessageCatalog.createCatalog();
            expected = catalog("llms:mustSetFunctionsForCall");
            msg = aisdk.llms.internal.MessageCatalog.getMessage( ...
                "llms:mustSetFunctionsForCall");
            testCase.verifyEqual(msg, expected);
        end

        function getMessage_withHole_replacesPlaceholder(testCase)
            catalog = aisdk.llms.internal.MessageCatalog.createCatalog();
            messageWithPlaceholder = catalog("llms:keyMustBeSpecified");
            msg = aisdk.llms.internal.MessageCatalog.getMessage( ...
                "llms:keyMustBeSpecified", "MY_API_KEY");
            testCase.verifyEqual(msg, replace(messageWithPlaceholder, "{1}", "MY_API_KEY"));
        end

        function getMessage_unknownId_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.llms.internal.MessageCatalog.getMessage( ...
                    "llms:nonexistentId"), ...
                "MATLAB:dictionary:ScalarKeyNotFound");
        end
    end
end
