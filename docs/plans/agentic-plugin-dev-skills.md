# Plan: `agentic-plugin-dev` Plugin — Create & Manage Plugins

## Context

The agentics marketplace has plugins for reviewing skills (`skill-reviewer`), creating agents (`agent-creator`), and scaffolding marketplace infrastructure (`marketplace-builder`), but nothing for the **plugin-level workflow** itself — creating a new plugin from scratch, managing marketplace entries, or validating plugin structure against the official spec. This plugin fills that gap.

## Decisions

- **Self-contained templates** — no cross-plugin dependencies on skill-reviewer or agent-creator
- **Single plugin validation only** — no batch mode
- **Skills only** — no explicit commands; users invoke via natural language
- **Static templates with optional live fetch** — default to embedded references, offer "use latest docs" mode fetching from `code.claude.com`
- **Separate reference files per skill** — no shared schema files; each skill fully self-contained
- **CWD-only marketplace search** — `plugin-manager` checks CWD only, prompts user for path if not found
- **Suggest commit message only** — version bumps suggest conventional commit format but do not touch git
- **Explicit disambiguation** — when user intent overlaps with skill-reviewer, agent-creator, or marketplace-builder, ask which scope they mean
- **CHANGELOG format** — use [Keep a Changelog](https://keepachangelog.com/) conventions
- **Lean references for v1.0** — concise checklists (field + required/optional + constraint), not comprehensive docs

## File Tree

```
plugins/agentic-plugin-dev/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── plugin-creator/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── plugin-json-schema.md
│   │       └── component-templates.md
│   ├── plugin-manager/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── marketplace-schema.md
│   └── plugin-validator/
│       ├── SKILL.md
│       └── references/
│           └── validation-rules.md
├── CHANGELOG.md
└── README.md
```

**Total: 11 files** + 1 edit to `.claude-plugin/marketplace.json`

## Implementation Steps

### 1. Create plugin manifest

**File:** `plugins/agentic-plugin-dev/.claude-plugin/plugin.json`

- `name`: `"agentic-plugin-dev"`
- No `version` field (relative-path convention)
- Keywords: `plugin-authoring`, `scaffolding`, `validation`, `marketplace`, `plugin-management`
- Homepage: `https://github.com/shawn-sandy/agentics/tree/main/plugins/agentic-plugin-dev`

### 2. Create `plugin-creator` skill

**File:** `plugins/agentic-plugin-dev/skills/plugin-creator/SKILL.md`

- Sequential pattern, rigid freedom level
- **Step 0** — Disambiguation check: if user intent is ambiguous (e.g., "scaffold something", "create a skill"), ask whether they mean a full plugin or just a component (redirect to skill-reviewer or agent-creator if appropriate)
- **Step 1** — Gather requirements via AskUserQuestion: name, description, components wanted (commands, skills, agents, hooks, MCP)
- **Step 2** — Gather component details: names, descriptions, design patterns for skills, argument hints for commands
- **Step 3** — Generate `plugin.json` (no version field), show for confirmation
- **Step 4** — Show full file list for confirmation, then write files sequentially: `.claude-plugin/plugin.json`, starter SKILL.md/COMMAND.md/agent/hooks.json/.mcp.json files, `CHANGELOG.md`. If any write fails, report which succeeded and which failed
- **Step 5** — Offer to register in `marketplace.json` if one exists at project root. Before registering: confirm the marketplace name matches user's intent AND check for duplicate plugin names
- Scope: scaffolds entire plugins. Does NOT scaffold individual skills (use skill-reviewer) or agents (use agent-creator)
- Undo guidance: inform user they can remove the generated directory or `git checkout` to revert

**Reference:** `references/plugin-json-schema.md` — lean checklist: field name + required/optional + constraint. Include optional live fetch from `code.claude.com/docs/en/plugins-reference`
**Reference:** `references/component-templates.md` — starter templates for SKILL.md, COMMAND.md, agent.md, hooks.json, .mcp.json

### 3. Create `plugin-manager` skill

**File:** `plugins/agentic-plugin-dev/skills/plugin-manager/SKILL.md`

- Adaptive pattern, flexible freedom level
- **Step 0** — Disambiguation: if user intent overlaps with marketplace-builder (e.g., "set up a marketplace"), ask which scope they mean
- **Step 1** — Locate `marketplace.json` in CWD only. If not found, ask user for the path. Do NOT traverse parent directories
- **Step 2** — Determine operation from user intent:
  - **List** — table of all plugins with name, version, category
  - **Add** — new entry with name, source, version, description, category, tags. Validate name uniqueness before adding
  - **Remove** — confirm and delete entry by name
  - **Update** — modify fields on existing entry
  - **Bump version** — patch/minor/major increment, update CHANGELOG.md (Keep a Changelog format), suggest conventional commit message. Do NOT stage or commit — suggest message only
- **Step 3** — Validate JSON after any write operation
- Scope: manages entries in existing `marketplace.json`. Does NOT create marketplace infrastructure (use marketplace-builder). Does NOT touch git

**Reference:** `references/marketplace-schema.md` — lean checklist: marketplace.json fields + required/optional + constraints, standard categories, semver bump triggers. Include optional live fetch from `code.claude.com/docs/en/plugin-marketplaces`

### 4. Create `plugin-validator` skill

**File:** `plugins/agentic-plugin-dev/skills/plugin-validator/SKILL.md`

- Sequential pattern, rigid freedom level
- **Step 1** — Resolve target plugin path
- **Step 2** — Structural scan: inventory `.claude-plugin/plugin.json`, `commands/`, `skills/`, `agents/`, `hooks/`; flag components incorrectly inside `.claude-plugin/`
- **Step 3** — Manifest validation: name exists + kebab-case, description present, no version conflict. When a `marketplace.json` exists, cross-check that the plugin's source path resolves to the validated directory
- **Step 4** — Component validation: SKILL.md frontmatter, COMMAND.md frontmatter, agent frontmatter, naming conventions
- **Step 5** — Present report table with PASS/FAIL + severity (ERROR, WARNING, INFO)
- Scope: validates structure against spec. Does NOT review skill quality (use skill-reviewer)

**Reference:** `references/validation-rules.md` — lean checklist: rule ID + check + severity + fix guidance. Include optional live fetch from `code.claude.com/docs/en/plugins-reference`

### 5. Create CHANGELOG.md

**File:** `plugins/agentic-plugin-dev/CHANGELOG.md`

- Use [Keep a Changelog](https://keepachangelog.com/) format
- Initial `v1.0.0` entry under `### Added` listing all three skills

### 6. Create README.md

**File:** `plugins/agentic-plugin-dev/README.md`

- Overview, features, installation, usage examples, related plugins

### 7. Register in marketplace.json

**Edit:** `.claude-plugin/marketplace.json`

- Add entry: name `agentic-plugin-dev`, version `1.0.0`, category `development`
- Tags: `plugin-authoring`, `scaffolding`, `validation`, `marketplace`, `plugin-management`, `claude-code`

## Key Files to Reference During Implementation

| File | Purpose |
|------|---------|
| `plugins/agent-creator/skills/generating-agents/SKILL.md` | Best example of multi-step scaffolding skill |
| `plugins/skill-reviewer/skills/reviewing-skills/SKILL.md` | Pattern for audit/validation skills |
| `plugins/marketplace-builder/skills/building-marketplaces/SKILL.md` | Marketplace-aware skill pattern |
| `.claude/rules/marketplace.md` | Version bump rules and categories |
| `.claude-plugin/marketplace.json` | Current marketplace entries |

## Verification

1. Load plugin locally: `claude --plugin-dir ./plugins/agentic-plugin-dev`
2. Test `plugin-creator`: say "create a new plugin called test-plugin" — verify directory structure is generated correctly
3. Test `plugin-creator` disambiguation: say "scaffold a skill" — verify it asks whether you mean a full plugin or just a skill component
4. Test `plugin-manager`: say "list all marketplace plugins" — verify formatted output
5. Test `plugin-manager`: say "bump hello-world version" — verify marketplace.json update, CHANGELOG entry in Keep a Changelog format, and suggested commit message (no git operations)
6. Test `plugin-validator`: say "validate the hello-world plugin" — verify report output including marketplace source path cross-check
7. Test activation overlap: say "scaffold something" — verify disambiguation prompt appears
8. Run `/reload-plugins` between tests to pick up changes

## Next Steps (out of scope)

- Add a `plugin-tester` skill that loads a plugin and verifies activation end-to-end
- Add test fixtures under `tests/fixtures/` for validation edge cases
- Add a hook that auto-validates `plugin.json` on save
- Consider batch validation mode for CI pipelines

## Interview Summary

### Key Decisions Confirmed

1. **Static templates with optional live fetch** — default to embedded templates in reference files, offer a "use latest docs" mode that fetches from `code.claude.com` (matching `skill-reviewer`'s pattern)
2. **Separate reference files per skill** — no shared schema files; each skill is fully self-contained
3. **CWD-only marketplace search, then ask** — `plugin-manager` checks CWD only, prompts user for path if not found
4. **Both marketplace identity and name collision checks** — plugin-creator confirms the marketplace name AND checks for duplicate plugin names before registering
5. **Cross-check source paths** — plugin-validator verifies marketplace.json source paths resolve to the validated plugin directory
6. **Sequential file writes with upfront confirmation** — plugin-creator shows the full file list, writes one-by-one, reports partial failures
7. **Suggest commit message only** — plugin-manager suggests conventional commit format after version bumps but does not touch git
8. **Add explicit disambiguation** — when user intent overlaps with skill-reviewer, agent-creator, or marketplace-builder, ask which scope they mean

### Open Risks & Concerns

1. **Hook/MCP template depth** — the plan lists hooks and MCP servers as scaffoldable components but doesn't specify starter templates for `hooks.json` or `.mcp.json` schemas
2. **CHANGELOG format unspecified** — no standard format chosen for changelogs across plugins
3. **Validation rules will drift** — static validation rules have no mechanism to detect when the official spec changes
4. **Reference file volume** — 4 reference files across 3 skills may be more documentation than needed for v1.0; consider leaner initial versions
5. **No undo guidance** — plugin-creator writes many files with no documented rollback path

### Recommended Next Steps

1. **Amend the plan** to specify the CHANGELOG format (suggest Keep a Changelog) and add starter hook/MCP templates to `component-templates.md`
2. **Amend plugin-creator Step 1** to include a disambiguation check: if user says something ambiguous like "scaffold a skill", ask whether they mean a full plugin or just a skill component
3. **Amend plugin-validator Step 3** to include marketplace source path cross-checking when a marketplace.json is present
4. **Amend plugin-manager** to clarify CWD-only search and document the "suggest commit message only" boundary
5. **Start reference files lean** — include only the rules and schemas needed for v1.0, with a note that live fetch can supplement

### Simplification Opportunities

- **Lean reference files for v1.0**: Rather than comprehensive schema documentation in 4 reference files, start with concise checklists (field name + required/optional + constraint). Expand to full documentation only if the lean versions prove insufficient during testing.
