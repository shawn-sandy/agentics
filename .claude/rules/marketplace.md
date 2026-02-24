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

## Common Pitfalls

- Invalid `source` paths — must be relative or absolute and must exist on disk
- Duplicate plugin names in the same marketplace
- Missing `marketplace.json` in `.claude-plugin/` directory
- Version mismatch between `marketplace.json` and `plugin.json`
