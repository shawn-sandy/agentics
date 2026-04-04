# Marketplace Configuration

## Registering a Plugin

Add plugin entries to `agentics/.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "my-plugin",
      "version": "1.0.0",
      "description": "Brief description",
      "source": "./plugins/my-plugin",
      "category": "development",
      "tags": ["relevant", "tags"]
    }
  ]
}
```

**Version:** Set `version` only in `marketplace.json` for relative-path plugins. Do NOT add it to `plugin.json` — `plugin.json` silently overrides the marketplace version.

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

1. Update `"version"` in `agentics/.claude-plugin/marketplace.json` under the plugin entry
2. Add an entry to `agentics/plugins/<name>/CHANGELOG.md`
3. Commit with a conventional message:
   - Patch: `fix(agentics/plugins/<name>): bump version to X.Y.Z`
   - Minor: `feat(agentics/plugins/<name>): bump version to X.Y.Z`
   - Major: `feat(agentics/plugins/<name>)!: bump version to X.Y.Z` + `BREAKING CHANGE:` in body

## Common Pitfalls

- Invalid `source` paths — must exist on disk
- Duplicate plugin names in the same marketplace
- Missing `marketplace.json` in `agentics/.claude-plugin/`
- Setting `version` in both `plugin.json` and `marketplace.json`
