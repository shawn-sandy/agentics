# Changelog

All notable changes to this project are documented here.

---

## [Unreleased] — Marketplace Refactor

### Summary

Three bugs were discovered and fixed during an attempt to register the `agentics-test`
marketplace via `/plugin marketplace add`. Each bug was a schema validation error caught
by the Claude Code CLI at a different stage: marketplace registration, plugin install.

---

### Bug 1 — Marketplace registered at the wrong directory

**Commit:** `af36361` / `aae719c`

**Symptom:**
Registration required pointing at a subdirectory instead of the repo root:
```bash
/plugin marketplace add ~/devbox/agentics/marketplace-data  # wrong
```

**Root Cause:**
Claude Code looks for `.claude-plugin/marketplace.json` in the directory you register.
The manifest was nested inside `marketplace-data/.claude-plugin/` — a subdirectory of
the repo — so users had to register `marketplace-data/` rather than the project root.
This was inconsistent with the Claude Code docs, which show `.claude-plugin/` at the
root of the registered directory.

**Fix:**
Moved the manifest to the project root via `git mv`:
```
marketplace-data/.claude-plugin/marketplace.json → .claude-plugin/marketplace.json
```

**Side effect fixed:**
Moving the file also resolved a latent path traversal issue. Source paths in
`marketplace.json` are resolved relative to the manifest's location. When the manifest
lived inside `marketplace-data/.claude-plugin/`, the paths had to traverse upward:
```json
"source": "../plugins/hello-world"
```
After moving to the project root, the paths are straightforward:
```json
"source": "./plugins/hello-world"
```

The `marketplace-data/` directory was deleted entirely (its README contained only
API speculation and boilerplate not relevant to local plugin testing).

---

### Bug 2 — `"components"` is not a valid key in `marketplace.json`

**Commit:** `95bf881`

**Error:**
```
Error: Failed to parse marketplace file at .claude-plugin/marketplace.json:
Invalid schema: plugins.1: Unrecognized key: "components"
```

**Root Cause:**
The `dev-tools` plugin entry in `marketplace.json` included a `"components"` field
listing its commands and skills:
```json
{
  "name": "dev-tools",
  "source": "./plugins/dev-tools",
  "components": {
    "commands": ["format", "plan-review", "plan-interview"],
    "skills": ["code-review", "claude-md-optimizer"]
  }
}
```
This field was a custom addition not defined in the official marketplace schema. The
CLI's strict schema validation rejects any unrecognized keys.

**Fix:**
Removed the `"components"` block from the `dev-tools` entry. The CLI discovers
commands and skills by scanning the plugin directory itself — they do not need to be
declared in `marketplace.json`.

---

### Bug 3 — `"category"` is not a valid key in `plugin.json`

**Commit:** `0e463fd`

**Error:**
```
Error: Failed to install: Plugin has an invalid manifest file at
.claude-plugin/plugin.json. Validation errors: Unrecognized key: "category"
```

**Root Cause:**
Both `plugins/hello-world/.claude-plugin/plugin.json` and
`plugins/dev-tools/.claude-plugin/plugin.json` contained a `"category"` field:
```json
{
  "name": "hello-world",
  "version": "1.0.0",
  "description": "...",
  "license": "MIT",
  "category": "learning"   ← not allowed here
}
```
`"category"` is a marketplace-level concept used for discovery and filtering. It
belongs in `marketplace.json` (where it is valid and already present), not in the
plugin's own manifest.

**Fix:**
Removed `"category"` from both `plugin.json` files. The field remains in
`marketplace.json` where it is schema-valid.

---

### Schema Field Reference

| Field | `plugin.json` | `marketplace.json` plugins entry |
|-------|:---:|:---:|
| `name` | required | required |
| `version` | required | required |
| `description` | required | required |
| `source` | — | required |
| `author` | allowed | — |
| `license` | allowed | — |
| `category` | **not allowed** | allowed |
| `tags` | **not allowed** | allowed |
| `components` | **not allowed** | **not allowed** |

---

### Files Changed

| File | Change |
|------|--------|
| `.claude-plugin/marketplace.json` | Created (moved from `marketplace-data/.claude-plugin/`), source paths updated, version bumped to `1.1.0`, `"components"` removed |
| `plugins/hello-world/.claude-plugin/plugin.json` | Removed `"category"` |
| `plugins/dev-tools/.claude-plugin/plugin.json` | Removed `"category"` |
| `marketplace-data/` | Deleted entirely |
| `CLAUDE.md` | Updated registration command and directory structure references |
| `README.md` | Updated project structure diagram and marketplace registration section |
