---
status: completed
type: standard
created: 2026-03-06
modified: 2026-03-08
---

# Plan: Add `marketplace-builder` Plugin

## Context

Developers wanting to build their own Claude Code skill marketplace have no structured guidance. They need to:
- Evaluate what their repository already has
- Understand what's missing for marketplace functionality
- Scaffold the required infrastructure (`.claude-plugin/marketplace.json`, plugin directories, SKILL.md templates)

This plugin fills that gap. It evaluates a repository's current state, scores it across 5 marketplace-readiness dimensions, then **generates the missing pieces** — turning any repo into a functioning skill marketplace.

Follows the "Audit + Scaffold" pattern proven by `claude-md-optimizer` and `skill-reviewer`. Informed by:
- Anthropic's official skill best practices guide
- "The Complete Guide to Building Skills for Claude" PDF
- Official marketplace docs: https://code.claude.com/docs/en/plugin-marketplaces

---

## Files to Create (7 new) + Modify (1 existing)

| # | File | Purpose |
|---|------|---------|
| 1 | `plugins/marketplace-builder/.claude-plugin/plugin.json` | Plugin manifest (v1.0.0) |
| 2 | `plugins/marketplace-builder/skills/building-marketplaces/SKILL.md` | Core skill — 6-step evaluate + scaffold workflow |
| 3 | `plugins/marketplace-builder/skills/building-marketplaces/references/audit-dimensions.md` | Scoring rubrics for 5 dimensions |
| 4 | `plugins/marketplace-builder/skills/building-marketplaces/references/marketplace-templates.md` | Marketplace scaffolding templates |
| 5 | `plugins/marketplace-builder/skills/building-marketplaces/references/checklist.md` | Quick-scan checklist |
| 6 | `plugins/marketplace-builder/README.md` | Plugin documentation |
| 7 | `plugins/marketplace-builder/CHANGELOG.md` | Version history |
| 8 | `.claude-plugin/marketplace.json` | Add new plugin entry |

---

## Implementation Details

### Step 1: `plugin.json`

Path: `plugins/marketplace-builder/.claude-plugin/plugin.json`

```json
{
  "name": "marketplace-builder",
  "version": "1.0.0",
  "description": "Evaluate a repository and scaffold Claude Code skill marketplace infrastructure",
  "author": { "name": "Agentics Project" },
  "license": "MIT",
  "keywords": ["marketplace", "scaffold", "skill-marketplace", "plugin-builder", "marketplace-setup", "plugin-readiness"],
  "homepage": "https://github.com/shawn-sandy/agentics/tree/main/plugins/marketplace-builder",
  "repository": "https://github.com/shawn-sandy/agentics"
}
```

### Step 2: `SKILL.md` (core skill)

Path: `plugins/marketplace-builder/skills/building-marketplaces/SKILL.md`

**Frontmatter:**
- `name: building-marketplaces` (gerund form per best practices)
- `description:` Third-person, ≤1024 chars, includes triggers and scope exclusions
- Trigger phrases: "build a marketplace", "set up a marketplace", "create a skill marketplace", "scaffold marketplace", "make this repo a marketplace", "marketplace builder"
- Scope exclusion: "Does not audit individual SKILL.md quality (use skill-reviewer) or CLAUDE.md content quality (use claude-md-optimizer)."

**Body: 6-step rigid sequential workflow (~180 lines)**

1. **Resolve target repository** — explicit path, CWD, or ask. Confirm with user before proceeding.
2. **Scan and inventory** — collect metrics:
   - Git status (initialized? remote? branch?)
   - Key files present: CLAUDE.md, .claude/rules/, README.md, LICENSE, .gitignore, CONTRIBUTING.md, CHANGELOG.md
   - Marketplace files: `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`
   - Plugin directories: count `plugins/*/` folders, check each for `.claude-plugin/plugin.json`
   - Skill/command detection: scan for `skills/*/SKILL.md` and `commands/*.md` under each plugin
   - Package manifest: package.json, Cargo.toml, pyproject.toml, etc.
   - Test infrastructure: test directories, CI config files
   - Top-level directory structure listing
