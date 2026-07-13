---
status: in-progress
created: 2026-02-23
modified: 2026-02-26
---

# Plan: Update CLAUDE.md to Reflect 5-Plugin Marketplace

## Context

The CLAUDE.md was last updated when the repo had 2 plugins (hello-world, dev-tools). Three new plugins were added (claude-md-optimizer, code-review, plan-interview) and dev-tools was refactored in commit `307f69b` to extract skills into standalone plugins. The CLAUDE.md is now stale and inaccurate, misrepresenting dev-tools as "Commands + skills" and omitting 3 plugins entirely.

**Score before:** 72/100 (Grade C+) — primarily due to currency and accuracy gaps.

## Files to Modify

- `CLAUDE.md` — sole file requiring updates

## Changes

### 1. Fix Reference Implementations section

**Problem:** Lists only 2 plugins, dev-tools described incorrectly as commands+skills.

Replace:
```
- **Minimal Plugin:** `plugins/hello-world/` — Single command, basic structure
- **Multi-Component:** `plugins/dev-tools/` — Commands + skills working together
- **Marketplace Config:** `.claude-plugin/marketplace.json` — Plugin registry example
- **Valid Test Fixture:** `tests/fixtures/valid-plugin/` — Validation reference
```

With:
```
- **Minimal Plugin:** `plugins/hello-world/` — Single command, basic structure
- **Commands Only:** `plugins/dev-tools/` — Formatting commands (skills extracted in v2.0)
- **Skills Only:** `plugins/claude-md-optimizer/` — Auto-activated CLAUDE.md auditing skill
- **Skills Only:** `plugins/code-review/` — Auto-activated code review skill
- **Mixed (commands + skills):** `plugins/plan-interview/` — Plan interview command and skill
- **Marketplace Config:** `.claude-plugin/marketplace.json` — Plugin registry (agentics-kit v2.0.0)
- **Valid Test Fixture:** `tests/fixtures/valid-plugin/` — Validation reference
```

### 2. Update Local Development section

**Problem:** Install examples only cover dev-tools; no examples for 3 new plugins. No "load all" shortcut.

Add after existing load examples, before the marketplace commands:
```bash
# Load all plugins
claude --plugin-dir ~/devbox/agentics/plugins/hello-world \
  --plugin-dir ~/devbox/agentics/plugins/dev-tools \
  --plugin-dir ~/devbox/agentics/plugins/claude-md-optimizer \
  --plugin-dir ~/devbox/agentics/plugins/code-review \
  --plugin-dir ~/devbox/agentics/plugins/plan-interview
```

Add after `/plugin install dev-tools@agentics-kit`:
```bash
/plugin install claude-md-optimizer@agentics-kit
/plugin install code-review@agentics-kit
/plugin install plan-interview@agentics-kit
```

## Verification

- Read updated CLAUDE.md and confirm all 5 plugins are listed accurately
- Verify dev-tools is no longer described as "commands + skills"
- Confirm install commands cover all 5 plugins
- Check that plugin component descriptions match actual directory contents (`ls plugins/*/`)
