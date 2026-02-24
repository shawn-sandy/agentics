# Marketplace Configuration

## Registering a Plugin

Add plugin entries to `.claude-plugin/marketplace.json`:

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

**Version Synchronization:** `version` in `marketplace.json` must exactly match `version` in the plugin's `plugin.json`.

## Standard Categories

- `development` — Developer tools and utilities
- `productivity` — Workflow and efficiency tools
- `learning` — Educational and tutorial plugins
- `testing` — Testing and QA tools
- `documentation` — Documentation generators
- `security` — Security analysis and auditing

## Tagging Strategy

Tags must be:
- Specific and descriptive (not generic like "tool" or "helper")
- Searchable terms users would type when looking for this plugin
- Related to plugin functionality or use case

Example: `["formatting", "code-quality", "prettier", "eslint"]`

## Versioning (Semantic Versioning)

- **MAJOR** (`2.0.0`) — Breaking changes to plugin structure or behavior
- **MINOR** (`1.1.0`) — New features, backward compatible
- **PATCH** (`1.0.1`) — Bug fixes, backward compatible

## Bumping a Plugin Version

Every plugin version appears in exactly two places that **must match**:

1. `plugins/<name>/.claude-plugin/plugin.json` → `"version"`
2. `.claude-plugin/marketplace.json` → `plugins[].version` for that plugin entry

A mismatch causes install failure.

### When to bump

| Bump | Triggers |
|------|----------|
| **PATCH** | Bug fix in a command/skill/hook, typo or clarification in instructions, correcting metadata (homepage, keywords) |
| **MINOR** | New command added, new skill added, new agent/hook added — all backward compatible |
| **MAJOR** | Removing or renaming a command/skill/agent, changing command argument format, changing skill activation behavior, restructuring plugin directory |

> **Out of scope:** `tests/fixtures/` plugins do not need version bumps. The marketplace-level version (`agentics-kit` v2.0.0) is separate from individual plugin versions and is not covered here.

### How to bump

1. **Edit `plugin.json`** — update `"version"` in `plugins/<name>/.claude-plugin/plugin.json`
2. **Edit `marketplace.json`** — update the matching `"version"` in `.claude-plugin/marketplace.json` under the same plugin entry
3. **Update changelog** — add an entry to `plugins/<name>/CHANGELOG.md` (create the file if it doesn't exist)
4. **Verify sync** — confirm both values match:
   ```bash
   grep -r '"version"' plugins/<name>/.claude-plugin/ .claude-plugin/marketplace.json
   ```
5. **Commit** — use a conventional commit message:
   - Patch: `fix(plugins/<name>): bump version to X.Y.Z`
   - Minor: `feat(plugins/<name>): bump version to X.Y.Z`
   - Major: `feat(plugins/<name>)!: bump version to X.Y.Z` with a `BREAKING CHANGE:` note in the body

## Common Pitfalls

- Invalid `source` paths — must be relative or absolute and must exist on disk
- Duplicate plugin names in the same marketplace
- Missing `marketplace.json` in `.claude-plugin/` directory
- Version mismatch between `marketplace.json` and `plugin.json`
