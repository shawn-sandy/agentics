# Plugin Manifest Schema (`plugin.json`)

Official docs: <https://code.claude.com/docs/en/plugins-reference>

Use `WebFetch` on the URL above for the latest spec if the user requests "use latest docs".

## Required Fields

| Field | Type | Constraint |
|-------|------|------------|
| `name` | string | Required. Lowercase letters, numbers, hyphens. ≤64 chars. Must not contain `anthropic` or `claude`. |

## Recommended Fields

| Field | Type | Constraint |
|-------|------|------------|
| `description` | string | What the plugin does. ≤256 chars. |
| `author` | object | `{ "name": "...", "email": "..." }` |
| `license` | string | SPDX identifier (e.g., `MIT`, `Apache-2.0`) |
| `keywords` | string[] | Searchable terms. Specific, not generic. |
| `homepage` | string | URL to plugin docs or directory. For this repo: `https://github.com/shawn-sandy/agentics/tree/main/plugins/[name]` |
| `repository` | string | URL to source repository |

## Fields to NEVER Include (Relative-Path Plugins)

| Field | Reason |
|-------|--------|
| `version` | For relative-path plugins, version lives only in `marketplace.json`. `plugin.json` silently overrides it, creating maintenance risk. |

## Example

```json
{
  "name": "my-plugin",
  "description": "Brief description of what the plugin does",
  "author": {
    "name": "Author Name"
  },
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "homepage": "https://github.com/owner/repo/tree/main/plugins/my-plugin",
  "repository": "https://github.com/owner/repo"
}
```

## Validation Checklist

- [ ] `name` is present, lowercase, hyphenated, ≤64 chars
- [ ] `name` does not contain `anthropic` or `claude`
- [ ] No `version` field (for relative-path plugins)
- [ ] `description` is present and concise
- [ ] `homepage` points to the plugin directory, not the repo root
- [ ] JSON is valid (no trailing commas, proper quoting)
