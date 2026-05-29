---
status: completed
type: standard
created: 2026-03-02
---

# Plan: Rename Skill `test-review` → `reviewing-tests`

## Context

The `test-review` skill in `plugins/code-test-suggestion` uses a noun-noun naming pattern. Per skill authoring best practices, the gerund form (`reviewing-tests`) is preferred for skills (which describe ongoing actions rather than nouns). Renaming the skill requires updates to the directory, frontmatter, metadata files, and documentation.

Skills are auto-activated by description matching — the `name` field is internal metadata only, not user-facing. Renaming it is **not a breaking change**. This requires a **PATCH version bump**: `2.2.0` → `2.2.1`.

---

## Files to Modify

| File | Change |
|------|--------|
| `plugins/code-test-suggestion/skills/test-review/` | Rename directory to `reviewing-tests/` |
| `plugins/code-test-suggestion/skills/reviewing-tests/SKILL.md` | Frontmatter: `name: test-review` → `name: reviewing-tests` |
| `plugins/code-test-suggestion/skills/reviewing-tests/references/test-quality-checklist.md` | Update self-reference text |
| `plugins/code-test-suggestion/.claude-plugin/plugin.json` | Keywords: replace `"test-review"` with `"reviewing-tests"`; bump version to `2.2.1` |
| `plugins/code-test-suggestion/README.md` | Update 4 references to `test-review` |
| `plugins/code-test-suggestion/CHANGELOG.md` | Add `v3.0.0` entry |
| `.claude-plugin/marketplace.json` | Tags: replace `"test-review"` with `"reviewing-tests"`; bump version to `2.2.1` |

---

## Steps

1. **Rename directory**
   - `plugins/code-test-suggestion/skills/test-review/` → `skills/reviewing-tests/`

2. **Update SKILL.md frontmatter**
   - File: `skills/reviewing-tests/SKILL.md`
   - Change: `name: test-review` → `name: reviewing-tests`

3. **Update reference file self-description**
   - File: `skills/reviewing-tests/references/test-quality-checklist.md`
   - Change: "Loaded by the test-review skill" → "Loaded by the reviewing-tests skill"

4. **Update plugin.json**
   - File: `plugins/code-test-suggestion/.claude-plugin/plugin.json`
   - Replace `"test-review"` with `"reviewing-tests"` in keywords
   - Bump `"version"` from `"2.2.0"` to `"2.2.1"`

5. **Update README.md**
   - File: `plugins/code-test-suggestion/README.md`
   - Update all 4 references: lines 18, 60, 94, 104, 143

6. **Add CHANGELOG entry**
   - File: `plugins/code-test-suggestion/CHANGELOG.md`
   - Add `v2.2.1` entry noting the internal rename of `test-review` → `reviewing-tests` (non-breaking)

7. **Update marketplace.json**
   - File: `.claude-plugin/marketplace.json`
   - Replace `"test-review"` with `"reviewing-tests"` in tags
   - Bump version for `code-test-suggestion` entry from `"2.2.0"` to `"3.0.0"`

8. **Commit**
   - Message: `fix(plugins/code-test-suggestion): rename skill test-review to reviewing-tests — bump to v2.2.1`
   - Include plan file in commit

---

## Verification

1. Confirm both versions match:
   ```bash
   grep -r '"version"' plugins/code-test-suggestion/.claude-plugin/ .claude-plugin/marketplace.json
   ```
2. Confirm no remaining references to `test-review` as a skill name (allow CHANGELOG history):
   ```bash
   grep -r "test-review" plugins/code-test-suggestion/ --include="*.md" --include="*.json"
   ```
3. Load plugin locally and verify the skill activates under its new name:
   ```bash
   claude --plugin-dir ~/devbox/agentics/plugins/code-test-suggestion
   ```

---

## Unresolved Questions

1. ~~Is the skill `name` field user-facing?~~ **Resolved:** `name` is internal metadata; skills activate by description match only. Rename is a PATCH bump.
2. Is the README reference count 4 or 5? Line numbers listed: 18, 60, 94, 104, 143 — implementer should grep to confirm.
3. Should the `code-test-suggestion` skill also be renamed for consistency, or explicitly deferred?

---

## Interview Summary

### Key Decisions Confirmed

- Rename `skills/test-review/` directory and all internal references to `reviewing-tests`
- Update `plugin.json` keywords, `marketplace.json` tags, README, and CHANGELOG
- Include plan file in the commit

### Open Risks & Concerns

1. **Semver classification** — MAJOR (3.0.0) is stated but may not be correct; skill auto-activation is description-driven, not name-driven. Clarify whether `name` is a user-facing contract before locking in 3.0.0.
2. **README reference count** — Plan says "4 references" but lists 5 line numbers (18, 60, 94, 104, 143). One is wrong; should be resolved before implementation.
3. **Verification command false positives** — The grep will hit CHANGELOG history and produce misleading output. Scope it to exclude CHANGELOG.
4. **Companion skill consistency** — `code-test-suggestion` remains noun-noun; the plan creates an internal inconsistency without acknowledging it.

### Recommended Next Steps

1. Confirm whether skill `name` is a user-facing contract — determines correct semver bump.
2. Fix the README reference count in the plan (4 vs. 5 line numbers).
3. Tighten the verification grep: exclude CHANGELOG explicitly.
4. Decide whether the `code-test-suggestion` skill rename is in scope or explicitly deferred.

### Simplification Opportunities

- ~~MAJOR bump~~ **Resolved:** Downgraded to PATCH (2.2.1). The `name` field is internal metadata; skill auto-activation is description-driven. No user-facing contract is broken.
