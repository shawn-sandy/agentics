# Rename Skill `test-review` → `reviewing-tests`

> Renames the `test-review` skill to `reviewing-tests` in the `code-test-suggestion` plugin to follow the gerund naming convention; PATCH version bump to 2.2.1.

<!-- generated:start -->

**Status:** Shipped 2026-03-02   **Plan:** [enhance-installation-instructions.md](plans/enhance-installation-instructions.md)   **Type:** standard

## What shipped

- Skill directory renamed from `skills/test-review/` to `skills/reviewing-tests/`.
- `SKILL.md` frontmatter name updated: `name: test-review` → `name: reviewing-tests`.
- `references/test-quality-checklist.md` self-description updated to reference the new skill name.
- `plugin.json` keywords updated: `"test-review"` → `"reviewing-tests"`.
- `README.md` updated — all references to `test-review` replaced with `reviewing-tests`.
- `CHANGELOG.md` updated with a `v2.2.1` entry.
- `marketplace.json` tags updated and version bumped to `2.2.1`.

> See [CHANGELOG §2.2.1](../kit/plugins/code-testing-agent/CHANGELOG.md) for the authoritative change log entry.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `plugins/code-test-suggestion/skills/test-review/` | Skill directory | Renamed → `reviewing-tests/` |
| `plugins/code-test-suggestion/skills/reviewing-tests/SKILL.md` | Skill instructions | Modified (name field) |
| `plugins/code-test-suggestion/skills/reviewing-tests/references/test-quality-checklist.md` | Reference file | Modified (self-description) |
| `plugins/code-test-suggestion/.claude-plugin/plugin.json` | Plugin manifest | Modified (keywords + version 2.2.1) |
| `plugins/code-test-suggestion/README.md` | Plugin documentation | Modified (5 references updated) |
| `plugins/code-test-suggestion/CHANGELOG.md` | Version history | Modified (2.2.1 entry) |
| `.claude-plugin/marketplace.json` | Marketplace registry | Modified (tags + version 2.2.1) |

## How it works

Skills in Claude Code activate by description matching, not by the `name` field — `name` is internal metadata only. Renaming `test-review` to `reviewing-tests` therefore carries no user-facing contract change and qualifies as a PATCH bump. The change aligns the skill with the gerund convention used by other skills in the repo (`reviewing-skills`, `code-testing-agent`, etc.).

The rename required touching seven files: the directory itself, the SKILL.md frontmatter, the reference file's self-description string, `plugin.json` keywords, README prose, CHANGELOG, and marketplace tags. No activation phrases or description text changed.

Note: The `code-test-suggestion` plugin was subsequently renamed to `code-testing-agent` (v3.0.0, 2026-03-06), so these files now live under `kit/plugins/code-testing-agent/`.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |

<!-- generated:end -->

## References

- Plan: [enhance-installation-instructions.md](plans/enhance-installation-instructions.md)
- Changelog: [kit/plugins/code-testing-agent/CHANGELOG.md §2.2.1](../kit/plugins/code-testing-agent/CHANGELOG.md)
