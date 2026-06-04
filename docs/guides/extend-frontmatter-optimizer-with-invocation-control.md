# Extend description-optimizer skill to also tune `disable-model-invocation`

> Renames `optimizing-skill-descriptions` to `optimizing-skill-frontmatter` and adds a new step that classifies skills as workflow vs. advisory and applies the correct `disable-model-invocation` value after user confirmation.

<!-- generated:start -->

**Status:** Shipped 2026-05-13  **Plan:** [extend-frontmatter-optimizer-with-invocation-control.md](plans/extend-frontmatter-optimizer-with-invocation-control.md)
**Type:** artifact

## What shipped

- Renamed skill directory `skills/optimizing-skill-descriptions/` → `skills/optimizing-skill-frontmatter/` via `git mv` so git history follows the file (MAJOR version bump — renaming a skill breaks existing invocation paths).
- Updated SKILL.md frontmatter: `name: optimizing-skill-descriptions` → `name: optimizing-skill-frontmatter`; description rewritten to cover both `description` length and `disable-model-invocation` optimization (target: ≤160 chars).
- Added new "Step 4b: Tune invocation control" between existing Step 4 (Apply edits) and Step 5 (Verify results) — classifies each SKILL.md as workflow or advisory using static signals from `allowed-tools` and `description` verbs, prints a compact classification table, and calls `AskUserQuestion` before applying any change.
- Updated Overview, "When not to use", and Table of Contents in SKILL.md to reflect expanded scope.
- Updated all cross-references to the old skill name: `scripts/measure-description.sh` (4 hits), `README.md` (4 hits), `commands/check-description.md` (1 hit).
- Added `## 2.0.0` entry to `CHANGELOG.md` marking the rename and new responsibility as a BREAKING CHANGE.
- Bumped `skill-reviewer` marketplace version from `1.9.0` → `2.0.0` and updated the marketplace description to mention `disable-model-invocation` support.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/skill-reviewer/scripts/measure-description.sh` | Description measurement script | Modified |
| `kit/plugins/skill-reviewer/README.md` | Plugin documentation | Modified |
| `kit/plugins/skill-reviewer/commands/check-description.md` | Command wrapper | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |

## How it works

The skill was previously named `optimizing-skill-descriptions` and had a single job: trim SKILL.md `description:` fields to ≤160 characters while preserving activation accuracy. This plan broadened its scope to also cover the `disable-model-invocation` frontmatter flag — the second lever that controls whether a skill fires automatically on intent match or only on explicit invocation.

The repo already had an established convention: workflow skills (those that commit, write files, push, branch, deploy) set `disable-model-invocation: true`; advisory/read-only skills omit the field. However this convention was unenforced, and new skills could drift without any tooling to surface the mismatch.

Step 4b classifies each touched SKILL.md using two static signals read from the file itself: the `allowed-tools:` line (presence of `Edit`, `Write`, or `Bash` with side-effect verbs indicates workflow; presence only of `Read`, `Glob`, `Grep`, `WebFetch`, `WebSearch`, or `AskUserQuestion` indicates advisory) and the `description:` verb set (commit/push/ship/branch/deploy/generate/scaffold signal workflow; review/audit/check/analyze/score/advise signal advisory). When both signals agree, the recommendation is marked "confident"; when they disagree or are mixed, the recommendation is marked "ambiguous" and both signals are surfaced in the prompt.

The classification output is a compact table — path, current value, recommendation, confidence, and a one-line reason. Per the user's "always confirm" policy, every proposed change goes through an `AskUserQuestion` call with options Apply recommendations / Pick per file / Skip invocation changes. This fires even for confident recommendations. Choosing Skip leaves all files untouched.

When applying, the skill either inserts `disable-model-invocation: true` on a new line after the `allowed-tools:` line, or deletes an existing `disable-model-invocation: true` line when the heuristic says omit. It never writes `disable-model-invocation: false` — matching the repo convention of omitting the field for advisory skills.

The rename required updating four string occurrences in `measure-description.sh` — the WARNING output lines that tell users which skill to run when they find over-budget descriptions. Without that update, the script would direct users to a skill that no longer exists by that name. The README, command doc, and CHANGELOG were updated in the same pass.

## How to use it

The skill is invoked as `/skill-reviewer:optimizing-skill-frontmatter`. It operates on one or more SKILL.md files passed as targets or discovered in the current session context.

When the skill completes Step 4 (description edits), it automatically runs Step 4b: prints the classification table and prompts once for how to handle `disable-model-invocation` across all touched files. Select **Apply recommendations** to apply all confident recommendations automatically, **Pick per file** to decide each one individually, or **Skip invocation changes** to ignore the new step entirely.

The `measure-description.sh` script also emits a WARNING with the correct new invocation path when it detects over-budget descriptions:

```bash
bash kit/plugins/skill-reviewer/scripts/measure-description.sh <path-to-SKILL.md>
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `2d91c96` | 2026-05-13 | fix(skill-reviewer): scope disable-model-invocation grep to frontmatter block |
| `5f8e038` | 2026-05-13 | fix(skill-reviewer): use concrete grep-first Edit pattern for disable-model-invocation |
| `1f3bf66` | 2026-05-13 | fix: address code review feedback on fix-branch command and skill docs |
| `b7a2e74` | 2026-05-13 | feat(skill-reviewer): polish frontmatter optimizer and mark plan completed |
| `7414135` | 2026-05-12 | feat(skill-reviewer)!: rename optimizing-skill-descriptions → optimizing-skill-frontmatter and add disable-model-invocation tuning (v2.0.0) |

<!-- generated:end -->

## References

- Plan: [extend-frontmatter-optimizer-with-invocation-control.md](plans/extend-frontmatter-optimizer-with-invocation-control.md)
