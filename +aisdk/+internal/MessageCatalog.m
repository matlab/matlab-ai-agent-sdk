classdef MessageCatalog
%MessageCatalog Stores display and error messages for this repository

%   Copyright 2026 The MathWorks, Inc.

    properties(Constant)
        %CATALOG dictionary mapping error ids to error msgs
        Catalog = buildMessageCatalog;
    end

    methods(Static)
        function msg = getMessage(messageId, hole)
            %getMessage returns error message given a messageID and a HOLE.
            %   The value in HOLE should be ordered, where the n-th element
            %   will replace the value "{n}".

            arguments
                messageId {mustBeNonzeroLengthText}
            end
            arguments(Repeating)
                % Holes may be empty: a message forwarded from a server or
                % from the MEX gateway can come in without any text.
                hole {mustBeTextScalar}
            end

            msg = aisdk.internal.MessageCatalog.Catalog(messageId);
            if ~isempty(hole)
                for i=1:numel(hole)
                    msg = replace(msg,"{"+i+"}", hole{i});
                end
            end
        end

        function s = createCatalog()
            %createCatalog will run the initialization code and return the catalog
            %   This is only meant to get more correct test coverage reports:
            %   The test coverage reports do not include the properties initialization
            %   for Catalog from above, so we have a test seam here to re-run it
            %   within the framework, where it is reported.
            s = buildMessageCatalog;
        end
    end
end

