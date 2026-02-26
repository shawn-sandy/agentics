# Plan: Dev-Tools Plugin Refactor & Marketplace Optimization

## Context

The `dev-tools` plugin bundles three distinct skills (`claude-md-optimizer`, `code-review`, `plan-interview`) alongside a `format` command. Bundled skills reduce discoverability, complicate independent versioning, and conflict with marketplace best practices which favor focused, single-purpose plugins. The `hello-world` plugin also lacks recommended metadata fields. This plan extracts each skill into its own standalone plugin and optimizes both plugins to meet Claude Code marketplace standards per the official reference docs.

**References:**
- [plugins-reference](https://code.claude.com/docs/en/plugins-reference)
- [plugin-marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)

---

## Current Structure

```
plugins/
├── hello-world/
│   ├── .claude-plugin/plugin.json
│   ├── commands/greet.md
│   └── README.md
└── dev-tools/
    ├── .claude-plugin/plugin.json
    ├── commands/
    │   ├── format.md
    │   └── plan-interview.md      ← move to plan-interview plugin
    └── skills/
        ├── claude-md-optimizer/   ← extract to own plugin
        ├── code-review/           ← extract to own plugin
        └── plan-interview/        ← extract to own plugin
```

---

## Target Structure

```
plugins/
├── hello-world/           (optimized - metadata + keywords)
├── dev-tools/             (refocused - format command only)
├── claude-md-optimizer/   (new standalone plugin)
├── code-review/           (new standalone plugin)
└── plan-interview/        (new standalone plugin - command + skill)
```

---

## Steps

### 1. Create `plugins/claude-md-optimizer/`

- Create `.claude-plugin/plugin.json` with full recommended metadata
- Create `skills/claude-md-optimizer/SKILL.md` (copy content from `dev-tools/skills/claude-md-optimizer/SKILL.md`)
- Create `README.md` documenting: purpose, skills provided, usage, activation triggers
- Add `keywords: ["claude-md", "configuration", "optimization", "best-practices"]`

### 2. Create `plugins/code-review/`

- Create `.claude-plugin/plugin.json` with full recommended metadata
- Create `skills/code-review/SKILL.md` (copy content from `dev-tools/skills/code-review/SKILL.md`)
- Create `README.md` documenting: purpose, skills provided, review checklist overview, usage
- Add `keywords: ["code-quality", "review", "security", "best-practices"]`

### 3. Create `plugins/plan-interview/`

- Create `.claude-plugin/plugin.json` with full recommended metadata
- Create `commands/plan-interview.md` (move from `dev-tools/commands/plan-interview.md`)
- Create `skills/plan-interview/SKILL.md` (copy content from `dev-tools/skills/plan-interview/SKILL.md`)
- Create `README.md` documenting: purpose, command usage (`/plan-interview`), skill auto-activation, interview rounds
- Add `keywords: ["planning", "interview", "stress-test", "architecture"]`

### 4. Refactor `plugins/dev-tools/`

- `git mv plugins/dev-tools/commands/plan-interview.md plugins/plan-interview/commands/plan-interview.md` (preserves file history)
- Remove `skills/` directory and all contents (all skills extracted; do this BEFORE step 6 to avoid transient marketplace conflicts)
- Update `.claude-plugin/plugin.json`: bump version to `2.0.0`, update description to format-only scope
- Update `README.md` to reflect the new format-only scope (remove references to extracted skills)
- Create `CHANGELOG.md` documenting v2.0.0 breaking change: list the 3 removed skills and their new plugin names
- Update keywords to `["formatting", "code-quality", "prettier", "eslint"]`

### 5. Optimize `plugins/hello-world/`

- Update `.claude-plugin/plugin.json` with `keywords`, `homepage`, `repository` fields
- Add `keywords: ["example", "tutorial", "minimal", "getting-started"]`
- Update `README.md` to include: purpose as reference plugin, command usage, marketplace installation instructions

### 6. Update `.claude-plugin/marketplace.json`

- Add `metadata.description` for marketplace discoverability
- Add entries for `claude-md-optimizer`, `code-review`, `plan-interview` (each `v1.0.0`) with explicit `./plugins/` source prefixes
- Update `dev-tools` entry: version `2.0.0`, updated description/category/tags
- Keep `version` in all entries (must stay in sync with `plugin.json` — both are authoritative for different load paths)
- **Do this after step 4 (dev-tools cleanup)** to avoid transient conflicts during intermediate states

### 7. Cleanup

- Delete `.DS_Store` from `dev-tools/`
- Remove `skills/` READMEs that are no longer needed in `dev-tools/`
- Add `**/.DS_Store` to `.gitignore` at repo root (prevent future occurrences across all plugin folders)

---

## Plugin Manifest Template (for new plugins)

Keep `version` in **both** `plugin.json` AND `marketplace.json`. Plugin.json version takes priority at runtime, and this ensures `--plugin-dir` users retain version info. Both must stay in sync.

```json
{
  "name": "<plugin-name>",
  "description": "<description>",
  "author": {
    "name": "Agentics Project"
  },
  "license": "MIT",
  "keywords": ["<relevant>", "<tags>"],
  "homepage": "https://code.claude.com/docs/en/plugins",
  "repository": "https://github.com/shawnsandy/agentics"
}
```

## Marketplace Entry Template (per plugin in marketplace.json)

```json
{
  "name": "<plugin-name>",
  "source": "<plugin-name>",
  "version": "1.0.0",
  "description": "<description>",
  "category": "<category>",
  "tags": ["<tag1>", "<tag2>"],
  "keywords": ["<kw1>", "<kw2>"],
  "homepage": "https://code.claude.com/docs/en/plugins",
  "repository": "https://github.com/shawnsandy/agentics",
  "license": "MIT",
  "author": { "name": "Agentics Project" }
}
```

## Updated marketplace.json Structure

Use explicit `./plugins/` prefixes (not `metadata.pluginRoot`) — pluginRoot support is not confirmed and failures would silently break all plugin source resolution:

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "agentics-kit",
  "owner": { "name": "Agentics Team", "email": "shawnsandy04@gmail.com" },
  "metadata": {
    "description": "Agentics plugin kit — developer tools, code review, planning, and CLAUDE.md optimization"
  },
  "plugins": [
    { "name": "hello-world",         "source": "./plugins/hello-world",         "version": "1.0.0", ... },
    { "name": "dev-tools",           "source": "./plugins/dev-tools",           "version": "2.0.0", ... },
    { "name": "claude-md-optimizer", "source": "./plugins/claude-md-optimizer", "version": "1.0.0", ... },
    { "name": "code-review",         "source": "./plugins/code-review",         "version": "1.0.0", ... },
    { "name": "plan-interview",      "source": "./plugins/plan-interview",      "version": "1.0.0", ... }
  ]
}
```

---

## Files Modified

| File | Action |
|------|--------|
| `plugins/claude-md-optimizer/.claude-plugin/plugin.json` | Create |
| `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md` | Create (copy) |
| `plugins/claude-md-optimizer/README.md` | Create |
| `plugins/code-review/.claude-plugin/plugin.json` | Create |
| `plugins/code-review/skills/code-review/SKILL.md` | Create (copy) |
| `plugins/code-review/README.md` | Create |
| `plugins/plan-interview/.claude-plugin/plugin.json` | Create |
| `plugins/plan-interview/commands/plan-interview.md` | Create (move) |
| `plugins/plan-interview/skills/plan-interview/SKILL.md` | Create (copy) |
| `plugins/plan-interview/README.md` | Create |
| `plugins/dev-tools/.claude-plugin/plugin.json` | Update (bump to v2.0.0, update description) |
| `plugins/dev-tools/commands/plan-interview.md` | `git mv` to plan-interview plugin (preserves history) |
| `plugins/dev-tools/skills/` | Delete (all extracted) |
| `plugins/dev-tools/README.md` | Update (reflect format-only scope) |
| `plugins/dev-tools/CHANGELOG.md` | Create (v2.0.0 breaking changes) |
| `plugins/hello-world/.claude-plugin/plugin.json` | Update (add metadata) |
| `plugins/hello-world/README.md` | Update (add install/usage docs) |
| `.claude-plugin/marketplace.json` | Update (add 3 entries, metadata.description) |
| `.gitignore` | Update (add `**/.DS_Store`) |

---

## README Required Sections (all plugin READMEs)

Every plugin README must include these four sections:
1. **Purpose & description** — What problem does this plugin solve?
2. **Component list** — All commands/skills/agents provided (with names)
3. **Usage examples** — Command syntax or example triggers for skill auto-activation
4. **Installation** — `/plugin install <name>@agentics-kit`

## Verification

Run in this order (isolated tests first, then marketplace):

1. `claude --debug --plugin-dir plugins/claude-md-optimizer` — verify skill loads
2. `claude --debug --plugin-dir plugins/code-review` — verify skill loads
3. `claude --debug --plugin-dir plugins/plan-interview` — verify command + skill load
4. `claude --debug --plugin-dir plugins/dev-tools` — verify only format command loads
5. `claude plugin validate .` from repo root — validate marketplace JSON
6. Register marketplace: `/plugin marketplace add ~/devbox/agentics`
7. Check `/plugin` discover tab shows all 5 plugins with correct metadata and descriptions

---

## Interview Summary

### Key Decisions Confirmed

- **Version**: Keep in both `plugin.json` and `marketplace.json`; must stay in sync — both serve different load paths (`--plugin-dir` vs marketplace install)
- **plan-interview command+skill overlap**: Acceptable — explicit command for manual invocation, skill auto-activates on intent; different use contexts
- **operation ordering**: Steps 1-3 (create new plugins) → Step 4 (delete dev-tools skills) → Step 6 (update marketplace.json) — no transient conflicts
- **pluginRoot**: Dropped in favor of explicit `./plugins/` prefixes — undocumented behavior risk too high
- **CHANGELOG.md**: Add to dev-tools documenting v2.0.0 breaking changes and redirect to new plugin names
- **README standard**: All plugin READMEs must include purpose, component list, usage examples, installation

### Open Risks & Concerns

- **Existing marketplace users**: Anyone with `agentics-kit` registered will lose dev-tools skills on next update; CHANGELOG.md + README migration note mitigates this
- **metadata.pluginRoot**: Not verified as supported — using safe `./plugins/` fallback instead
- **plugin validate**: Confirmed as a verification step but not yet tested against this repo structure
- **Intermediate state**: If implementation is interrupted after new plugins created but before dev-tools skills deleted, duplicates exist temporarily; safe since marketplace.json won't reference dev-tools skills

### Recommended Next Steps

- Use `git mv` for `plan-interview.md` to preserve file history
- Add `**/.DS_Store` to `.gitignore` as part of cleanup step
- Run `--plugin-dir` tests for each new plugin in isolation before updating marketplace.json
- Run `claude plugin validate .` after marketplace.json update

### Simplification Opportunities

None identified — the decomposition is appropriately scoped with each plugin having a clear single responsibility.
