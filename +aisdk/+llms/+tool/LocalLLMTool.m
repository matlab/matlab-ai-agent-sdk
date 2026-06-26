classdef LocalLLMTool < aisdk.llms.tool.CallableTool
%LocalLLMTool Tool wrapping a MATLAB function for use with an LLM.

% Copyright 2026 The MathWorks, Inc.

    properties
        %Workspace   Whether the function accepts and returns a workspace argument.
        Workspace(1,1) string {mustBeMember(Workspace, ["none","agent"])} = "none"
    end

    methods
        function this = LocalLLMTool(fcnHandle, name, NVPairs)
            arguments
                fcnHandle(1,1) function_handle
                name(1,1) string = ""
                NVPairs.Description(1,1) string
                NVPairs.DisplayTitle(1,1) string
                NVPairs.InputArguments(1,:)
                NVPairs.OutputArguments(1,:)
                NVPairs.Annotations(1,1) struct = struct()
                NVPairs.RequiresApproval(1,1) aisdk.llms.tool.RequiresApproval = "never"
                NVPairs.Workspace(1,1) string {mustBeMember(NVPairs.Workspace, ["none","agent"])}
            end

            funcName = func2str(fcnHandle);

            % func2str only starts with "@" for anonymous functions
            isAnonymous = startsWith(funcName, "@");
            if isAnonymous && strlength(name) == 0
                error("llms:anonymousFunctionRequiresName", ...
                    aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:anonymousFunctionRequiresName"));
            end

            this.Function = fcnHandle;
            if strlength(name) > 0
                this.Name = name;
            else
                this.Name = replace(funcName, ".", "_");
            end

            if isfield(NVPairs, "DisplayTitle")
                this.DisplayTitle = NVPairs.DisplayTitle;
            else
                this.DisplayTitle = this.Name;
            end

            metaData = aisdk.llms.tool.LocalLLMTool.getMetaData(funcName);
            hasMetaData = ~isempty(metaData);

            if isfield(NVPairs, "Workspace")
                this.Workspace = NVPairs.Workspace;
            else
                this.Workspace = "none";
            end

            if this.Workspace == "agent"
                n = nargout(fcnHandle);
                if n < 0
                    error("llms:workspaceDoesNotSupportVarargout", ...
                        aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:workspaceDoesNotSupportVarargout"));
                elseif n < 2
                    error("llms:workspaceRequiresMultipleOutputs", ...
                        aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:workspaceRequiresMultipleOutputs"));
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
                this.InputArguments = aisdk.llms.tool.LocalLLMTool.getParamsFromSignature(inputs, true);
            else
                this.InputArguments = aisdk.LLMToolArgument.empty(1,0);
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
                this.OutputArguments = aisdk.llms.tool.LocalLLMTool.getParamsFromSignature(outputs, false);
            else
                this.OutputArguments = aisdk.LLMToolArgument.empty(1,0);
            end

            aisdk.llms.tool.LocalLLMTool.checkDuplicateNames(this.InputArguments, "input");
            aisdk.llms.tool.LocalLLMTool.checkDuplicateNames(this.OutputArguments, "output");

            this.Annotations = NVPairs.Annotations;
            this.RequiresApproval = NVPairs.RequiresApproval;
        end

    end

    methods (Access = protected)

        function [output, workspace] = evaluateImpl(this, args, workspace)
            arguments
                this(1,1) aisdk.llms.tool.LocalLLMTool
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
                        error("llms:requiredArgumentNotFound", aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:requiredArgumentNotFound", iInput.Name));
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
                error("llms:duplicateArgumentNames", ...
                    aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:duplicateArgumentNames", kind));
            end
        end

        function params = getParamsFromSignature(signature, requireType)
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
                    args{end+1} = aisdk.llms.tool.LocalLLMTool.matlabTypeToJsonSchema( ...
                        param.Validation.Class.Name);
                elseif requireType
                    error("llms:missingTypeAnnotation", ...
                        aisdk.llms.internal.ErrorMessageCatalog.getMessage( ...
                        "llms:missingTypeAnnotation", param.Identifier.Name));
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
                    error("llms:unsupportedMATLABType", ...
                        aisdk.llms.internal.ErrorMessageCatalog.getMessage("llms:unsupportedMATLABType", matlabType));
            end
        end


        function metaData = getMetaData(fcnName)
            if ~isempty(which('metafunction'))
                metaData = metafunction(fcnName);
            else
                metaData = aisdk.llms.tool.LocalLLMTool.convertInternalMeta( ...
                    matlab.internal.metafunction(fcnName));
            end
        end

        function out = convertInternalMeta(m)
            if isempty(m)
                out = [];
                return
            end
            out.Name = m.Name;
            out.Description = m.Description;
            out.Signature.Inputs = aisdk.llms.tool.LocalLLMTool.convertArgs(m.Signature.Inputs);
            out.Signature.Outputs = aisdk.llms.tool.LocalLLMTool.convertArgs(m.Signature.Outputs);
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