3. **Run 5-dimension audit** — load `references/audit-dimensions.md`, score 0/1/2 per dimension (max 10)
4. **Present scored report** — table + grade + critical gaps + per-dimension findings + top 3 actions
5. **Offer marketplace scaffolding** — based on what's missing, offer to generate:
   - `.claude-plugin/marketplace.json` — per official schema (required: `name`, `owner`, `plugins`; optional: `metadata.description`, `metadata.version`, `metadata.pluginRoot`)
   - Validate marketplace name is not reserved (blocked: `claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences`)
   - `CLAUDE.md` (derived from actual scan data: detected tech stack, directory structure, conventions)
   - `.claude/rules/` directory with starter rules (e.g., `plugin-patterns.md`, `marketplace.md`)
   - `.claude/settings.json` with `extraKnownMarketplaces` entry for team distribution (optional, offer separately)
   - `.gitignore` additions (`.claude/worktrees/`, `CLAUDE.local.md`)
   - Plugin scaffold: `plugins/<name>/.claude-plugin/plugin.json` + `plugins/<name>/skills/<skill-name>/SKILL.md` stub
   - Show plugin source options: relative path (default), github, url, git-subdir, npm, pip
   - `CLAUDE.local.md` template
   - Each file shown in a code block first, then ask per-file "Should I write this?"
6. **Write confirmation** — explicit per-file confirmation before each write. Never batch-write without asking.

**Quick reference checklist** at the bottom (~30 items) for rapid pre-scan.

### Step 3: `references/audit-dimensions.md`

5 dimensions, each 0-2 points (max 10):

**Dimension 1: Repository Foundation (max 2)**
- CLAUDE.md present and non-trivial (>10 lines with key sections)?
- `.claude/rules/` directory with at least one rule file?
- CLAUDE.local.md pattern documented or `.gitignore` includes it?
- Scoring: 2 = all three, 1 = CLAUDE.md present but incomplete, 0 = no CLAUDE.md

**Dimension 2: Project Documentation (max 2)**
- README.md with overview, setup, and usage sections?
- LICENSE file present?
- CONTRIBUTING.md or equivalent?
- CHANGELOG.md present?
- .gitignore present and non-trivial?
- Scoring: 2 = README + 3 others, 1 = README + 1-2 others, 0 = no README

**Dimension 3: Code Organization (max 2)**
- Clear top-level directory structure (not flat dump of files)?
- Consistent naming conventions (kebab-case, camelCase, etc.)?
- Separation of concerns (source/test/config/docs)?
- Package manifest present (package.json, Cargo.toml, etc.)?
- Scoring: 2 = organized with manifest, 1 = some structure, 0 = flat or chaotic

**Dimension 4: Developer Experience (max 2)**
- Build/test/lint scripts defined in manifest?
- CI/CD config present (.github/workflows/, .gitlab-ci.yml, etc.)?
- Clear onboarding path (can a new dev get running in <5 min)?
- Scoring: 2 = scripts + CI + clear onboarding, 1 = some scripts, 0 = no automation

**Dimension 5: Marketplace Readiness (max 2)**
- `.claude-plugin/marketplace.json` present with required fields (`name`, `owner`, `plugins`)?
- Marketplace name is kebab-case and not a reserved name?
- At least one plugin in `plugins/` with valid `.claude-plugin/plugin.json` (required: `name`, `description`, `version`)?
- Plugin entries have required fields (`name`, `source`)?
- Plugin source paths valid (relative paths start with `./`, no `../` traversal)?
- Passes `claude plugin validate .` or `/plugin validate .`?
- Scoring: 2 = valid marketplace + ≥1 valid plugin + passes validation, 1 = partial (marketplace OR plugin exists), 0 = neither

**Grade scale:**
| Score | Grade |
|-------|-------|
| 9-10 | Marketplace-ready |
| 7-8 | Well-structured |
| 4-6 | Needs scaffolding |
| 0-3 | Fresh start |

Include example audit output for a 4/10 "Needs scaffolding" repo.

### Step 4: `references/marketplace-templates.md`

Templates the skill uses when scaffolding. Not generic — derived from scan data where possible.

