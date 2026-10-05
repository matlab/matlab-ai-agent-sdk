classdef LocalLLMTool < aisdk.tool.internal.CallableTool
%LocalLLMTool Tool wrapping a MATLAB function for use with an LLM.

% Copyright 2026 The MathWorks, Inc.

    properties
        %InputArguments   Description of the tool inputs.
        InputArguments

        %OutputArguments   Description of the tool outputs.
        OutputArguments
    end

    methods
        function this = LocalLLMTool(fcnHandle, NVPairs)
            arguments
                fcnHandle(1,1) function_handle
                NVPairs.Name(1,1) string = ""
                NVPairs.Description(1,1) string
                NVPairs.DisplayTitle(1,1) string
                NVPairs.InputArguments(1,:) {aisdk.internal.mustBeToolArguments}
                NVPairs.OutputArguments(1,:) {aisdk.internal.mustBeToolArguments}
                NVPairs.Annotations(1,1) struct = struct()
                NVPairs.ApprovalRequest(1,1) aisdk.tool.ApprovalRequest = "never"
                NVPairs.Workspace(1,1) string {mustBeMember(NVPairs.Workspace, ["none","agent"])}
            end

            fcnInfo = functions(fcnHandle);
            funcName = fcnInfo.function;
            if fcnInfo.type == "anonymous" && strlength(NVPairs.Name) == 0
                error("aisdk:anonymousFunctionRequiresName", ...
                    aisdk.internal.MessageCatalog.getMessage("aisdk:anonymousFunctionRequiresName"));
            end

            if fcnInfo.type == "nested" && (~isfield(NVPairs, "InputArguments") || ~isfield(NVPairs, "OutputArguments"))
                error("aisdk:nestedFunctionRequiresExplicitDefinition", ...
                    aisdk.internal.MessageCatalog.getMessage("aisdk:nestedFunctionRequiresExplicitDefinition"));
            end

            this.Function = fcnHandle;
            if strlength(NVPairs.Name) > 0
                this.Name = NVPairs.Name;
            elseif contains(funcName, "/")
                this.Name = extractAfter(funcName, "/");
            else
                this.Name = replace(funcName, ".", "_");
            end

            if isfield(NVPairs, "DisplayTitle")
                this.DisplayTitle = NVPairs.DisplayTitle;
            else
                this.DisplayTitle = this.Name;
            end

            metaData = aisdk.tool.LocalLLMTool.getMetaData(fcnHandle);
            hasMetaData = ~isempty(metaData);

            if isfield(NVPairs, "Workspace")
                this.Workspace = NVPairs.Workspace;
            else
                this.Workspace = "none";
            end

            if this.Workspace == "agent"
                n = nargout(fcnHandle);
                if n < 0
                    error("aisdk:workspaceDoesNotSupportVarargout", ...
                        aisdk.internal.MessageCatalog.getMessage("aisdk:workspaceDoesNotSupportVarargout"));
                elseif n < 2
                    error("aisdk:workspaceRequiresMultipleOutputs", ...
                        aisdk.internal.MessageCatalog.getMessage("aisdk:workspaceRequiresMultipleOutputs"));
                end
            end

            if isfield(NVPairs, "Description")
                this.Description = NVPairs.Description;
            elseif hasMetaData
                this.Description = metaData.Description;
            end

            if isfield(NVPairs, "InputArguments") && isa(NVPairs.InputArguments, "aisdk.LLMToolArgument")
                this.InputArguments = NVPairs.InputArguments;
            elseif isfield(NVPairs, "InputArguments") && isstruct(NVPairs.InputArguments)
                this.InputArguments = aisdk.LLMToolArgument(NVPairs.InputArguments);
            elseif hasMetaData
                inputs = metaData.Signature.Inputs;
                if this.Workspace == "agent" && ~isempty(inputs)
                    inputs = inputs(2:end);
                end
                inputNames = arrayfun(@(s) string(s.Identifier.Name), inputs);
                if ~isempty(inputNames) && any(inputNames == "varargin")
                    error("aisdk:vararginInInputs", ...
                        aisdk.internal.MessageCatalog.getMessage("aisdk:vararginInInputs"));
                end
                this.InputArguments = aisdk.tool.LocalLLMTool.getParamsFromSignature(inputs);
            else
                error("aisdk:cannotInferInputArguments", ...
                    aisdk.internal.MessageCatalog.getMessage("aisdk:cannotInferInputArguments"));
            end

            if isfield(NVPairs, "OutputArguments") && isa(NVPairs.OutputArguments, "aisdk.LLMToolArgument")
                this.OutputArguments = NVPairs.OutputArguments;
            elseif isfield(NVPairs, "OutputArguments") && isstruct(NVPairs.OutputArguments)
                this.OutputArguments = aisdk.LLMToolArgument(NVPairs.OutputArguments);
            elseif hasMetaData
                outputs = metaData.Signature.Outputs;
                if this.Workspace == "agent" && ~isempty(outputs)
                    outputs = outputs(1:end-1);
                end
                outputNames = arrayfun(@(s) string(s.Identifier.Name), outputs);
                if ~isempty(outputNames) && any(outputNames == "varargout")
                    error("aisdk:varargoutInOutputs", ...
                        aisdk.internal.MessageCatalog.getMessage("aisdk:varargoutInOutputs"));
                end
                this.OutputArguments = aisdk.tool.LocalLLMTool.getParamsFromSignature(outputs);
            elseif nargout(fcnHandle) ~= 1
                error("aisdk:unknownOutputCount", ...
                    aisdk.internal.MessageCatalog.getMessage("aisdk:unknownOutputCount"));
            else
                this.OutputArguments = aisdk.LLMToolArgument.empty(1,0);
            end

            aisdk.tool.LocalLLMTool.checkDuplicateNames(this.InputArguments, "input");
            aisdk.tool.LocalLLMTool.checkDuplicateNames(this.OutputArguments, "output");

            this.Annotations = NVPairs.Annotations;
            this.ApprovalRequest = NVPairs.ApprovalRequest;
        end

    end

    methods (Access = protected)

        function sig = displaySignature(obj)
        % Build a display signature like "toolName(arg1, <opt>, Name=Value)".
            maxSigChars = 60;
            args = obj.InputArguments;
            if isempty(args)
                sig = obj.Name + "()";
                return
            end
            hasNameValue = false;
            argLabels = strings(0, 1);
            for j = 1:numel(args)
                if args(j).NameValue
                    hasNameValue = true;
                elseif ~args(j).Required
                    argLabels(end+1) = "<" + args(j).Name + ">"; %#ok<AGROW>
                else
                    argLabels(end+1) = args(j).Name; %#ok<AGROW>
                end
            end
            if hasNameValue
                argLabels(end+1) = "Name=Value";
            end
            inner = join(argLabels, ", ");
            maxInner = maxSigChars - strlength(obj.Name) - 2;
            if maxInner < 1
                inner = "…";
            elseif strlength(inner) > maxInner
                inner = extractBefore(inner, maxInner + 1) + "…";
            end
            sig = obj.Name + "(" + inner + ")";
        end

        function label = displayTypeLabel(~)
            label = "LocalLLMTool";
        end

        function [output, workspace] = evaluateImpl(this, args, workspace)
            arguments
                this(1,1) aisdk.tool.LocalLLMTool
                args(1,1) struct
                workspace
            end
            inputs = this.processArguments(args);
            numOutputs = numel(this.OutputArguments);
            if this.Workspace == "agent"
                nFcnOut = max(numOutputs, 1) + 1;
                outputs = cell(1, nFcnOut);
                [outputs{:}] = this.Function(workspace, inputs{:});
                workspace = outputs{end};
            elseif numOutputs >= 1
                outputs = cell(1, numOutputs);
                [outputs{:}] = this.Function(inputs{:});
            else
                output = this.Function(inputs{:});
                return
            end

            if numOutputs >= 1
                output = struct();
                for i = 1:numOutputs
                    output.(this.OutputArguments(i).Name) = outputs{i};
                end
            else
                output = outputs{1};
            end
        end

        function argsOut = processArguments(this, argsIn)
            argsOut = cell(0,0);
            for iArg = 1:numel(this.InputArguments)
                iInput = this.InputArguments(iArg);
                if ~isfield(argsIn, iInput.Name)
                    if iInput.Required
                        error("aisdk:requiredArgumentNotFound", aisdk.internal.MessageCatalog.getMessage("aisdk:requiredArgumentNotFound", iInput.Name));
                    end
                    continue
                end
                if ~iInput.NameValue
                    argsOut{end + 1} = argsIn.(iInput.Name); %#ok<*AGROW>
                else
                    argsOut{end + 1} = iInput.Name;
                    argsOut{end + 1} = argsIn.(iInput.Name);
                end
            end
        end
    end

    methods (Static, Access = private)
        function checkDuplicateNames(args, kind)
            if isempty(args)
                return
            end
            names = [args.Name];
            if numel(names) ~= numel(unique(names))
                error("aisdk:duplicateArgumentNames", ...
                    aisdk.internal.MessageCatalog.getMessage("aisdk:duplicateArgumentNames", kind));
            end
        end

        function params = getParamsFromSignature(signature)
            if isempty(signature)
                params = aisdk.LLMToolArgument.empty(1,0);
                return
            end
            names = arrayfun(@(s) string(s.Identifier.Name), signature);
            signature = signature( ...
                ~ismember(names, ["varargin", "varargout"]));
            if isempty(signature)
                params = aisdk.LLMToolArgument.empty(1,0);
                return
            end
            for iSig = 1:numel(signature)
                param = signature(iSig);
                args = {param.Identifier.Name, ...
                    "Description", param.Description, ...
                    "NameValue", param.NameValue, ...
                    "Required", param.Required};
                if ~isempty(param.Validation) && ~isempty(param.Validation.Class)
                    args{end+1} = "DataType";
                    args{end+1} = aisdk.tool.LocalLLMTool.matlabTypeToJsonSchema( ...
                        param.Validation.Class.Name);
                end
                params(iSig) = aisdk.LLMToolArgument(args{:}); %#ok<AGROW>
            end
        end

        function jsonType = matlabTypeToJsonSchema(matlabType)
            switch matlabType
                case {"double","single","int8","int16","int32","int64", ...
                        "uint8","uint16","uint32","uint64"}
                    jsonType = "number";
                case "logical"
                    jsonType = "boolean";
                case {"string","char"}
                    jsonType = "string";
                otherwise
                    error("aisdk:unsupportedMATLABType", ...
                        aisdk.internal.MessageCatalog.getMessage("aisdk:unsupportedMATLABType", matlabType));
            end
        end

        function metaData = getMetaData(fcnHandle)
            fn = functions(fcnHandle);
            if isfield(fn, "parentage")
                qualifiedName = join(string(fliplr(fn.parentage)), ">");
            else
                qualifiedName = string(fn.function);
            end
            if ~isempty(which('metafunction'))
                metaData = metafunction(qualifiedName);
            else
                metaData = aisdk.tool.LocalLLMTool.convertInternalMeta( ...
                    matlab.internal.metafunction(qualifiedName));
                % matlab.internal.metafunction does not populate description
                % for all functions, so try the function help instead.
                if ~isempty(metaData) && strlength(metaData.Description) == 0
                    h = strtrim(string(help(qualifiedName)));
                    if strlength(h) > 0
                        lines = splitlines(h);
                        desc = strip(lines(1));
                        fcnName = string(fn.function);
                        if startsWith(desc, fcnName, "IgnoreCase", true)
                            desc = strip(extractAfter(desc, strlength(fcnName)));
                        end
                        desc = regexprep(desc, "^[\s\-]+", "");
                        metaData.Description = desc;
                    end
                end
            end
        end
    end

    methods (Static, Access = {?tLocalLLMTool})
        function out = convertInternalMeta(m)
            if ~isscalar(m)
                % metadata missing or ambiguous
                out = [];
                return
            end
            out.Name = m.Name;
            out.Description = m.Description;
            out.Signature.Inputs = aisdk.tool.LocalLLMTool.convertArgs(m.Signature.Inputs);
            out.Signature.Outputs = aisdk.tool.LocalLLMTool.convertArgs(m.Signature.Outputs);
        end

        function args = convertArgs(oldArgs)
            args = struct("Identifier", {}, "Description", {}, ...
                "NameValue", {}, "Required", {}, "Validation", {});
            idx = 0;
            for i = 1:numel(oldArgs)
                a = oldArgs(i);
                if a.Kind == "varargin" || a.Kind == "varargout"
                    continue
                end
                idx = idx + 1;
                args(idx).Identifier.Name = a.Name;
                args(idx).Description = a.Description;
                args(idx).NameValue = (a.Kind == "namevalue");
                args(idx).Required = isempty(a.DefaultValue) && (a.Kind ~= "namevalue");
                args(idx).Validation = a.Validation;
            end
        end
    end
end
