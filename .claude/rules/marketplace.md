# Marketplace Configuration

## Registering a Plugin

Add plugin entries to `.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "my-plugin",
      "source": {
        "source": "git-subdir",
        "url": "shawn-sandy/agentics",
        "path": "kit/plugins/my-plugin"
      },
      "version": "1.0.0",
      "description": "Brief description",
      "category": "development",
      "tags": ["relevant", "tags"]
    }
  ]
}
```

**Version:** Set `version` only in `marketplace.json`. Do NOT add it to `plugin.json` — `plugin.json` silently overrides the marketplace version.

## Standard Categories

- `development` — Developer tools and utilities
- `productivity` — Workflow and efficiency tools
- `learning` — Educational and tutorial plugins
- `testing` — Testing and QA tools
- `documentation` — Documentation generators
- `security` — Security analysis and auditing

## Tagging

Tags must be specific, searchable, and related to plugin functionality. Avoid generic terms like "tool" or "helper".

## Versioning

**Versions are bumped automatically by CI after merge to main.** Do not manually edit `version` fields in `marketplace.json` — the version guard CI check (`check-no-manual-bump.sh`) will reject PRs that do.

| Bump | When |
|------|------|
| **PATCH** | Bug fix, typo, metadata correction |
| **MINOR** | New command, skill, agent, or hook added |
| **MAJOR** | Removing/renaming a command/skill/agent, changing argument format or activation behavior |

### How it works

1. You commit plugin changes using conventional commit messages to signal the bump type
2. The version guard PR check (`check-no-manual-bump.sh`) verifies you did NOT manually change any version fields
3. After your PR merges, the `auto-version-bump.yml` workflow detects which plugins changed, reads your commit messages for the bump type, and applies the correct semver bump to `marketplace.json`
4. The CI commits the version bump with `[skip ci]` to prevent loops

### Signaling bump type

Use conventional commit scopes to control which bump type CI applies:

- Patch: `fix(kit/plugins/<name>): <description>`
- Minor: `feat(kit/plugins/<name>): <description>`
- Major: `feat(kit/plugins/<name>)!: <description>` or include `BREAKING CHANGE:` in the commit body

Unscoped commits (`fix: ...`, `feat: ...`) apply to all plugins with changed source files. When multiple commits touch the same plugin, the highest bump wins.

### What you still do manually

1. Add an entry to `kit/plugins/<name>/CHANGELOG.md` describing the change
2. Use conventional commit messages so CI picks the right bump type

### Merge driver

The `scripts/merge-marketplace.mjs` merge driver (registered via `.gitattributes`) still handles non-version merge conflicts in `marketplace.json` — e.g., two branches adding different new plugins or updating metadata fields.

### Legacy scripts

- `scripts/check-version-bump.sh` — the old guard that *required* manual bumps. Superseded by `check-no-manual-bump.sh`. Retained for reference.

## Removed Plugins — Do Not Re-Add

The following plugins were deliberately removed from the marketplace. Do not re-register them unless the removal reason is explicitly resolved and the user approves.

| Plugin | Removed | Reason |
|--------|---------|--------|
| `agent-creator` | 2026-05-29 | Redundant with `agentic-plugin-dev` |
| `agent-reviewer` | 2026-05-29 | Overlaps with `skill-reviewer` |
| `marketplace-builder` | 2026-05-29 | Redundant with `agentic-plugin-dev` |
| `react-perf-analyzer` | 2026-05-29 | Too specialized; `code-review` covers general perf |
| `agentic-plugin-dev` | 2026-05-29 | Removed from marketplace; directories retained for reference |
| `code-simplifier` | 2026-05-29 | Removed from marketplace; structural analysis covered by `code-review` |

If a user asks to add any of these back, flag the removal reason and ask for explicit confirmation before proceeding.

## Common Pitfalls

- Invalid `path` in `git-subdir` source — must match actual directory in the repo
- Duplicate plugin names in the same marketplace
- Missing `marketplace.json` in `kit/.claude-plugin/`
- Setting `version` in both `plugin.json` and `marketplace.json`
