classdef SkillRegistry < handle
% SkillRegistry Scans, caches, and serves skill content from disk.

%   Copyright 2026 The MathWorks, Inc.

    properties (SetAccess = private)
        ScanPaths (1,:) string
        Skills (1,:) aisdk.internal.Skill
        CatalogText (1,1) string = ""
    end

    properties (SetAccess = private)
        DiscoverSkillsFcn  = @aisdk.internal.SkillRegistry.defaultDiscoverSkills
        FileReadFcn        = @fileread
        LastModifiedFcn    = @aisdk.internal.SkillRegistry.defaultLastModified
    end

    properties (Access = private)
        LastScanned = []
    end

    properties (Constant, Access = private)
        %MaxListedInError   Above this many candidates, "not found" errors omit
        %the list entirely rather than truncate it, so the model is never shown
        %a partial list it could mistake for the full set.
        MaxListedInError = 5
    end

    methods
        function this = SkillRegistry(paths, nvp)
            arguments
                paths (1,:) string
                nvp.DiscoverSkillsFcn = @aisdk.internal.SkillRegistry.defaultDiscoverSkills
                nvp.FileReadFcn = @fileread
                nvp.LastModifiedFcn = @aisdk.internal.SkillRegistry.defaultLastModified
            end
            for path = paths
                if ~isfolder(path)
                    aisdk.internal.throwError("aisdk:skills:DirectoryNotFound", path);
                end
            end
            this.ScanPaths = paths;
            this.DiscoverSkillsFcn = nvp.DiscoverSkillsFcn;
            this.FileReadFcn = nvp.FileReadFcn;
            this.LastModifiedFcn = nvp.LastModifiedFcn;
            this.scan();
        end

        function tf = isStale(this)
        % Has the filesystem changed since last scan?
            current = this.LastModifiedFcn(this.ScanPaths);
            tf = ~isequal(current, this.LastScanned);
        end

        function scan(this)
        % Rebuilds all skills from disk and updates the timestamp.
            skillPaths = this.DiscoverSkillsFcn(this.ScanPaths);
            skills = aisdk.internal.Skill.empty(1, 0);

            for skillPath = skillPaths
                % Normalize Windows line endings (CRLF \r\n) to LF (\n).
                content = replace(string(this.FileReadFcn(skillPath)), string(char([13 10])), newline);
                % Strip BOM (U+FEFF).
                content = erase(content, char(0xFEFF));
                [name, description] = this.parseFrontmatter(content, skillPath);

                skillDir = fileparts(skillPath);
                [~, folderName] = fileparts(skillDir);
                if name ~= string(folderName)
                    aisdk.internal.throwError("aisdk:skills:NameFolderMismatch", name, folderName, skillPath);
                end

                % Error if a skill with this name was already discovered.
                if ~isempty(skills) && any([skills.Name] == name)
                    existing = skills([skills.Name] == name).Path;
                    aisdk.internal.throwError("aisdk:skills:DuplicateSkillName", name, existing + ", " + skillPath);
                end

                body = this.extractBody(content);
                resources = this.discoverResources(skillDir);
                skills(end+1) = aisdk.internal.Skill(name, description, skillPath, body, resources); %#ok<AGROW>
            end

            this.Skills = skills;
            this.buildCatalog();
            this.LastScanned = this.LastModifiedFcn(this.ScanPaths);
        end

        function result = loadSkillImpl(this, nameOrPath)
        % Splits at first "/": no slash → skill body, with slash → resource lookup.
            arguments
                this
                nameOrPath (1,1) string
            end
            nameOrPath = replace(nameOrPath, "\", "/");
            if contains(nameOrPath, "/")
                parts = split(nameOrPath, "/");
                name = parts(1);
                resourceKey = join(parts(2:end), "/");
                skill = this.select(name);
                if ~isKey(skill.Resources, resourceKey)
                    error("aisdk:skills:ResourceNotFound", "%s", ...
                        this.buildResourceNotFoundMessage(resourceKey, skill));
                end
                result = skill.Resources(resourceKey);
            else
                skill = this.select(nameOrPath);
                result = skill.Body;
            end
        end
    end

    methods (Access = {?tSkillRegistry})
        function msg = buildSkillNotFoundMessage(this, name)
            msg = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:tool:SkillNotFound", name);
            if ~isempty(this.Skills) && numel(this.Skills) <= this.MaxListedInError
                msg = msg + " " + aisdk.internal.MessageCatalog.getMessage( ...
                    "aisdk:tool:AvailableSkills", join([this.Skills.Name], ", "));
            end
        end

        function msg = buildResourceNotFoundMessage(this, relativePath, skill)
            msg = aisdk.internal.MessageCatalog.getMessage( ...
                "aisdk:tool:ResourceNotFound", relativePath, skill.Name);
            n = numEntries(skill.Resources);
            if n > 0 && n <= this.MaxListedInError
                msg = msg + " " + aisdk.internal.MessageCatalog.getMessage( ...
                    "aisdk:tool:AvailableResources", skill.Name, join(keys(skill.Resources), ", "));
            end
        end
    end

    methods (Access = private)
        function skill = select(this, name)
            if ~isempty(this.Skills)
                idx = [this.Skills.Name] == name;
                if any(idx)
                    skill = this.Skills(idx);
                    return
                end
            end
            error("aisdk:skills:SkillNotFound", "%s", this.buildSkillNotFoundMessage(name));
        end

        function resources = discoverResources(this, skillDir)
        % Collects sibling files and one-level-deep subfolder contents as resources.
            resources = dictionary;
            for entry = dir(skillDir)'
                % Skip dotfiles (.env) and dotfolders (.git, ., ..)
                if startsWith(entry.name, ".")
                    continue
                end
                fullPath = fullfile(skillDir, entry.name);
                if ~entry.isdir
                    % Sibling file (e.g. "example.m") — skip SKILL.md itself
                    if ~strcmpi(entry.name, "SKILL.md")
                        relKey = string(entry.name);
                        content = string(this.FileReadFcn(fullPath));
                        resources(relKey) = content;
                    end
                else
                    % Subfolder (e.g. "references/") — include its files, no deeper
                    for subEntry = dir(fullPath)'
                        if ~subEntry.isdir && ~startsWith(subEntry.name, ".")
                            subFullPath = fullfile(fullPath, subEntry.name);
                            relKey = entry.name + "/" + subEntry.name;
                            content = string(this.FileReadFcn(subFullPath));
                            resources(relKey) = content;
                        end
                    end
                end
            end
        end

        function [name, description] = parseFrontmatter(this, content, skillPath)
        % Extracts name and description from the YAML frontmatter block.
            lines = splitlines(content);

            % Opening delimiter: first line must be "---"
            if isempty(lines) || strtrim(lines(1)) ~= "---"
                error("aisdk:skills:InvalidFrontmatter", ...
                    "SKILL.md missing YAML frontmatter: %s", skillPath);
            end

            % Closing delimiter: find the next "---" after line 1
            endIdx = 0;
            for i = 2:numel(lines)
                if strtrim(lines(i)) == "---"
                    endIdx = i;
                    break
                end
            end

            if endIdx == 0
                error("aisdk:skills:InvalidFrontmatter", ...
                    "SKILL.md frontmatter not closed: %s", skillPath);
            end

            % Parse key-value pairs from frontmatter lines.
            yamlLines = lines(2:endIdx-1);
            name = "";
            description = "";
            i = 1;
            while i <= numel(yamlLines)
                line = yamlLines(i);
                if startsWith(line, "name:")
                    [name, i] = this.parseYAMLValue(yamlLines, i, "name:");
                elseif startsWith(line, "description:")
                    [description, i] = this.parseYAMLValue(yamlLines, i, "description:");
                else
                    i = i + 1;
                end
            end

            if name == ""
                error("aisdk:skills:InvalidFrontmatter", ...
                    "SKILL.md missing required 'name' field: %s", skillPath);
            end
            if description == ""
                error("aisdk:skills:InvalidFrontmatter", ...
                    "SKILL.md missing required 'description' field: %s", skillPath);
            end
            if strlength(name) > 64 || isempty(regexp(name, "^[a-z0-9]+(-[a-z0-9]+)*$", "once"))
                error("aisdk:skills:InvalidFrontmatter", "%s", ...
                    aisdk.internal.MessageCatalog.getMessage( ...
                    "aisdk:skills:InvalidFrontmatterName", skillPath));
            end
            if strlength(description) > 1024
                error("aisdk:skills:InvalidFrontmatter", "%s", ...
                    aisdk.internal.MessageCatalog.getMessage( ...
                    "aisdk:skills:InvalidFrontmatterDescriptionLength", skillPath));
            end
        end

        function body = extractBody(~, content)
            % Opening "---" has no leading newline, so first \n---\n is the closing delimiter.
            closingDelimiter = newline + "---" + newline;
            body = strip(extractAfter(content, closingDelimiter), "left");
        end

        function buildCatalog(this)
        % Rebuilds CatalogText as a bullet list of skill names and descriptions.
            if isempty(this.Skills)
                this.CatalogText = "";
                return
            end
            % Flatten multiline descriptions so catalog stays one-line-per-skill.
            descriptions = replace([this.Skills.Description], newline, " ");
            lines = compose("- %s: %s", [this.Skills.Name]', descriptions');
            this.CatalogText = join(lines, newline);
        end
    end

    methods (Static, Access = private)
        function skillPaths = defaultDiscoverSkills(paths)
        % Finds SKILL.md files one or two levels below each search path.
            skillPaths = string.empty(1, 0);
            for path = paths
                if isfile(fullfile(path, "SKILL.md"))
                    aisdk.internal.throwError("aisdk:skills:SkillInRootDirectory", path);
                end
                for entry = dir(path)'
                    if ~entry.isdir || startsWith(entry.name, ".")
                        continue
                    end
                    candidate = fullfile(path, entry.name, "SKILL.md");
                    if isfile(candidate)
                        skillPaths(end+1) = string(candidate); %#ok<AGROW>
                    end
                    % One level deeper (category folder pattern)
                    for subEntry = dir(fullfile(path, entry.name))'
                        if ~subEntry.isdir || startsWith(subEntry.name, ".")
                            continue
                        end
                        candidate = fullfile(path, entry.name, subEntry.name, "SKILL.md");
                        if isfile(candidate)
                            skillPaths(end+1) = string(candidate); %#ok<AGROW>
                        end
                    end
                end
            end
        end

        function maxDatenum = defaultLastModified(paths)
        % Recursive max datenum across all paths; used by hasUpdated.
            maxDatenum = 0;
            for path = paths
                entries = dir(fullfile(path, '**'));
                if ~isempty(entries)
                    maxDatenum = max(maxDatenum, max([entries.datenum]));
                end
            end
        end
    end

    methods (Access = private)
        function [value, nextIdx] = parseYAMLValue(~, yamlLines, idx, key)
        % Parses a YAML scalar value supporting folded (>), literal (|), and plain continuation.
            raw = strtrim(extractAfter(yamlLines(idx), key));
            if raw == "|" || raw == "|-"
                joiner = newline;
                parts = string.empty(1, 0);
            elseif raw == ">" || raw == ">-"
                joiner = " ";
                parts = string.empty(1, 0);
            else
                joiner = " ";
                parts = raw;
            end
            nextIdx = idx + 1;
            while nextIdx <= numel(yamlLines) && startsWith(yamlLines(nextIdx), " ")
                parts(end+1) = strtrim(yamlLines(nextIdx)); %#ok<AGROW>
                nextIdx = nextIdx + 1;
            end
            value = join(parts, joiner);
        end
    end
end
