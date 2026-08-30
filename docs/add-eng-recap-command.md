# Give engineers a recap written for them

> `/artifact-tools:eng-recap` is the third recap command over the session-artifact pipeline, written for the engineer who will touch the code next, leading with technical fact rather than plain-language translation.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [add-eng-recap-command](plans/add-eng-recap-command.md)
**Type:** feature

## What shipped

- New `commands/eng-recap.md` in `artifact-tools` that overrides only framing, reusing the existing session-artifact pipeline for extraction and publishing
- Engineering-first section order: At a glance, Architecture and code paths, Decisions with rationale, Tradeoffs and rejected options, Learnings, Tests and verification, Review follow-ups and tech debt, Files touched
- Audience section explicitly inverts `team-recap`'s plain-language-first rule
- Diff-read budget capping `gh pr diff` at 20 files, with `--name-only` fallback for the remainder and a required summary count
- Unique republish key `eng-artifact-url:` with a never-write warning naming all three sibling keys
- PR mode guarded by the `gh auth status` + GitHub-remote preflight before any `gh pr view` call
- `artifact-tools` bumped to `1.7.0`; smoke test extended with key-collision check and diff-cap assertion

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | New command file — framing overrides only, no new pipeline | Created |
| `tests/plugins/test-artifact-tools.sh` | Extended: `eng-recap.md` added to republish-key map, check 8 raised to ≥ 3 PR-mode commands, diff-cap check added | Modified |
| `.claude-plugin/marketplace.json` | `artifact-tools` version 1.6.0 → 1.7.0 | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | `[1.7.0]` Added entry | Modified |
| `kit/plugins/artifact-tools/README.md` | Commands table, Usage block, Plugin Structure tree, `### eng-recap (command)` subsection | Modified |
| `CLAUDE.md` | `artifact-tools` row updated in reference-implementations table | Modified |

## How it works

`artifact-tools` ships a `session-artifact` skill that extracts, scrubs, and publishes a session summary. Two command files — `product-doc.md` and `team-recap.md` — each override only the framing applied to that pipeline's output. `eng-recap.md` is the third such file and adds no new pipeline logic.

The audience section opens with a statement that inverts `team-recap`'s rule verbatim: where `team-recap` leads with the plain-language statement, `eng-recap` leads with the technical fact. This inversion is stated explicitly so an author cannot drift back to the mixed-audience default.

PR mode is reached the same way as in the sibling commands: the `gh auth status` check and a `git remote get-url origin | grep -qi 'github\.com'` test must both emit `PR_MODE_OK` before any `gh pr view` call runs. The diff-read budget is the one place `eng-recap` departs from its siblings: full hunks via `gh pr diff` are read for at most 20 files; beyond that the fallback switches to `--name-only` and the command must report how many files were summarized rather than read in full.

The republish key `eng-artifact-url:` is unique to this command. A never-write warning in the command file names the three sibling keys (`artifact-url:`, `product-artifact-url:`, `team-artifact-url:`) so a copy-paste from a sibling is caught before it causes a silent overwrite on the shared session record.

Check 7 of `tests/plugins/test-artifact-tools.sh` maintains a map of `{command file: republish key}`. Adding `commands/eng-recap.md`: `eng-artifact-url` to that map means a key collision fails the suite rather than shipping silently. The plan required running the suite against a deliberately broken `eng-recap.md` (key swapped to `team-artifact-url`) to confirm the check has teeth before reverting.

## How to use it

```text
/artifact-tools:eng-recap
/artifact-tools:eng-recap #123
/artifact-tools:eng-recap --pr 123
```

The first form uses the current session artifact. The second and third forms switch to PR mode, reading the PR description, commits, and up to 20 diff files before generating the recap. The artifact is published under the `eng-artifact-url:` key in the shared session record and handed off via `save-artifact`.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `df49b6d` | 2026-08-12 | feat(settings-sync): restore onto a new machine via clone URL (1.1.0) (#548) |

<!-- generated:end -->

## References

- Plan: [add-eng-recap-command](plans/add-eng-recap-command.md)
- Proposal: `docs/proposals/add-eng-recap-command.md`
- Changelog: `kit/plugins/artifact-tools/CHANGELOG.md` — `[1.7.0]`
