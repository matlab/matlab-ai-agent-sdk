classdef tMessageCatalog < matlab.unittest.TestCase
% Tests for aisdk.internal.MessageCatalog.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function createCatalog_returnsDictionary(testCase)
            catalog = aisdk.internal.MessageCatalog.createCatalog();
            testCase.verifyClass(catalog, 'dictionary');
        end

        function getMessage_noHole_matchesCatalogDirectly(testCase)
            catalog = aisdk.internal.MessageCatalog.createCatalog();
            expected = catalog("aisdk:mustSetFunctionsForCall");
            msg = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:mustSetFunctionsForCall");
            testCase.verifyEqual(msg, expected);
        end

        function getMessage_withHole_replacesPlaceholder(testCase)
            catalog = aisdk.internal.MessageCatalog.createCatalog();
            messageWithPlaceholder = catalog("aisdk:keyMustBeSpecified");
            msg = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:keyMustBeSpecified", "MY_API_KEY");
            testCase.verifyEqual(msg, replace(messageWithPlaceholder, "{1}", "MY_API_KEY"));
        end

        function getMessage_emptyHole_replacesPlaceholder(testCase)
            msg = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:mcpClient:serverError", "");
            testCase.verifyEqual(msg, "");
        end

        function getMessage_unknownId_throwsError(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.MessageCatalog.getMessage( ...
                    "aisdk:nonexistentId"), ...
                "MATLAB:dictionary:ScalarKeyNotFound");
        end
    end
end
