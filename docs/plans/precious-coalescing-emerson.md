# Plan: Rename Skill `code-review` → `code-review-agent`

## Context

The `code-review` skill in `plugins/code-review` conflicts by name with Anthropic's built-in `code-review` skill. Renaming the skill's `name` field (and its directory) to `code-review-agent` disambiguates the two.

The plugin itself (`name: "code-review"` in `plugin.json`) does **not** change — only the skill identifier changes.

## Steps

1. **Rename skill directory**
   - `plugins/code-review/skills/code-review/` → `plugins/code-review/skills/code-review-agent/`

2. **Update SKILL.md frontmatter**
   - File: `plugins/code-review/skills/code-review-agent/SKILL.md`
   - Change `name: code-review` → `name: code-review-agent`

3. **Update README.md**
   - File: `plugins/code-review/README.md`
   - Update skill name in the activation table: `` `code-review` `` → `` `code-review-agent` ``

4. **Bump version — MAJOR** (renaming a skill is a breaking change per project rules)
   - `plugins/code-review/.claude-plugin/plugin.json`: `1.2.0` → `2.0.0`
   - `.claude-plugin/marketplace.json`: update matching entry `1.2.0` → `2.0.0`

5. **Update CHANGELOG.md**
   - File: `plugins/code-review/CHANGELOG.md`
   - Add entry for v2.0.0: BREAKING CHANGE — skill renamed from `code-review` to `code-review-agent`

## Critical Files

| File | Change |
|------|--------|
| `plugins/code-review/skills/code-review-agent/SKILL.md` | Rename dir + update `name:` field |
| `plugins/code-review/README.md` | Update skill name in table |
| `plugins/code-review/.claude-plugin/plugin.json` | Bump version 1.2.0 → 2.0.0 |
| `.claude-plugin/marketplace.json` | Bump version 1.2.0 → 2.0.0 |
| `plugins/code-review/CHANGELOG.md` | Add v2.0.0 entry |

## Verification

1. Confirm the old directory `skills/code-review/` no longer exists
2. Confirm `skills/code-review-agent/SKILL.md` has `name: code-review-agent`
3. Verify version sync: `grep -r '"version"' plugins/code-review/.claude-plugin/ .claude-plugin/marketplace.json`
4. Load the plugin locally and confirm the skill activates on a code review request:
   ```bash
   claude --plugin-dir ~/devbox/agentics/plugins/code-review
   ```
