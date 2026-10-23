# Give engineers a recap written for them

> Adds `/artifact-tools:eng-recap` — a third recap command over the session-artifact pipeline written for the engineer who has to touch the code next, inverting the plain-language-first rule of its siblings.

<!-- generated:start -->

**Status:** Shipped 2026-07-27  **Plan:** [add-eng-recap-command.md](plans/add-eng-recap-command.md)
**Type:** feature

## What shipped

- Added `kit/plugins/artifact-tools/commands/eng-recap.md` as a third recap command over the existing `session-artifact` pipeline, framed for engineering readers.
- The command leads with technical facts (code paths, invariants, rejected tradeoffs) — the explicit inverse of `team-recap`'s plain-language-first rule.
- All eight agreed sections are present: At a glance, Architecture and code paths, Decisions with rationale, Tradeoffs and rejected options, Learnings, Tests and verification, Review follow-ups and tech debt, Files touched.
- A diff-read budget caps the `gh pr diff` read at 20 files, falling back to `--name-only` for the remainder, to prevent context blowout on large PRs.
- PR mode is guarded by a `gh auth status` + GitHub-remote preflight before any `gh pr view` call.
- The command declares a unique `eng-artifact-url:` republish key and carries an explicit never-write warning naming all three sibling keys, preventing silent overwrites of live pages.
- Extended `tests/plugins/test-artifact-tools.sh` with the `eng-recap.md` entry in the republish-key collision map, a raised sibling-command count assertion, and a new diff-cap check.
- Bumped `artifact-tools` to `1.7.0` in `.claude-plugin/marketplace.json` with a matching CHANGELOG entry.
- Updated `kit/plugins/artifact-tools/README.md` in all four command-listing locations (table, usage block, structure tree, and a new subsection).
- Updated the `artifact-tools` row in the root `CLAUDE.md` reference-implementations table.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | Command file | Created |
| `tests/plugins/test-artifact-tools.sh` | Smoke test | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Changelog | Modified |
| `kit/plugins/artifact-tools/README.md` | Plugin README | Modified |
| `CLAUDE.md` | Root plugin table | Modified |

## How it works

`artifact-tools` ships two recap commands over one shared `session-artifact` pipeline: `product-doc` (stakeholders) and `team-recap` (mixed audience, plain-language-first). `eng-recap` is the third framing: it delegates all transcript extraction, scrubbing, and publishing to the same pipeline and overrides only the audience and section structure.

The audience override is the core of the command. `team-recap` states its rule outright — "Lead every section with the plain-language statement, then the technical detail. Never the reverse." `eng-recap` states the inverse: lead with the technical fact, assume the vocabulary, never translate. This is not a soft preference but a named inversion that a reviewer can verify against the file.

The eight sections are arranged to serve a maintainer: At a glance gives a stat strip (changes, files, decisions, open items) plus landing description; Architecture and code paths maps the code surface; Decisions and Tradeoffs are explicitly separated so the author cannot collapse "we chose X" and "we tried Y and it failed" into one section; Learnings, Tests and verification, Review follow-ups and tech debt, and Files touched round out the engineering picture.

The diff-read budget addresses the one place `eng-recap` departs from both siblings: it reads actual diff hunks (which neither `product-doc` nor `team-recap` do). An uncapped `gh pr diff` on a large PR consumes the context the recap itself needs. The cap-and-summarize policy (≤20 files read in full, `--name-only` for the remainder, reported count of summarized files) mirrors `diff-artifact`'s existing policy.

The `eng-artifact-url:` republish key is unique among the four recap writers. Check 7 of `tests/plugins/test-artifact-tools.sh` maintains a map of all command files to their declared keys; adding a new command without a unique key fails that check immediately, making key collision a CI-level rather than runtime failure.

## How to use it

```text
/artifact-tools:eng-recap
/artifact-tools:eng-recap #123
/artifact-tools:eng-recap --pr 123
```

The command reads the current session by default. Pass a PR number or URL to produce an engineering recap of that pull request instead.

PR mode requires `gh auth status` and a GitHub-remote origin; the preflight emits `PR_MODE_OK` or `PR_MODE_UNAVAILABLE` before any `gh pr view` call.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-eng-recap-command.md](plans/add-eng-recap-command.md)
