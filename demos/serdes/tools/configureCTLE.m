function [observation, workspace] = configureCTLE(workspace, nvp)
%configureCTLE Configure a CTLE block on the receiver.
%   [OBSERVATION, WORKSPACE] = configureCTLE(WORKSPACE, ...) sets parameters
%   on the CTLE block. Specification must be set before gain properties.

    arguments (Input)
        workspace struct
        nvp.Specification (1,1) string = ""       % "DC Gain and Peaking Gain" (default), "DC Gain and AC Gain", "AC Gain and Peaking Gain", or "GPZ Matrix"
        nvp.DCGain (1,:) double = []              % DC gain (at f=0) in dB, usually <=0 (attenuation). Vector defines CTLE family, e.g. [0 -1 -2 -3 -4 -5 -6 -7 -8]. Default=0:-1:-8
        nvp.ACGain (1,:) double = []              % AC gain = gain AT THE PEAK (peaking frequency) in dB, i.e. the maximum gain, NOT the high-frequency asymptote. Equals DCGain+PeakingGain. Use when the prompt gives an absolute AC/peak gain. Default=0
        nvp.PeakingFrequency (1,:) double = []    % Peaking frequency in Hz, scalar or vector. Default=5e9
        nvp.PeakingGain (1,:) double = []         % Peaking gain = boost ABOVE DC in dB (RELATIVE, = ACGain-DCGain), not an absolute peak value. Use when the prompt says "peaking"/"boost". e.g. [0 1 2 3 4 5 6 7 8]. Default=0:8
        nvp.GPZ (:,:) double = []                 % Gain-pole-zero matrix [G,P1,Z1,P2,...], rows=configs. Default=9x4 matrix
        nvp.ConfigSelect double = []        % Zero-based index selecting CTLE config (requires Mode=1). Default=0
        nvp.Mode double = []                % 0=Off, 1=Fixed, 2=Adapt. Omit to use default (Adapt). Only set if prompt specifies a mode.
    end
    arguments (Output)
        observation (1,1) string
        workspace (1,1) struct
    end

    % Soft-create: if no Rx architecture exists, create with CTLE only
    createdArch = false;
    if ~isfield(workspace, 'rxBlocks') || isempty(workspace.rxBlocks)
        workspace.rxBlocks = {serdes.CTLE};
        workspace.rxBlockTypes = ["CTLE"];
        workspace.rxModel = Receiver('Blocks', workspace.rxBlocks);
        createdArch = true;
    end

    idx = find(workspace.rxBlockTypes == "CTLE", 1);
    % Soft-create: if CTLE block not in architecture, prepend one
    if isempty(idx)
        workspace.rxBlocks = [{serdes.CTLE}, workspace.rxBlocks];
        workspace.rxBlockTypes = ["CTLE", workspace.rxBlockTypes];
        workspace.rxModel = Receiver('Blocks', workspace.rxBlocks);
        idx = 1;
        createdArch = true;
    end

    obj = workspace.rxBlocks{idx};
    if isLocked(obj)
        release(obj);
    end

    % Specification must be set first (changes which properties are valid)
    % Auto-switch if ACGain provided without explicit Specification
    autoSwitched = false;
    if nvp.Specification ~= ""
        obj.Specification = nvp.Specification;
    elseif ~isempty(nvp.ACGain) && obj.Specification ~= "DC Gain and AC Gain" && obj.Specification ~= "AC Gain and Peaking Gain"
        obj.Specification = "DC Gain and AC Gain";
        autoSwitched = true;
    end

    if ~isempty(nvp.DCGain)
        obj.DCGain = nvp.DCGain;
    end
    if ~isempty(nvp.ACGain)
        obj.ACGain = nvp.ACGain;
    end
    if ~isempty(nvp.PeakingFrequency)
        obj.PeakingFrequency = nvp.PeakingFrequency;
    end
    if ~isempty(nvp.PeakingGain)
        obj.PeakingGain = nvp.PeakingGain;
    end
    if ~isempty(nvp.GPZ)
        obj.GPZ = nvp.GPZ;
    end
    if ~isempty(nvp.Mode)
        obj.Mode = nvp.Mode;
    end
    if ~isempty(nvp.ConfigSelect)
        assert(obj.Mode == 1, 'configureCTLE:modeRequired', ...
            'ConfigSelect requires Mode=1. Set Mode=1 first.');
        obj.ConfigSelect = nvp.ConfigSelect;
    end


    workspace.rxBlocks{idx} = obj;

    specStr = string(obj.Specification);
    nConfigs = size(obj.GPZ, 1);
    if specStr == "GPZ Matrix"
        nConfigs = size(obj.GPZ, 1);
    elseif isprop(obj, 'DCGain')
        nConfigs = numel(obj.DCGain);
    end

    prefix = "";
    if createdArch
        prefix = "No Rx architecture set; created [CTLE]. ";
    end
    if autoSwitched
        prefix = prefix + "Note: Specification was ""DC Gain and Peaking Gain"" (ACGain is irrelevant under that mode). Auto-switched to ""DC Gain and AC Gain"" so ACGain takes effect. ";
    end

    if specStr == "GPZ Matrix"
        observation = sprintf('%sCTLE configured: Mode=%d (%s), Spec="GPZ Matrix", %d configs. Ready for configureDFECDR or runAnalysis.', ...
            prefix, obj.Mode, modeStr(obj.Mode), nConfigs);
    else
        % Report the full gain triple. Because a CTLE Specification names only
        % two of the three gains as active properties, derive the third via the
        % identity ACGain = DCGain + PeakingGain (all dB) so all three are
        % always reported consistently.
        switch specStr
            case "DC Gain and AC Gain"
                dc = obj.DCGain; ac = obj.ACGain;
                pk = combineGains(ac, dc, -1); derived = "PeakingGain";
            case "AC Gain and Peaking Gain"
                ac = obj.ACGain; pk = obj.PeakingGain;
                dc = combineGains(ac, pk, -1); derived = "DCGain";
            otherwise  % "DC Gain and Peaking Gain" (toolbox default)
                dc = obj.DCGain; pk = obj.PeakingGain;
                ac = combineGains(dc, pk, +1); derived = "ACGain";
        end
        observation = sprintf(['%sCTLE configured: Mode=%d (%s), Spec="%s", ' ...
            'DCGain=[%s] dB, ACGain=[%s] dB (=gain at peak), PeakingGain=[%s] dB (=boost above DC), ' ...
            '%s derived via ACGain=DCGain+PeakingGain, PeakingFreq=%.2f GHz, %d configs. ' ...
            'Ready for configureDFECDR or runAnalysis.'], ...
            prefix, obj.Mode, modeStr(obj.Mode), specStr, ...
            gainField(dc), gainField(ac), gainField(pk), derived, ...
            obj.PeakingFrequency/1e9, nConfigs);
    end
end

function r = combineGains(a, b, sgn)
    % Elementwise a + sgn*b with scalar broadcast; [] if lengths mismatch.
    if isempty(a) || isempty(b)
        r = [];
    elseif isscalar(a) || isscalar(b) || numel(a) == numel(b)
        r = a + sgn * b;
    else
        r = [];
    end
end

function s = gainField(v)
    % Format a scalar or vector gain for the observation; "?" if unknown.
    if isempty(v)
        s = "?";
    else
        s = string(strtrim(num2str(v, '%.1f ')));
    end
end

function s = modeStr(m)
    switch m
        case 0, s = "Off";
        case 1, s = "Fixed";
        case 2, s = "Adapt";
        otherwise, s = "Unknown";
    end
end
