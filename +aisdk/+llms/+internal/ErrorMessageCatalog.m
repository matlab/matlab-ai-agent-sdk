classdef ErrorMessageCatalog
%ErrorMessageCatalog Stores the error messages from this repository

%   Copyright 2026 The MathWorks, Inc.

    properties(Constant)
        %CATALOG dictionary mapping error ids to error msgs
        Catalog = buildErrorMessageCatalog;
    end

    methods(Static)
        function msg = getMessage(messageId, slot)
            %getMessage returns error message given a messageID and a SLOT.
            %   The value in SLOT should be ordered, where the n-th element
            %   will replace the value "{n}".

            arguments
                messageId {mustBeNonzeroLengthText}
            end
            arguments(Repeating)
                slot {mustBeNonzeroLengthText}
            end

            msg = aisdk.llms.internal.ErrorMessageCatalog.Catalog(messageId);
            if ~isempty(slot)
                for i=1:numel(slot)
                    msg = replace(msg,"{"+i+"}", slot{i});
                end
            end
        end

        function s = createCatalog()
            %createCatalog will run the initialization code and return the catalog
            %   This is only meant to get more correct test coverage reports:
            %   The test coverage reports do not include the properties initialization
            %   for Catalog from above, so we have a test seam here to re-run it
            %   within the framework, where it is reported.
            s = buildErrorMessageCatalog;
        end
    end
end

function catalog = buildErrorMessageCatalog
catalog = dictionary("string", "string");
catalog("llms:keyMustBeSpecified") = "Unable to find API key. Either set environment variable {1} or specify name-value argument ""APIKey"".";
catalog("llms:mustSetFunctionsForCall") = "When Tools is empty, ToolChoice must be ""none"" or ""auto"".";
catalog("llms:apiReturnedError") = "Server returned error indicating: ""{1}""";
catalog("llms:apiReturnedIncompleteJSON") = "Model output is invalid JSON: {1}";
catalog("llms:stream:responseStreamer:InvalidInput") = "Unable to stream model output.";
catalog("llms:unsupportedDatatypeInPrototype") = "Invalid argument data type. Field values of struct must be numeric, string, logical, or categorical.";
catalog("llms:incorrectResponseFormat") = "Response format must be ""text"", ""json"", a struct containing example output, or a string scalar containing a JSON schema.";
catalog("llms:requiredArgumentNotFound") = "Model did not generate required input argument {1}.";
catalog("llms:anonymousFunctionRequiresName") = "Not enough input arguments. When tool is an anonymous function, the second argument must be the tool name.";
catalog("llms:duplicateArgumentNames") = "Argument names must be unique.";
catalog("llms:invalidToolCallArguments") = "Unable to convert tool arguments to struct: {1}";
catalog("llms:arrayPrototypeNotSupported") = "Array prototypes are not supported. Use scalar values in prototypes.";
catalog("llms:unsupportedMATLABType") = "Unable to convert data type ""{1}"" to JSON schema. Data type must be numeric, logical, string, or char.";
catalog("llms:invalidFunctionDefinition") = "First argument must be a function handle or an mcpHTTPClient object.";
catalog("llms:invalidClientType") = "Client must be an OpenAIClient or OllamaClient object.";
catalog("llmToolArgument:invalidInput") = "First argument must be a string scalar or a structure array.";
catalog("llmToolArgument:requiredNameValue") = "A name-value argument cannot be required. Set Required=false or NameValue=false.";
catalog("llmToolArgument:nonScalarRequired") = "Required must be a scalar logical when constructing a single LLMToolArgument.";
catalog("llmToolArgument:nonScalarNameValue") = "NameValue must be a scalar logical when constructing a single LLMToolArgument.";
catalog("llms:message:InvalidContent") = "Message content must be empty or a string scalar.";
catalog("llms:invalidFunctionCall") = "Unrecognized tool {1}.";
catalog("llms:message:InvalidToolCallID") = "Tool call ID must be empty or a string scalar.";
catalog("llms:unsupportedToolType") = "Tools must only contain LocalLLMTool and MCPTool objects.";
catalog("llms:client:InvalidMessageInput") = "Messages must be a string scalar, character vector, or LLMMessage array.";
end
