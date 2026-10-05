classdef tthrowError < matlab.unittest.TestCase
% Tests for aisdk.internal.throwError.

%   Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Unit'})
        function noHole_throwsCatalogMessage(testCase)
            err = testCase.captureError( ...
                @() aisdk.internal.throwError("aisdk:mustSetFunctionsForCall"));
            testCase.verifyEqual(err.identifier, 'aisdk:mustSetFunctionsForCall');
            testCase.verifyEqual(string(err.message), ...
                aisdk.internal.MessageCatalog.getMessage("aisdk:mustSetFunctionsForCall"));
        end

        function withHole_throwsFilledMessage(testCase)
            err = testCase.captureError( ...
                @() aisdk.internal.throwError( ...
                    "aisdk:keyMustBeSpecified", "MY_API_KEY"));
            testCase.verifyEqual(err.identifier, 'aisdk:keyMustBeSpecified');
            testCase.verifyEqual(string(err.message), ...
                aisdk.internal.MessageCatalog.getMessage( ...
                    "aisdk:keyMustBeSpecified", "MY_API_KEY"));
        end

        function holeWithFormatCharacters_isNotFormatted(testCase)
            % Text arriving from a server or from user data is not a format
            % string: '%' and '\' must show up verbatim.
            serverText = "100%d done, 50%% left, see C:\new\table";
            err = testCase.captureError( ...
                @() aisdk.internal.throwError("aisdk:apiReturnedError", serverText));
            testCase.verifyEqual(err.identifier, 'aisdk:apiReturnedError');
            testCase.verifyTrue(contains(err.message, serverText));
        end

        function emptyPassthroughMessage_keepsIdentifier(testCase)
            % A server or the MEX gateway may report a failure without any
            % text. The identifier still has to describe the failure rather
            % than an argument validation problem inside the SDK.
            err = testCase.captureError( ...
                @() aisdk.internal.throwError("aisdk:mcpClient:serverError", ""));
            testCase.verifyEqual(err.identifier, 'aisdk:mcpClient:serverError');
            testCase.verifyEqual(string(err.message), "");
        end

        function error_reportedFromCallerOfThrowError(testCase)
            err = testCase.captureError(@() throwFromHelper);
            testCase.verifyEqual(err.identifier, 'aisdk:mustSetFunctionsForCall');
            testCase.verifyTrue(endsWith(err.stack(1).name, "throwFromHelper"), ...
                "Error should be reported from the caller of throwError.");
            testCase.verifyFalse( ...
                any(contains(string({err.stack.name}), "aisdk.internal.throwError")), ...
                "throwError should not appear in the stack.");
        end

        function unknownId_throwsCatalogLookupError(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.throwError("aisdk:nonexistentId"), ...
                "MATLAB:dictionary:ScalarKeyNotFound");
        end

        function emptyId_isRejected(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.throwError(""), ...
                "MATLAB:validators:mustBeNonzeroLengthText");
        end
    end

    methods (Access = private)
        function err = captureError(testCase, fcn)
            %captureError Return the MException thrown by FCN.
            try
                fcn();
                testCase.verifyFail("Expected the function to throw an error.");
                err = MException("aisdk:test:noError", "no error thrown");
            catch err
            end
        end
    end
end

function throwFromHelper()
aisdk.internal.throwError("aisdk:mustSetFunctionsForCall");
end
