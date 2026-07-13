---
status: in-progress
created: 2026-03-06
modified: 2026-03-08
---

# Plan: Rename `code-test-suggestion` to `code-testing-agent`

## Context

The plugin `code-test-suggestion` is being renamed to `code-testing-agent` to align with the naming convention established by `code-review-agent` and `git-agent`. This is a **MAJOR** breaking change (v2.2.1 -> v3.0.0) because users who installed `code-test-suggestion@agentics-kit` must reinstall under the new name.

## Steps

### 1. Rename directories (via `git mv`)

- `plugins/code-test-suggestion/` -> `plugins/code-testing-agent/`
- `plugins/code-testing-agent/skills/code-test-suggestion/` -> `plugins/code-testing-agent/skills/code-testing-agent/`

### 2. Update `plugins/code-testing-agent/.claude-plugin/plugin.json`

- `"name"`: `"code-test-suggestion"` -> `"code-testing-agent"`
- `"version"`: `"2.2.1"` -> `"3.0.0"`
- `"homepage"`: update path segment from `code-test-suggestion` to `code-testing-agent`
- `"keywords"`: replace `"test-suggestion"` with `"testing-agent"`

### 3. Update `.claude-plugin/marketplace.json`

- `"name"`: `"code-test-suggestion"` -> `"code-testing-agent"`
- `"source"`: `"./plugins/code-test-suggestion"` -> `"./plugins/code-testing-agent"`
- `"version"`: `"2.2.1"` -> `"3.0.0"`
- `"tags"`: replace `"test-suggestion"` with `"testing-agent"`
- Bump marketplace `agentics-kit` version from `"2.1.0"` to `"2.2.0"`

### 4. Update skill frontmatter

- `plugins/code-testing-agent/skills/code-testing-agent/SKILL.md` line 2: `name: code-test-suggestion` -> `name: code-testing-agent`

### 5. Update reference file

- `plugins/code-testing-agent/skills/code-testing-agent/references/test-analysis-guide.md` line 3: update `code-test-suggestion` -> `code-testing-agent`

### 6. Update README.md

- `plugins/code-testing-agent/README.md`: replace all occurrences of `code-test-suggestion` with `code-testing-agent` (~12 occurrences)

### 7. Add CHANGELOG.md entry

- Add v3.0.0 entry at top of `plugins/code-testing-agent/CHANGELOG.md` with BREAKING CHANGE note

### 8. Update cross-references in `skill-reviewer` plugin

- `plugins/skill-reviewer/README.md` line 186: `(code-test-suggestion plugin)` -> `(code-testing-agent plugin)`
- `plugins/skill-reviewer/skills/running-tests/references/test-runner-guide.md` line 107: same change

### 9. Verify

- `grep -r '"version"' plugins/code-testing-agent/.claude-plugin/ .claude-plugin/marketplace.json` -- both show `3.0.0`
- `grep -r "code-test-suggestion" plugins/ .claude-plugin/ .claude/rules/ --include="*.md" --include="*.json"` -- zero matches
- `grep -r "code-test-suggestion" docs/plans/` -- matches expected (historical, not updated)

## Files NOT changed

- `docs/plans/*.md` -- historical records, left as-is
- `CLAUDE.local.md` -- gitignored; user must update manually
- `reviewing-tests` skill files -- contain no references to old name

## Commit message

```
feat(plugins/code-testing-agent)!: rename plugin from code-test-suggestion — bump to v3.0.0

BREAKING CHANGE: plugin renamed from code-test-suggestion to code-testing-agent.
Users who installed code-test-suggestion@agentics-kit must reinstall as
code-testing-agent@agentics-kit.

Note: Update CLAUDE.local.md plugin loading paths if using local testing.
```

## Interview Summary

### Key Decisions Confirmed

1. **Update keywords/tags**: Replace `"test-suggestion"` with `"testing-agent"` in both `plugin.json` keywords and `marketplace.json` tags
2. **Bump marketplace version**: Bump `agentics-kit` from 2.1.0 to 2.2.0 (minor catalog change)
3. **Commit scope uses new name**: `feat(plugins/code-testing-agent)!:` identifies the resulting plugin
4. **Expanded verification grep**: Add `.claude/rules/` to the stale-reference check (zero matches found there currently)

### Open Risks & Concerns

- **CLAUDE.local.md staleness**: User must manually update local plugin loading paths. Commit message includes a reminder note.

### Recommended Next Steps

- Proceed with implementation — all interview findings have been incorporated into the plan above.
