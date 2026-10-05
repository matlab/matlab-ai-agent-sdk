classdef tSkillRegistry < matlab.unittest.TestCase
% Tests for aisdk.internal.SkillRegistry.

%   Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        LiteralIndicator = {"|", "|-"}
        FoldedIndicator = {">", ">-"}
        ValidFrontmatter = struct( ...
            'nameAtLimit', struct('Name', string(repmat('a', 1, 64)), 'Description', "desc"), ...
            'descriptionAtLimit', struct('Name', "valid-skill", 'Description', string(repmat('d', 1, 1024))))
        InvalidFrontmatter = struct( ...
            'nameTooLong', struct('Name', string(repmat('a', 1, 65)), 'Description', "desc"), ...
            'uppercaseName', struct('Name', "Invalid", 'Description', "desc"), ...
            'leadingHyphen', struct('Name', "-invalid", 'Description', "desc"), ...
            'trailingHyphen', struct('Name', "invalid-", 'Description', "desc"), ...
            'consecutiveHyphens', struct('Name', "invalid--name", 'Description', "desc"), ...
            'descriptionTooLong', struct('Name', "valid-skill", 'Description', string(repmat('d', 1, 1025))))
    end

    methods (Test, TestTags = {'Unit'})

        %% Scanning / pre-loading

        function scan_singleSkillPath_populatesSkillsWithNameAndBody(testCase)
            reg = testCase.createRegistry();
            testCase.verifyEqual([reg.Skills.Name], "valid-skill");
            testCase.verifyEqual(reg.Skills(1).Body, "Body of valid-skill.");
        end

        function scan_multiplePaths_aggregatesAllSkills(testCase)
            paths = ["/path1/skill-a/SKILL.md", "/path2/skill-b/SKILL.md"];
            contents = dictionary(paths, ...
                [sprintf("---\nname: skill-a\ndescription: Skill A\n---\nBody A"), ...
                 sprintf("---\nname: skill-b\ndescription: Skill B\n---\nBody B")]);
            discoverFcn = @(~) paths;
            fileReadFcn = @(p) contents(string(p));
            reg = testCase.createRegistryWith(discoverFcn, fileReadFcn);
            testCase.verifyEqual(sort([reg.Skills.Name]), sort(["skill-a", "skill-b"]));
        end

        function scan_skillWithSiblingFiles_preloadsResourcesUpToOneSubfolder(testCase)
            tmpDir = testCase.createTemporaryFolder();
            skillDir = fullfile(tmpDir, "my-skill");
            mkdir(skillDir);
            refsDir = fullfile(skillDir, "references");
            mkdir(refsDir);
            deepDir = fullfile(refsDir, "sub");
            mkdir(deepDir);

            writelines(["---"; "name: my-skill"; "description: desc"; "---"; "Body"], fullfile(skillDir, "SKILL.md"));
            writelines("example content", fullfile(skillDir, "example.m"));
            writelines("guide content", fullfile(refsDir, "guide.md"));
            writelines("deep content", fullfile(deepDir, "deep.md"));

            reg = aisdk.internal.SkillRegistry(tmpDir);
            skill = reg.Skills(1);
            testCase.verifyTrue(isKey(skill.Resources, "references/guide.md"));
            testCase.verifyTrue(isKey(skill.Resources, "example.m"));
            testCase.verifyFalse(isKey(skill.Resources, "references/sub/deep.md"));
        end


        function scan_skillWithDotfile_excludesDotfileFromResources(testCase)
            tmpDir = testCase.createTemporaryFolder();
            skillDir = fullfile(tmpDir, "my-skill");
            mkdir(skillDir);

            writelines(["---"; "name: my-skill"; "description: desc"; "---"; "Body"], fullfile(skillDir, "SKILL.md"));
            writelines("SECRET=abc123", fullfile(skillDir, ".env"));
            writelines("readme content", fullfile(skillDir, "readme.txt"));

            reg = aisdk.internal.SkillRegistry(tmpDir);
            skill = reg.Skills(1);
            testCase.verifyTrue(isKey(skill.Resources, "readme.txt"));
            testCase.verifyFalse(isKey(skill.Resources, ".env"));
        end

        function loadSkillImpl_dotfileInSubfolder_throwsResourceNotFound(testCase)
            tmpDir = testCase.createTemporaryFolder();
            skillDir = fullfile(tmpDir, "my-skill");
            refsDir = fullfile(skillDir, "references");
            mkdir(refsDir);

            writelines(["---"; "name: my-skill"; "description: desc"; "---"; "Body"], fullfile(skillDir, "SKILL.md"));
            writelines("secret content", fullfile(refsDir, ".secret"));
            writelines("guide content", fullfile(refsDir, "guide.md"));

            reg = aisdk.internal.SkillRegistry(tmpDir);
            testCase.verifySubstring(reg.loadSkillImpl("my-skill/references/guide.md"), "guide content");
            testCase.verifyError(@() reg.loadSkillImpl("my-skill/references/.secret"), ...
                "aisdk:skills:ResourceNotFound");
        end

        function scan_nestedCategoryStructure_discoversSkillsAtDepthTwo(testCase)
            tmpDir = testCase.createTemporaryFolder();
            categoryDir = fullfile(tmpDir, "matlab-core");
            mkdir(fullfile(categoryDir, "skill-a"));
            mkdir(fullfile(categoryDir, "skill-b"));
            writelines(["---"; "name: skill-a"; "description: A"; "---"; "Body A"], ...
                fullfile(categoryDir, "skill-a", "SKILL.md"));
            writelines(["---"; "name: skill-b"; "description: B"; "---"; "Body B"], ...
                fullfile(categoryDir, "skill-b", "SKILL.md"));

            reg = aisdk.internal.SkillRegistry(tmpDir);
            testCase.verifyEqual(sort([reg.Skills.Name]), sort(["skill-a", "skill-b"]));
        end

        function scan_mixedFlatAndNested_discoversAll(testCase)
            tmpDir = testCase.createTemporaryFolder();
            mkdir(fullfile(tmpDir, "flat-skill"));
            writelines(["---"; "name: flat-skill"; "description: flat"; "---"; "Body"], ...
                fullfile(tmpDir, "flat-skill", "SKILL.md"));
            categoryDir = fullfile(tmpDir, "category");
            mkdir(fullfile(categoryDir, "nested-skill"));
            writelines(["---"; "name: nested-skill"; "description: nested"; "---"; "Body"], ...
                fullfile(categoryDir, "nested-skill", "SKILL.md"));

            reg = aisdk.internal.SkillRegistry(tmpDir);
            testCase.verifyEqual(sort([reg.Skills.Name]), sort(["flat-skill", "nested-skill"]));
        end

        function scan_nestedWithDotfolder_skipsDotfolder(testCase)
            tmpDir = testCase.createTemporaryFolder();
            dotDir = fullfile(tmpDir, ".git", "hooks");
            mkdir(dotDir);
            writelines(["---"; "name: hooks"; "description: bad"; "---"; "Body"], ...
                fullfile(dotDir, "SKILL.md"));
            categoryDir = fullfile(tmpDir, "category");
            mkdir(fullfile(categoryDir, "real-skill"));
            writelines(["---"; "name: real-skill"; "description: good"; "---"; "Body"], ...
                fullfile(categoryDir, "real-skill", "SKILL.md"));

            reg = aisdk.internal.SkillRegistry(tmpDir);
            testCase.verifyEqual([reg.Skills.Name], "real-skill");
        end

        function scan_skillWithNoSiblingFiles_hasEmptyResources(testCase)
            discoverFcn = @(~) "/path/lonely/SKILL.md";
            fileReadFcn = @(~) sprintf("---\nname: lonely\ndescription: alone\n---\nBody");
            reg = testCase.createRegistryWith(discoverFcn, fileReadFcn);
            testCase.verifyEqual(reg.Skills(1).Resources, dictionary);
        end

        function scan_windowsLineEndings_parsesBodyCorrectly(testCase)
            discoverFcn = @(~) "/path/crlf-skill/SKILL.md";
            fileReadFcn = @(~) sprintf("---\r\nname: crlf-skill\r\ndescription: CRLF\r\n---\r\nBody with CRLF");
            reg = testCase.createRegistryWith(discoverFcn, fileReadFcn);
            testCase.verifyEqual(reg.Skills(1).Body, "Body with CRLF");
        end

        function scan_bomPrefixedContent_parsesCorrectly(testCase)
            bom = char(65279);
            discoverFcn = @(~) "/path/bom-skill/SKILL.md";
            fileReadFcn = @(~) bom + sprintf("---\nname: bom-skill\ndescription: BOM test\n---\nBody after BOM");
            reg = testCase.createRegistryWith(discoverFcn, fileReadFcn);
            testCase.verifyEqual(reg.Skills(1).Name, "bom-skill");
            testCase.verifyEqual(reg.Skills(1).Body, "Body after BOM");
        end

        %% Construction errors

        function construct_pathDoesNotExist_throwsDirectoryNotFound(testCase)
            testCase.verifyError( ...
                @() aisdk.internal.SkillRegistry("/nonexistent/path"), ...
                "aisdk:skills:DirectoryNotFound");
        end

        function construct_missingNameField_throwsInvalidFrontmatter(testCase)
            discoverFcn = @(~) "/path/bad/SKILL.md";
            fileReadFcn = @(~) sprintf("---\ndescription: no name\n---\nBody");
            testCase.verifyError( ...
                @() testCase.createRegistryWith(discoverFcn, fileReadFcn), ...
                "aisdk:skills:InvalidFrontmatter");
        end

        function construct_missingDescriptionField_throwsInvalidFrontmatter(testCase)
            discoverFcn = @(~) "/path/bad/SKILL.md";
            fileReadFcn = @(~) sprintf("---\nname: x\n---\nBody");
            testCase.verifyError( ...
                @() testCase.createRegistryWith(discoverFcn, fileReadFcn), ...
                "aisdk:skills:InvalidFrontmatter");
        end

        function construct_validNameAndDescriptionLimits_registersSkill(testCase, ValidFrontmatter)
            input = ValidFrontmatter;
            skillPath = "/path/" + input.Name + "/SKILL.md";
            content = "---" + newline + "name: " + input.Name + newline + ...
                "description: " + input.Description + newline + "---" + newline + "Body";

            reg = testCase.createRegistryWith(@(~) skillPath, @(~) content);

            testCase.verifyEqual([reg.Skills.Name, reg.Skills.Description], ...
                [input.Name, input.Description]);
        end

        function construct_invalidNameOrDescription_throwsInvalidFrontmatter(testCase, InvalidFrontmatter)
            input = InvalidFrontmatter;
            skillPath = "/path/" + input.Name + "/SKILL.md";
            content = "---" + newline + "name: " + input.Name + newline + ...
                "description: " + input.Description + newline + "---" + newline + "Body";

            testCase.verifyError( ...
                @() testCase.createRegistryWith(@(~) skillPath, @(~) content), ...
                "aisdk:skills:InvalidFrontmatter");
        end

        function construct_unclosedFrontmatter_throwsInvalidFrontmatter(testCase)
            discoverFcn = @(~) "/path/bad/SKILL.md";
            fileReadFcn = @(~) sprintf("---\nname: x\ndescription: y\n");
            testCase.verifyError( ...
                @() testCase.createRegistryWith(discoverFcn, fileReadFcn), ...
                "aisdk:skills:InvalidFrontmatter");
        end

        function construct_noFrontmatter_throwsInvalidFrontmatter(testCase)
            discoverFcn = @(~) "/path/bad/SKILL.md";
            fileReadFcn = @(~) "No frontmatter here";
            testCase.verifyError( ...
                @() testCase.createRegistryWith(discoverFcn, fileReadFcn), ...
                "aisdk:skills:InvalidFrontmatter");
        end

        function construct_duplicateSkillNames_throwsDuplicateSkillName(testCase)
            discoverFcn = @(~) ["/path/same-name/SKILL.md", "/path2/same-name/SKILL.md"];
            fileReadFcn = @(~) sprintf("---\nname: same-name\ndescription: desc\n---\nBody");
            testCase.verifyError( ...
                @() testCase.createRegistryWith(discoverFcn, fileReadFcn), ...
                "aisdk:skills:DuplicateSkillName");
        end

        function scan_nameMismatchesFolderName_errors(testCase)
            discoverFcn = @(~) "/path/wrong-folder/SKILL.md";
            fileReadFcn = @(~) sprintf("---\nname: right-name\ndescription: desc\n---\nBody");
            testCase.verifyError( ...
                @() testCase.createRegistryWith(discoverFcn, fileReadFcn), ...
                "aisdk:skills:NameFolderMismatch");
        end

        function defaultDiscover_skillMdInRoot_errors(testCase)
            tmpDir = testCase.createTemporaryFolder();
            writelines(["---"; "name: root-skill"; "description: bad"; "---"; "Body"], ...
                fullfile(tmpDir, "SKILL.md"));
            testCase.verifyError( ...
                @() aisdk.internal.SkillRegistry(tmpDir), ...
                "aisdk:skills:SkillInRootDirectory");
        end

        function defaultDiscover_mixedDepthsUnderSameParent_findsBoth(testCase)
            tmpDir = testCase.createTemporaryFolder();
            mkdir(fullfile(tmpDir, "foo"));
            mkdir(fullfile(tmpDir, "foo", "bar"));
            writelines(["---"; "name: foo"; "description: depth one"; "---"; "Body"], ...
                fullfile(tmpDir, "foo", "SKILL.md"));
            writelines(["---"; "name: bar"; "description: depth two"; "---"; "Body"], ...
                fullfile(tmpDir, "foo", "bar", "SKILL.md"));
            reg = aisdk.internal.SkillRegistry(tmpDir);
            testCase.verifyEqual(numel(reg.Skills), 2);
            testCase.verifyTrue(all(ismember(["foo", "bar"], [reg.Skills.Name])));
        end

        %% Multiline frontmatter

        function parseFrontmatter_foldedDescription_joinsWithSpace(testCase, FoldedIndicator)
            discoverFcn = @(~) "/path/my-skill/SKILL.md";
            fileReadFcn = @(~) sprintf("---\nname: my-skill\ndescription: %s\n  line one.\n  line two.\n---\nBody", FoldedIndicator);
            reg = testCase.createRegistryWith(discoverFcn, fileReadFcn);
            testCase.verifyEqual(reg.Skills(1).Description, "line one. line two.");
        end

        function parseFrontmatter_literalDescription_joinsWithNewline(testCase, LiteralIndicator)
            discoverFcn = @(~) "/path/my-skill/SKILL.md";
            fileReadFcn = @(~) sprintf("---\nname: my-skill\ndescription: %s\n  line one.\n  line two.\n---\nBody", LiteralIndicator);
            reg = testCase.createRegistryWith(discoverFcn, fileReadFcn);
            testCase.verifyEqual(reg.Skills(1).Description, "line one." + newline + "line two.");
        end

        function parseFrontmatter_inlineDescription_remainsSingleLine(testCase)
            discoverFcn = @(~) "/path/my-skill/SKILL.md";
            fileReadFcn = @(~) sprintf("---\nname: my-skill\ndescription: A short desc\n---\nBody");
            reg = testCase.createRegistryWith(discoverFcn, fileReadFcn);
            testCase.verifyEqual(reg.Skills(1).Description, "A short desc");
        end

        function parseFrontmatter_foldedDescriptionFollowedByKey_stopsAtNextKey(testCase)
            discoverFcn = @(~) "/path/my-skill/SKILL.md";
            fileReadFcn = @(~) sprintf("---\nname: my-skill\ndescription: >\n  multi\n  line\nlicense: MIT\n---\nBody");
            reg = testCase.createRegistryWith(discoverFcn, fileReadFcn);
            testCase.verifyEqual(reg.Skills(1).Description, "multi line");
        end

        function parseFrontmatter_plainContinuation_joinsWithSpace(testCase)
            discoverFcn = @(~) "/path/my-skill/SKILL.md";
            fileReadFcn = @(~) sprintf("---\nname: my-skill\ndescription: This is a long\n  description that continues\n---\nBody");
            reg = testCase.createRegistryWith(discoverFcn, fileReadFcn);
            testCase.verifyEqual(reg.Skills(1).Description, "This is a long description that continues");
        end

        function parseFrontmatter_nestedKeysAfterDescription_ignoredCleanly(testCase)
            discoverFcn = @(~) "/path/my-skill/SKILL.md";
            fileReadFcn = @(~) sprintf(join([ ...
                "---", "name: my-skill", "description: A short description", ...
                "license: https://example.com", "metadata:", "  author: MathWorks", ...
                "  version: ""1.4""", "allowed-tools:", "  - Read", "  - Write", ...
                "---", "Body"], "\n"));
            reg = testCase.createRegistryWith(discoverFcn, fileReadFcn);
            testCase.verifyEqual(reg.Skills(1).Description, "A short description");
        end

        %% Catalog

        function catalogText_containsEachSkillNameAndDescription(testCase)
            reg = testCase.createRegistry();
            testCase.verifySubstring(reg.CatalogText, "valid-skill");
            testCase.verifySubstring(reg.CatalogText, "A valid test skill");
        end

        function catalogText_excludesSkillBody(testCase)
            reg = testCase.createRegistry();
            testCase.verifyThat(reg.CatalogText, ...
                ~matlab.unittest.constraints.ContainsSubstring("Body of valid-skill."));
        end

        function catalogText_literalDescription_rendersAsSingleLine(testCase)
            discoverFcn = @(~) "/path/multi-skill/SKILL.md";
            fileReadFcn = @(~) sprintf("---\nname: multi-skill\ndescription: |\n  Line one.\n  Line two.\n---\nBody");
            reg = testCase.createRegistryWith(discoverFcn, fileReadFcn);
            testCase.verifyThat(reg.CatalogText, ...
                ~matlab.unittest.constraints.ContainsSubstring(newline + "Line two."));
            testCase.verifySubstring(reg.CatalogText, "Line one. Line two.");
        end

        %% Empty registry

        function scan_noSkillsDiscovered_hasEmptyCatalog(testCase)
            discoverFcn = @(~) string.empty(1, 0);
            fileReadFcn = @(~) "";
            reg = testCase.createRegistryWith(discoverFcn, fileReadFcn);
            testCase.verifyEqual(reg.CatalogText, "");
            testCase.verifyEmpty(reg.Skills);
        end

        function loadSkillImpl_emptyRegistry_throwsSkillNotFound(testCase)
            discoverFcn = @(~) string.empty(1, 0);
            fileReadFcn = @(~) "";
            reg = testCase.createRegistryWith(discoverFcn, fileReadFcn);
            testCase.verifyError( ...
                @() reg.loadSkillImpl("anything"), ...
                "aisdk:skills:SkillNotFound");
        end

        %% loadSkillImpl -- dispatch

        function loadSkillImpl_nameOnly_returnsBody(testCase)
            reg = testCase.createRegistry();
            result = reg.loadSkillImpl("valid-skill");
            testCase.verifyEqual(result, "Body of valid-skill.");
        end

        function loadSkillImpl_namePlusRelPath_returnsResourceContent(testCase)
            reg = testCase.createRegistryWithResource();
            result = reg.loadSkillImpl("res-skill/references/guide.md");
            testCase.verifySubstring(result, "guide content");
        end

        function loadSkillImpl_backslashPath_normalizesToForwardSlash(testCase)
            reg = testCase.createRegistryWithResource();
            result = reg.loadSkillImpl("res-skill\references\guide.md");
            testCase.verifySubstring(result, "guide content");
        end


        %% loadSkillImpl -- unhappy path

        function loadSkillImpl_unknownSkillName_throwsSkillNotFound(testCase)
            reg = testCase.createRegistry();
            testCase.verifyError( ...
                @() reg.loadSkillImpl("nonexistent"), ...
                "aisdk:skills:SkillNotFound");
        end

        function loadSkillImpl_unknownResourceKey_throwsResourceNotFound(testCase)
            reg = testCase.createRegistryWithResource();
            testCase.verifyError( ...
                @() reg.loadSkillImpl("res-skill/bad/path.md"), ...
                "aisdk:skills:ResourceNotFound");
        end

        function buildResourceNotFoundMessage_manyResources_omitsResourceList(testCase)
            keys = "a.m" + (1:6);
            values = "content" + (1:6);
            resources = dictionary(keys, values);
            skill = aisdk.internal.Skill("big-skill", "desc", "/path", "body", resources);
            reg = testCase.createRegistry();
            msg = reg.buildResourceNotFoundMessage("nonexistent.m", skill);
            testCase.verifySubstring(msg, "nonexistent.m");
            testCase.verifyThat(msg, ...
                ~matlab.unittest.constraints.ContainsSubstring("a.m1"));
        end

        function buildResourceNotFoundMessage_fewResources_includesResourceList(testCase)
            resources = dictionary("guide.md", "content");
            skill = aisdk.internal.Skill("small-skill", "desc", "/path", "body", resources);
            reg = testCase.createRegistry();
            msg = reg.buildResourceNotFoundMessage("bad.md", skill);
            testCase.verifySubstring(msg, "guide.md");
        end

        function buildSkillNotFoundMessage_manySkills_omitsSkillList(testCase)
            % Matches the resource-list behaviour: past the cap, omit the list
            % rather than show a partial one the model could read as complete.
            reg = testCase.createRegistryWithManySkills(6);
            msg = reg.buildSkillNotFoundMessage("nonexistent");
            testCase.verifySubstring(msg, "nonexistent");
            testCase.verifyThat(msg, ...
                ~matlab.unittest.constraints.ContainsSubstring("skill1"));
        end

        function buildSkillNotFoundMessage_fewSkills_includesSkillList(testCase)
            reg = testCase.createRegistryWithManySkills(5);
            msg = reg.buildSkillNotFoundMessage("nonexistent");
            testCase.verifySubstring(msg, "skill1");
        end

        %% isStale / scan -- coherence

        function isStale_lastModifiedUnchanged_returnsFalse(testCase)
            fixedTimestamp = 100;
            lastModFcn = @(~) fixedTimestamp;
            reg = testCase.createRegistryWithLastMod(lastModFcn);
            testCase.verifyFalse(reg.isStale());
        end

        function isStale_lastModifiedChanged_returnsTrue(testCase)
            counter = containers.Map('KeyType', 'char', 'ValueType', 'double');
            counter('n') = 0;
            lastModFcn = @(~) testCase.advancingTimestamp(counter);
            reg = testCase.createRegistryWithLastMod(lastModFcn);
            testCase.verifyTrue(reg.isStale());
        end

        function scan_afterStale_rebuildsSkills(testCase)
            callCount = containers.Map('KeyType', 'char', 'ValueType', 'double');
            callCount('n') = 0;
            discoverFcn = @(~) testCase.discoverMoreOnRescan(callCount);
            readMap = containers.Map({ ...
                '/path/skill-a/SKILL.md', ...
                '/path/skill-b/SKILL.md'}, { ...
                sprintf('---\nname: skill-a\ndescription: A\n---\nBody A'), ...
                sprintf('---\nname: skill-b\ndescription: B\n---\nBody B')});
            fileReadFcn = @(p) readMap(char(p));
            timestampCounter = containers.Map('KeyType', 'char', 'ValueType', 'double');
            timestampCounter('n') = 0;
            lastModFcn = @(~) testCase.advancingTimestamp(timestampCounter);

            reg = aisdk.internal.SkillRegistry(pwd, ...
                DiscoverSkillsFcn=discoverFcn, FileReadFcn=fileReadFcn, LastModifiedFcn=lastModFcn);
            testCase.verifyEqual(numel(reg.Skills), 1);
            testCase.verifyTrue(reg.isStale());
            reg.scan();
            testCase.verifyEqual(numel(reg.Skills), 2);
        end
    end

    methods (Test, TestTags = {'Integration'})

        function scan_fileURIPath_discoversSkills(testCase)
            tmpDir = testCase.createTemporaryFolder();
            skillDir = fullfile(tmpDir, "uri-skill");
            mkdir(skillDir);
            fid = fopen(fullfile(skillDir, "SKILL.md"), "w");
            fprintf(fid, "---\nname: uri-skill\ndescription: File URI test\n---\nURI body");
            fclose(fid);

            fileURI = "file:///" + strrep(tmpDir, "\", "/");
            reg = aisdk.internal.SkillRegistry(fileURI);
            result = reg.loadSkillImpl("uri-skill");
            testCase.verifyEqual(result, "URI body");
        end

    end

    methods (Access = private)
        function reg = createRegistry(testCase) %#ok<MANU>
            discoverFcn = @(~) "/path/valid-skill/SKILL.md";
            fileReadFcn = @(~) sprintf("---\nname: valid-skill\ndescription: A valid test skill\n---\nBody of valid-skill.");
            reg = aisdk.internal.SkillRegistry(pwd, ...
                DiscoverSkillsFcn=discoverFcn, FileReadFcn=fileReadFcn, LastModifiedFcn=@(~) 1);
        end

        function reg = createRegistryWithManySkills(testCase, count)
            names = "skill" + (1:count);
            paths = "/path/" + names + "/SKILL.md";
            contents = dictionary(paths, ...
                "---" + newline + "name: " + names + newline + ...
                "description: D" + newline + "---" + newline + "Body");
            reg = testCase.createRegistryWith(@(~) paths, @(p) contents(string(p)));
        end

        function reg = createRegistryWith(testCase, discoverFcn, fileReadFcn) %#ok<INUSL>
            reg = aisdk.internal.SkillRegistry(pwd, ...
                DiscoverSkillsFcn=discoverFcn, FileReadFcn=fileReadFcn, LastModifiedFcn=@(~) 1);
        end

        function reg = createRegistryWithResource(testCase)
            tmpDir = testCase.createTemporaryFolder();
            skillDir = fullfile(tmpDir, "res-skill");
            mkdir(skillDir);
            refsDir = fullfile(skillDir, "references");
            mkdir(refsDir);
            writelines(["---"; "name: res-skill"; "description: has resources"; "---"; "Body of res-skill."], ...
                fullfile(skillDir, "SKILL.md"));
            writelines("guide content", fullfile(refsDir, "guide.md"));
            reg = aisdk.internal.SkillRegistry(tmpDir);
        end

        function reg = createRegistryWithLastMod(testCase, lastModFcn) %#ok<INUSL>
            discoverFcn = @(~) "/path/skill/SKILL.md";
            fileReadFcn = @(~) sprintf("---\nname: skill\ndescription: d\n---\nBody");
            reg = aisdk.internal.SkillRegistry(pwd, ...
                DiscoverSkillsFcn=discoverFcn, FileReadFcn=fileReadFcn, LastModifiedFcn=lastModFcn);
        end


        function skillPaths = discoverMoreOnRescan(~, counter)
            counter('n') = counter('n') + 1;
            if counter('n') <= 1
                skillPaths = "/path/skill-a/SKILL.md";
            else
                skillPaths = ["/path/skill-a/SKILL.md", "/path/skill-b/SKILL.md"];
            end
        end

        function val = advancingTimestamp(~, counter)
            counter('n') = counter('n') + 1;
            val = counter('n');
        end
    end
end
