---
status: in-progress
created: 2026-02-23
modified: 2026-02-26
---

# Plan: Improve CLAUDE.md Accuracy — agentics project

## Context

The project's CLAUDE.md has drifted from the current codebase state after the dev-tools plugin was expanded (adding two new skills and renaming a command from `plan-review` to `plan-interview`) and the marketplace was renamed from `agentics-test` to `agentics-kit`. Copy-paste commands in the file will silently fail or install the wrong target. The goal is targeted accuracy fixes plus trimming two stale/speculative sections.

---

## Quality Report Summary

**Score: 73/100 (Grade: B-)** — one file: `./CLAUDE.md`

| Criterion | Score | Notes |
|-----------|-------|-------|
| Commands/workflows | 14/20 | Two `plan-review` refs and one `agentics-test` break copy-paste |
| Architecture clarity | 16/20 | Good overview; marketplace-data/ empty so skip |
| Non-obvious patterns | 12/15 | Version sync and discovery flow well documented |
| Conciseness | 8/15 | 357 lines; plugin creation walkthrough is redundant; Future API section is stale |
| Currency | 10/15 | Stale command name, wrong marketplace ID, missing 2 skills |
| Actionability | 13/15 | Most commands copy-paste ready, but wrong names undermine trust |

---

## Implementation Steps

### 1. Fix command name: `plan-review` → `plan-interview` (2 occurrences)

**Line 82:**
```diff
-# Load dev-tools (includes format, plan-review commands + code-review skill)
+# Load dev-tools (includes format, plan-interview commands + code-review, claude-md-optimizer, plan-interview skills)
```

**Line 120:**
```diff
-# /dev-tools:plan-review path/to/plan.md
+# /dev-tools:plan-interview path/to/plan.md
```

### 2. Fix marketplace name: `agentics-test` → `agentics-kit` (1 occurrence)

**Line 95:**
```diff
-/plugin install dev-tools@agentics-test
+/plugin install dev-tools@agentics-kit
```

### 3. Remove "Future API Integration Notes" section

Lines ~297-306 — entire section describing unimplemented API endpoints. Remove completely. Section is speculative and not actionable.

### 4. Trim "Creating New Example Plugins" walkthrough

Lines ~125-158 — 35-line shell walkthrough duplicates the Plugin Structure and Plugin Component Patterns sections already below it. Replace with a short pointer:

```markdown
### Creating New Example Plugins

Follow the Plugin Structure and Plugin Component Patterns sections below. Then register the plugin in `.claude-plugin/marketplace.json`.
```

### 5. (Post-implementation) Verify Claude minimum version

The file currently states "Minimum Claude Code Version Required: 1.0.33 or later". Verify this is still the accurate minimum for plugin support; update if needed.

---

## Additional Concerns (Surfaced in Interview)

- **test/fixtures README references non-existent code**: `tests/fixtures/README.md` mentions `loadPlugin()`, `vitest`, and docs (`docs/plugin-schema.md`) that don't exist. Not a CLAUDE.md issue, but the fixture README is misleading — document-only concern.
- **Minimum Claude version may be stale**: 1.0.33 was documented; given the project date (Feb 2026), this may be outdated and should be verified against current Claude Code release notes.

---

## Files to Modify

- `./CLAUDE.md` — 4 targeted edits (two string replacements, one section removal, one section trim)

## Verification

```bash
# After applying — should return 0 matches
grep -n "plan-review\|agentics-test" CLAUDE.md

# Should return matches in correct locations
grep -n "plan-interview\|agentics-kit" CLAUDE.md

# Confirm removed section is gone
grep -n "Future API Integration" CLAUDE.md
```