**Marketplace.json template** (per official schema at https://code.claude.com/docs/en/plugin-marketplaces):

Required fields: `name` (kebab-case), `owner` (object with `name`), `plugins` (array).
Optional: `metadata.description`, `metadata.version`, `metadata.pluginRoot` (base dir for relative plugin sources).

```json
{
  "name": "<repo-name-kebab-case>",
  "owner": {
    "name": "<from git config or package.json>",
    "email": "<optional>"
  },
  "metadata": {
    "description": "<derived from README or package.json>"
  },
  "plugins": []
}
```

**Reserved marketplace names** (blocked by Claude Code):
`claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences`. Names that impersonate official marketplaces are also blocked.

**Plugin entry template** (required: `name`, `source`; all else optional):
```json
{
  "name": "<plugin-name>",
  "source": "./plugins/<plugin-name>",
  "description": "<brief description>",
  "version": "<semver>",
  "category": "<category>",
  "tags": ["<tag1>", "<tag2>"]
}
```

**Plugin source types** (6 options the skill should mention):
| Source | Format | Example |
|--------|--------|---------|
| Relative path | `"./plugins/name"` | Local directory within marketplace repo |
| GitHub | `{"source": "github", "repo": "owner/repo"}` | GitHub repository |
| Git URL | `{"source": "url", "url": "https://...git"}` | Any git host |
| Git subdirectory | `{"source": "git-subdir", "url": "...", "path": "..."}` | Monorepo subdirectory |
| npm | `{"source": "npm", "package": "@org/plugin"}` | npm registry |
| pip | `{"source": "pip", "package": "plugin"}` | PyPI registry |

**Version resolution warning**: Avoid setting version in both `plugin.json` and `marketplace.json` — `plugin.json` always wins silently. For relative-path plugins, set version in marketplace entry. For external sources, set in `plugin.json`.

**Team distribution template** (`.claude/settings.json`):
```json
{
  "extraKnownMarketplaces": {
    "<marketplace-name>": {
      "source": {
        "source": "github",
        "repo": "<owner>/<repo>"
      }
    }
  }
}
```

**Plugin directory template:**
```
plugins/<name>/
  .claude-plugin/
    plugin.json
  skills/
    <skill-name>/
      SKILL.md
      references/    (optional)
  commands/          (optional)
  README.md
  CHANGELOG.md
```

**CLAUDE.md generation guide:**
- Project Overview — derive from README.md or package.json `description`
- Tech Stack — detect from manifests (package.json → Node/TS, Cargo.toml → Rust, etc.)
- Repository Structure — generate from actual `ls` of top-level dirs
- Common Commands — extract from package.json scripts or Makefile targets
- Conventions — detect from existing code (naming patterns, file extensions)
- Reference Implementations — list discovered plugins

**SKILL.md stub template:**
```markdown
---
name: <skill-name>
description: <placeholder — describe what this skill does and when to use it. Include "Use when..." trigger phrase.>
---

## Overview

<Brief description of what this skill does.>

## Steps

1. **Step 1** — <description>
2. **Step 2** — <description>
3. **Step 3** — <description>
```

**Starter .claude/rules/ files:**
- `plugin-patterns.md` — basic plugin authoring conventions
- `marketplace.md` — version sync, categories, tagging rules

### Step 5: `references/checklist.md`

Quick checkbox list (~30 items) across all 5 dimensions:

**Repository Foundation**
- [ ] CLAUDE.md exists at root
- [ ] CLAUDE.md has Project Overview, Tech Stack, Commands, Structure, Conventions
- [ ] `.claude/rules/` directory exists with ≥1 rule file
- [ ] CLAUDE.local.md documented or in .gitignore

**Project Documentation**
- [ ] README.md with overview + setup + usage
- [ ] LICENSE file
- [ ] CONTRIBUTING.md
- [ ] CHANGELOG.md
- [ ] .gitignore is non-trivial

**Code Organization**
- [ ] Clear directory structure (not flat)
- [ ] Consistent naming conventions
- [ ] Source/test/config separation
- [ ] Package manifest present

**Developer Experience**
- [ ] Build/test/lint scripts in manifest
- [ ] CI/CD config present
- [ ] New developer can get running quickly

**Marketplace Readiness** (per official schema: https://code.claude.com/docs/en/plugin-marketplaces)
- [ ] `.claude-plugin/marketplace.json` exists
- [ ] Required fields present: `name` (kebab-case), `owner.name`, `plugins` (array)
- [ ] Marketplace name is not reserved (`claude-code-marketplace`, `anthropic-plugins`, etc.)
- [ ] `plugins` array has ≥1 entry
- [ ] Each plugin entry has required fields: `name` (kebab-case), `source`
- [ ] Plugin source paths are valid (relative paths start with `./`, no `../` traversal)
- [ ] `plugins/<name>/.claude-plugin/plugin.json` exists for relative-path plugins
- [ ] `plugin.json` has required fields: `name`, `description`, `version`
- [ ] Version not set in both `marketplace.json` and `plugin.json` (plugin.json wins silently)
- [ ] At least one plugin has a `skills/` or `commands/` directory
- [ ] SKILL.md files have valid YAML frontmatter with `name` and `description`
- [ ] Plugin homepage URLs point to plugin-specific directory (not repo root)
- [ ] Passes `claude plugin validate .` or `/plugin validate .`

### Step 6: `README.md`

Path: `plugins/marketplace-builder/README.md`

Follow established plugin README pattern:
- Overview (what it does, who it's for)
- Features (evaluate + scaffold)
- Installation (marketplace: `/plugin install marketplace-builder@agentics-kit`, local: `--plugin-dir`)
- Usage (trigger phrases, example workflow)
- Plugin Structure (file tree)
- Components (skill description)
- What Gets Scaffolded (list of files the skill can generate)

### Step 7: `CHANGELOG.md`

Path: `plugins/marketplace-builder/CHANGELOG.md`

Keep a Changelog format. Single entry:
```
## [1.0.0] - 2026-03-06
### Added
- Initial release
- Repository evaluation with 5-dimension scoring
- Marketplace infrastructure scaffolding
- CLAUDE.md, plugin.json, SKILL.md template generation
```

### Step 8: Update `marketplace.json`

Add to `.claude-plugin/marketplace.json` plugins array:
```json
{
  "name": "marketplace-builder",
  "source": "./plugins/marketplace-builder",
  "version": "1.0.0",
  "description": "Evaluate a repository and scaffold Claude Code skill marketplace infrastructure — audit readiness, generate missing files, and guide marketplace setup",
  "category": "development",
  "tags": [
    "marketplace",
    "scaffold",
    "skill-marketplace",
    "plugin-builder",
    "marketplace-setup",
    "plugin-readiness",
    "developer-experience",
    "onboarding"
  ]
}
```

### Step 9: Verify

1. Version sync: `plugin.json` version `1.0.0` matches `marketplace.json` entry
2. SKILL.md frontmatter: `name` is kebab-case, `description` ≤1024 chars, third person, has "Use when..."
3. SKILL.md body: <500 lines, <5000 words
4. References: all at depth ≤1 from SKILL.md
5. File tree matches plan
6. Marketplace validation: `claude plugin validate .` from repo root (checks JSON syntax, required fields, duplicate names, path traversal)
7. Load test: `claude --plugin-dir ./plugins/marketplace-builder` → trigger with "build a marketplace" or "set up a marketplace"

### Step 10: Commit

```
feat(plugins/marketplace-builder): add marketplace-builder plugin v1.0.0
```

Include the plan file in the commit per project conventions.

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Evaluate + Scaffold (not just audit) | User wants to help devs BUILD skill marketplaces, not just score repos. Audit informs what to scaffold. |
| 5 dimensions x 2 pts = max 10 | Matches skill-reviewer scale. Clean grade boundaries. |
| Dim 5 (Marketplace Readiness) is the differentiator | Other plugins cover CLAUDE.md and SKILL.md quality. This plugin uniquely scores and scaffolds marketplace infrastructure. |
| Templates derived from scan data | Scaffolded CLAUDE.md pulls from actual package.json, directory structure — not generic boilerplate. |
| Per-file write confirmation | Safety pattern from claude-md-optimizer. Never batch-write generated files. |
| Clear scope boundaries | Defers to `claude-md-optimizer` for CLAUDE.md quality audit, `skill-reviewer` for SKILL.md quality audit. |
| `marketplace-templates.md` not `repo-templates.md` | Reflects the marketplace-building focus, not generic repo types. |

---

## Official Marketplace Schema (from docs)

The skill's `references/marketplace-templates.md` must align with the official schema:

**marketplace.json required fields:**
| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Kebab-case marketplace identifier. Users see it in `/plugin install X@name` |
| `owner` | object | `name` (required), `email` (optional) |
| `plugins` | array | List of plugin entries |

**marketplace.json optional fields:**
| Field | Type | Description |
|-------|------|-------------|
| `metadata.description` | string | Brief marketplace description |
| `metadata.version` | string | Marketplace version |
| `metadata.pluginRoot` | string | Base dir prepended to relative source paths |

**Plugin entry required fields:** `name`, `source`
**Plugin entry optional fields:** `description`, `version`, `author`, `homepage`, `repository`, `license`, `keywords`, `category`, `tags`, `strict`, `commands`, `agents`, `hooks`, `mcpServers`, `lspServers`

**Strict mode:** `strict: true` (default) — plugin.json is authority, marketplace supplements. `strict: false` — marketplace entry is entire definition, plugin.json must not declare components.

**Plugin caching note:** Plugins are copied to `~/.claude/plugins/cache`. Cannot reference `../` outside plugin directory. Use symlinks for shared files.

**Validation commands:** `claude plugin validate .` or `/plugin validate .`

---

## Files to Reuse as Patterns

| File | What to Reuse |
|------|---------------|
| `plugins/skill-reviewer/skills/reviewing-skills/SKILL.md` | Audit workflow structure, frontmatter pattern, checklist format |
| `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md` | 6-step rigid workflow, write confirmation pattern, rules-file generation |
| `plugins/claude-md-optimizer/skills/claude-md-optimizer/references/audit-steps.md` | Dimension scoring tables, example output format |
| `plugins/skill-reviewer/skills/reviewing-skills/references/audit-steps.md` | Regression risk pattern, grade thresholds |
| `.claude-plugin/marketplace.json` | Target for new entry; also the canonical example of marketplace structure |
| `.claude/rules/plugin-patterns.md` | Content to adapt for starter rules generation |
| `.claude/rules/marketplace.md` | Content to adapt for starter rules generation |

---

## Interview Summary

### Key Decisions Confirmed
- Equal weight across all 5 audit dimensions (2 pts each, max 10)
- CLAUDE.md scaffolding will be a minimal stub with section headings and TODOs — defer quality to `claude-md-optimizer`
- Follow official docs for version placement: single source of truth (marketplace.json for relative-path plugins, plugin.json for external sources)
- Generic starter rules for `.claude/rules/` — no agentics-specific conventions

### Open Risks & Concerns
- **Existing marketplace handling**: Plan needs explicit logic for repos that already have a marketplace.json (add to it? warn? offer to update broken fields?)
- **Broken file detection**: Step 2 scans for presence but Step 5 only scaffolds "missing" files — need to handle "present but invalid" case
- **Version self-consistency**: The marketplace-builder's own plugin.json and marketplace.json entry both set version, contradicting the official pattern the skill teaches
- **Plugin name uniqueness**: Scaffold should validate proposed names against existing marketplace entries before generating

### Recommended Next Steps
1. Add logic in SKILL.md Step 2 to distinguish "missing", "present and valid", and "present but broken" for marketplace files
2. Add a note in SKILL.md Step 5 about handling existing marketplace.json (offer to add entries vs. create new)
3. Decide whether to remove `version` from the marketplace-builder's own `plugin.json` to follow official guidance, or keep it for consistency with the existing agentics pattern (note: this affects ALL existing agentics plugins, not just this one)
4. Add plugin name uniqueness validation to Step 5 scaffold logic

### Simplification Opportunities
- None identified — the plan follows established patterns with appropriate scope
