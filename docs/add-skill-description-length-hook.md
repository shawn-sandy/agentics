# SKILL.md description-length warning — hook + command

> Adds an always-on PostToolUse hook, a `/skill-reviewer:check-description` command, and a shared measurement script to warn when a SKILL.md `description:` frontmatter field exceeds the 160-char context-budget limit.

<!-- generated:start -->

**Status:** Shipped 2026-05-11  **Plan:** [add-skill-description-length-hook.md](plans/add-skill-description-length-hook.md)
**Type:** artifact

## What shipped

- Created `kit/plugins/skill-reviewer/scripts/measure-description.sh` as the single source of truth for description measurement, emitting `OK:`, `WARNING:`, or `ERROR:` prefixed lines; committed with executable bit (`100755`).
- Created `kit/plugins/skill-reviewer/hooks.json` registering a PostToolUse hook matching `Write|Edit|MultiEdit`, with jq fallback for MultiEdit's `edits[0].file_path` payload shape, a repo-local guard via `git rev-parse --show-toplevel`, and dedup via `/tmp` hash state so the hook only fires when the `description:` line actually changes.
- Created `kit/plugins/skill-reviewer/commands/check-description.md` providing `/skill-reviewer:check-description [path-or-glob]` for ad-hoc and batch checks (calls the same shared script as the hook).
- Created `tests/fixtures/skill-description-hook/` with five fixture SKILL.md files (`desc-160.md`, `desc-161.md`, `desc-200.md`, `desc-missing.md`, `desc-multiline.md`) and a bash harness (`run.sh`) asserting expected output prefixes and character counts.
- Audited and trimmed all existing over-budget `kit/plugins/**/SKILL.md` descriptions as a pre-step so the hook lands on a clean baseline (zero warnings on pre-existing content).
- Updated `kit/plugins/skill-reviewer/README.md` with Hooks section, Commands entry, shared script note, audit history, and disable instructions.
- Appended a MINOR-bump entry to `kit/plugins/skill-reviewer/CHANGELOG.md` covering hook, command, shared script, test fixture, and audit.
- Bumped `skill-reviewer` version in `.claude-plugin/marketplace.json` (MINOR).

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/skill-reviewer/scripts/measure-description.sh` | Shared measurement script | Created |
| `kit/plugins/skill-reviewer/hooks.json` | Plugin manifest (hooks) | Created |
| `kit/plugins/skill-reviewer/commands/check-description.md` | Command wrapper | Created |
| `tests/fixtures/skill-description-hook/desc-160.md` | Test fixture | Created |
| `tests/fixtures/skill-description-hook/desc-161.md` | Test fixture | Created |
| `tests/fixtures/skill-description-hook/desc-200.md` | Test fixture | Created |
| `tests/fixtures/skill-description-hook/desc-missing.md` | Test fixture | Created |
| `tests/fixtures/skill-description-hook/desc-multiline.md` | Test fixture | Created |
| `tests/fixtures/skill-description-hook/run.sh` | Test harness | Created |
| `kit/plugins/skill-reviewer/README.md` | Plugin documentation | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |

## How it works

The rationale for the 160-char budget comes from the `optimizing-descriptions` skill: Claude Code's default `skillListingBudgetFraction` allocates roughly 1% of context (~8,000 chars for ~50 skills), which works out to ~160 chars per description. Over-budget descriptions risk truncation or being dropped from the skill listing at runtime.

`scripts/measure-description.sh` takes a single file path argument and applies the same extract-strip parameter expansion defined in Step 5 of `optimizing-descriptions/SKILL.md`. It detects multi-line descriptions by checking whether the stripped value is empty and the following line is indented. Output is a single stdout line with an `OK:`, `WARNING:`, or `ERROR:` prefix and always exits 0 for measurable cases.

`hooks.json` fires after every `Write`, `Edit`, or `MultiEdit` tool use. The hook shell command extracts the file path from the event payload via `jq`, falling back to `edits[0].file_path` for MultiEdit. It skips non-SKILL.md paths immediately. A repo-local guard runs `git -C "$(dirname "$file")" rev-parse --show-toplevel` — files outside the current git repository (e.g., externally installed plugins at `~/.claude/plugins/`) are silently skipped. The dedup mechanism hashes the literal `description:` line and stores it at `/tmp/skill-desc-hook-<sha256-of-path>.hash`; the hook fires only when the hash changes, preventing noise on unrelated saves.

The `/skill-reviewer:check-description` command resolves target files — defaulting to all `**/SKILL.md` via Glob when called with no argument, or accepting a path or glob pattern — and calls the same shared script for each. This provides on-demand batch auditing without duplicating measurement logic.

The five test fixtures in `tests/fixtures/skill-description-hook/` cover the boundary cases: exactly 160 chars (OK), exactly 161 chars (WARNING), 200 chars (WARNING), no `description:` line (ERROR), and a folded YAML scalar (`description: |`, WARNING multi-line). The `run.sh` harness calls `scripts/measure-description.sh` directly and asserts on expected output prefixes — it tests the shared script surface, not the hook's dedup or repo-guard logic, which requires a live Claude session.

## How to use it

```
# On-demand check for a single file
/skill-reviewer:check-description kit/plugins/my-plugin/skills/my-skill/SKILL.md

# Batch check all SKILL.md files from the repo root
/skill-reviewer:check-description
```

The hook runs automatically on every SKILL.md write within the current repository. To disable it, override the `hooks` key in your user `~/.claude/settings.json`. Existing over-budget descriptions were trimmed before the hook shipped, so a clean install produces no immediate warnings.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `20e530f` | 2026-05-11 | feat(skill-reviewer): add description-length hook, command, and test fixtures (#104) |
| `a22807d` | 2026-05-12 | refactor(plugins/skill-reviewer): rename optimizing-descriptions skill |
| `7414135` | 2026-05-12 | feat(skill-reviewer)!: rename optimizing-skill-descriptions → optimizing-skill-frontmatter and add disable-model-invocation tuning (v2.0.0) |

<!-- generated:end -->

## References

- Plan: [add-skill-description-length-hook.md](plans/add-skill-description-length-hook.md)