function catalog = buildMessageCatalog
catalog = dictionary("string", "string");
catalog("aisdk:keyMustBeSpecified") = "Unable to find API key. Either set environment variable {1} or specify name-value argument ""APIKey"".";
catalog("aisdk:mustSetFunctionsForCall") = "When Tools is empty, ToolChoice must be ""none"" or ""auto"".";
catalog("aisdk:apiReturnedError") = "Server returned error indicating: ""{1}""";
catalog("aisdk:apiReturnedIncompleteJSON") = "Model output is invalid JSON: {1}";
catalog("aisdk:stream:responseStreamer:InvalidInput") = "Unable to stream model output.";
catalog("aisdk:unsupportedDatatypeInPrototype") = "Invalid argument data type. Field values of struct must be numeric, string, logical, or categorical.";
catalog("aisdk:incorrectResponseFormat") = "Response format must be ""text"", ""json"", a struct containing example output, or a string scalar containing a JSON schema.";
catalog("aisdk:requiredArgumentNotFound") = "Model did not generate required input argument {1}.";
catalog("aisdk:anonymousFunctionRequiresName") = "Unable to derive tool name from an anonymous function. Specify the Name name-value argument.";
catalog("aisdk:duplicateArgumentNames") = "Argument names must be unique.";
catalog("aisdk:invalidToolCallArguments") = "Unable to convert tool arguments to struct: {1}";
catalog("aisdk:arrayPrototypeNotSupported") = "Array prototypes are not supported. Use scalar values in prototypes.";
catalog("aisdk:unsupportedMATLABType") = "Unable to convert data type ""{1}"" to JSON schema. Data type must be numeric, logical, string, or char.";
catalog("aisdk:missingTypeAnnotation") = "Unable to infer data type of argument ""{1}"". Specify the class in an arguments block or set the DataType name-value argument.";
catalog("aisdk:invalidFunctionDefinition") = "First argument must be a function handle or an mcpHTTPClient object.";
catalog("aisdk:invalidClientType") = "Client must be an OpenAIClient or OllamaClient object.";
catalog("aisdk:llmToolArgument:invalidInput") = "First argument must be a string scalar or a structure array.";
catalog("aisdk:llmToolArgument:nonScalarRequired") = "Required must be a scalar logical when constructing a single LLMToolArgument.";
catalog("aisdk:llmToolArgument:nonScalarNameValue") = "NameValue must be a scalar logical when constructing a single LLMToolArgument.";
catalog("aisdk:invalidToolArguments") = "Tool arguments must be a struct or LLMToolArgument object.";
catalog("aisdk:invalidFunctionCall") = "Unrecognized tool {1}.";
catalog("aisdk:message:InvalidToolCallID") = "Tool call ID must be empty or a string scalar.";
catalog("aisdk:unsupportedToolType") = "Tools must only contain LocalLLMTool and MCPTool objects.";
catalog("aisdk:workspaceRequiresMultipleOutputs") = "When Workspace is ""agent"", the underlying function must return one or more output arguments for the LLM to process, as well as the updated agent workspace.";
catalog("aisdk:workspaceDoesNotSupportVarargout") = "Functions that return varargout are not supported for tools that operate on the agent workspace.";
catalog("aisdk:client:InvalidMessageInput") = "Messages must be a string scalar, character vector, or LLMMessage array.";
catalog("aisdk:message:NotAnImage") = "Unable to read image from ''{1}''.";
catalog("aisdk:message:InvalidImageSource") = "Image must be a file path, URL, or numeric array.";
catalog("aisdk:message:InvalidImageContent") = "Message content must be a nonempty numeric or logical array.";
catalog("aisdk:message:InvalidTextContent") = "Message content must be a string scalar or character vector.";
catalog("aisdk:tool:arrayHeader") = "{1} LLMTool array with tools:";
catalog("aisdk:vararginInInputs") = "Unable to derive input arguments because the function signature contains ''varargin''. Specify the InputArguments name-value argument.";
catalog("aisdk:cannotInferInputArguments") = "Unable to derive input arguments from the function metadata. Specify the InputArguments name-value argument.";
catalog("aisdk:varargoutInOutputs") = "Unable to derive output arguments because the function signature contains ''varargout''. Specify the OutputArguments name-value argument.";
catalog("aisdk:unknownOutputCount") = "Unable to derive output arguments because the function has an unknown number of outputs. Specify the OutputArguments name-value argument.";
catalog("aisdk:nestedFunctionRequiresExplicitDefinition") = "Unable to derive function arguments from a nested function. Specify the InputArguments and OutputArguments name-value arguments.";
catalog("aisdk:mcpClient:nonScalarURL") = "MCP server URL must be a string scalar or character vector.";
catalog("aisdk:mcpClient:urlEndpointRequiresHttpTransport") = "To specify the MCP server as a URL, the transport protocol must be ""streamable-http"" or ""sse"".";
catalog("aisdk:mcpClient:httpTransportRequiresUrl") = "When Transport=""{1}"", the endpoint must start with ""http://"" or ""https://"". To start a local command, specify Transport=""stdio"" instead.";
catalog("aisdk:mcpClient:invalidToolPrefix") = "ToolPrefix must start with a letter and contain only letters, digits, and underscores.";
catalog("aisdk:mcpClient:oddNameValuePairs") = "Arguments after the tool name must be name-value pairs.";
catalog("aisdk:mcpClient:badRequest") = "The server rejected the connection with Bad Request. Check that the URL and transport type are correct: a server that expects streamable HTTP rejects SSE connections, and the other way round.";
catalog("aisdk:mcpClient:unauthorized") = "MCP servers that require authentication are not supported.";
catalog("aisdk:mcpClient:forbidden") = "The MCP server denied access.";
catalog("aisdk:mcpClient:notFound") = "The MCP server endpoint was not found. Check that the URL is correct.";
catalog("aisdk:mcpClient:methodNotAllowed") = "The server returned Method Not Allowed. Check that the URL and transport type are correct.";
catalog("aisdk:mcpClient:badGateway") = "The MCP server is unreachable (bad gateway). Check that the server is running.";
catalog("aisdk:mcpClient:hostNotFound") = "Host not found. Check that the URL is correct.";
catalog("aisdk:mcpClient:connectionRefused") = "Connection refused. Check that the server is running and the port is correct.";
catalog("aisdk:mcpClient:connectionTimeout") = "Connection timed out. The server may be unreachable or the TimeOut value may be too low.";
catalog("aisdk:mcpClient:stdioNotFound") = "The MCP server command was not found. Check that it is installed and on PATH.";
catalog("aisdk:mcpClient:stdioPermission") = "Permission denied when starting the MCP server. Check the file permissions.";
% The remaining messages come from outside MATLAB - the MEX gateway or the
% MCP server - and are reported verbatim.
catalog("aisdk:mcpClient:internalError") = "{1}";
catalog("aisdk:mcpClient:serverError") = "{1}";
end
