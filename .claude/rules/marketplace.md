---
paths:
  - "kit/plugins/**"
  - ".claude-plugin/**"
---

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

**Bump the `version` field in `marketplace.json` manually** as part of any PR that changes a plugin. The new value must be higher than the value on `main`. There is no CI version guard and no automatic post-merge bump — what you set in the PR is what ships.

| Bump | When |
|------|------|
| **PATCH** | Bug fix, typo, metadata correction |
| **MINOR** | New command, skill, agent, or hook added |
| **MAJOR** | Removing/renaming a command/skill/agent, changing argument format or activation behavior |

### What you do

1. Edit the plugin's `version` in `.claude-plugin/marketplace.json` to the next semver value (see the table above).
2. Add an entry to `kit/plugins/<name>/CHANGELOG.md` describing the change.
3. Use conventional commit messages (`feat(...)`, `fix(...)`) so the history stays readable — these are no longer wired to any automatic bump, but remain the project convention.

### Merge driver

The `scripts/merge-marketplace.mjs` merge driver (registered via `.gitattributes`) handles version merge conflicts in `marketplace.json` — when two branches bump the same plugin, it keeps the higher semver. It also resolves non-version conflicts, e.g. two branches adding different new plugins or updating metadata fields.

## Removed Plugins — Do Not Re-Add

The following plugins were deliberately removed from the marketplace. Do not re-register them unless the removal reason is explicitly resolved and the user approves.

| Plugin | Removed | Reason |
|--------|---------|--------|
| `agent-creator` | 2026-05-29 | Redundant with `agentic-plugin-dev` |
| `agent-reviewer` | 2026-05-29 | Overlaps with `skill-reviewer` |
| `marketplace-builder` | 2026-05-29 | Redundant with `agentic-plugin-dev` |
| `react-perf-analyzer` | 2026-05-29 | Too specialized; `code-review` covers general perf |
| `agentic-plugin-dev` | 2026-05-29 | Removed from marketplace; source deleted 2026-07-16, recoverable from git history |
| `code-simplifier` | 2026-05-29 | Removed from marketplace; structural analysis covered by `code-review`; source deleted 2026-07-16, recoverable from git history |
| `plan-interview` | 2026-07-17 | Merged into `plan-agent` 4.0.0 (documenting-plans, markdown-to-html, plan-status, plan-maintenance, deep-grill, and the ExitPlanMode nudge carried over); source recoverable from git history |

If a user asks to add any of these back, flag the removal reason and ask for explicit confirmation before proceeding.

## Common Pitfalls

- Invalid `path` in `git-subdir` source — must match actual directory in the repo
- Duplicate plugin names in the same marketplace
- Missing `marketplace.json` in `kit/.claude-plugin/`
- Setting `version` in both `plugin.json` and `marketplace.json`
