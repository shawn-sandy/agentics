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

| Bump | When |
|------|------|
| **PATCH** | Bug fix, typo, metadata correction |
| **MINOR** | New command, skill, agent, or hook added |
| **MAJOR** | Removing/renaming a command/skill/agent, changing argument format or activation behavior |

### How to bump

1. Update `"version"` in `.claude-plugin/marketplace.json` under the plugin entry
2. Add an entry to `kit/plugins/<name>/CHANGELOG.md`
3. Commit with a conventional message:
   - Patch: `fix(kit/plugins/<name>): bump version to X.Y.Z`
   - Minor: `feat(kit/plugins/<name>): bump version to X.Y.Z`
   - Major: `feat(kit/plugins/<name>)!: bump version to X.Y.Z` + `BREAKING CHANGE:` in body

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
