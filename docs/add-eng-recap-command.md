# Give engineers a recap written for them

> Adds `/artifact-tools:eng-recap` — a third recap command over the session-artifact pipeline, written for the engineer who has to touch the code next.

<!-- generated:start -->

**Status:** Shipped 2026-07-27  **Plan:** [add-eng-recap-command.md](plans/add-eng-recap-command.md)
**Type:** feature

## What shipped

- Added `kit/plugins/artifact-tools/commands/eng-recap.md` as the third recap command over the shared `session-artifact` pipeline, with engineer-first framing (lead with technical fact, not plain language).
- The command defines eight sections: At a glance, Architecture and code paths, Decisions with rationale, Tradeoffs and rejected options, Learnings, Tests and verification, Review follow-ups and tech debt, and Files touched.
- Added a diff-read budget: reads full hunks for up to 20 files via `gh pr diff`, falls back to `--name-only` for the remainder, and reports how many files were summarized.
- Declared `eng-artifact-url:` as the command's republish key with an explicit never-write warning naming the other three sibling keys (`artifact-url:`, `product-artifact-url:`, `team-artifact-url:`).
- Extended `tests/plugins/test-artifact-tools.sh` with a key-collision check (check 7's `owners` map), raised check 8's assertion to `>= 3` PR-mode commands, and added a diff-cap check.
- Bumped `artifact-tools` to `1.7.0` in `.claude-plugin/marketplace.json` with a matching CHANGELOG entry and updated the README in all four places it lists commands.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/artifact-tools/commands/eng-recap.md` | Command file | Created |
| `tests/plugins/test-artifact-tools.sh` | Smoke test | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/artifact-tools/README.md` | Plugin documentation | Modified |
| `CLAUDE.md` | Root plugin reference table | Modified |

## How it works

`eng-recap` is a command file that wraps the existing `session-artifact` pipeline, overriding only the framing layer. It explicitly inverts the `team-recap` rule — where `team-recap` leads every section with plain language, `eng-recap` leads with the technical fact and reserves plain language as optional context after it.

PR mode is guarded by the same `gh auth status` + `git remote get-url origin | grep -qi 'github.com'` preflight that `product-doc` uses. When both gates pass (`PR_MODE_OK`), the command can pull from a PR number or URL in addition to the session default.

The diff-read budget is the one departure from both siblings: `gh pr diff` is called with a 20-file cap. For files beyond that limit the command falls back to `--name-only` and reports the count of summarized files. This prevents context blowout on large PRs, modelled on `diff-artifact`'s existing cap-and-summarize policy.

The republish-key discipline is enforced at two levels: the command declares `eng-artifact-url:` and carries a never-write warning, and check 7 of the smoke test maintains an `owners` map that cross-checks every writer against the session record's key space — a command whose key is swapped for a sibling's fails the check.

## How to use it

Activate with `/artifact-tools:eng-recap`. Reads from the current session by default; pass `#<n>`, a GitHub PR URL, or `--pr <n>` to pull from a specific PR when the GitHub remote is reachable.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [add-eng-recap-command.md](plans/add-eng-recap-command.md)
