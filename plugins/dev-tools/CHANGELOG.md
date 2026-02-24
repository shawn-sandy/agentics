# Changelog

## v2.0.0 — Breaking Changes

### Removed skills

The following skills have been **removed** from this plugin and extracted into standalone plugins. Install them separately to continue using them:

| Removed skill | New plugin | Install command |
|---------------|-----------|-----------------|
| `claude-md-optimizer` | `claude-md-optimizer` | `/plugin install claude-md-optimizer@agentics-kit` |
| `code-review` | `code-review` | `/plugin install code-review@agentics-kit` |
| `plan-interview` | `plan-interview` | `/plugin install plan-interview@agentics-kit` |

### Removed commands

| Removed command | New plugin | New command |
|-----------------|-----------|-------------|
| `/dev-tools:plan-interview` | `plan-interview` | `/plan-interview:plan-interview` |

### What remains

- `/dev-tools:format` — unchanged, still works the same way

### Migration

If you installed `dev-tools` to access code review or planning tools, install the new standalone plugins:

```
/plugin install code-review@agentics-kit
/plugin install claude-md-optimizer@agentics-kit
/plugin install plan-interview@agentics-kit
```

---

## v1.1.0

- Added `plan-interview` command and skill
- Added `claude-md-optimizer` skill
- Added `code-review` skill

## v1.0.0

- Initial release with `format` command
