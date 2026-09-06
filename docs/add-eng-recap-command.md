# Give engineers a recap written for them

> Adds `/artifact-tools:eng-recap` — a third recap command over the session-artifact pipeline, authored for the engineer who touches the code next, leading with technical facts rather than plain-language summaries.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [add-eng-recap-command.md](plans/add-eng-recap-command.md)
**Type:** feature

## What shipped

- Created `kit/plugins/artifact-tools/commands/eng-recap.md` — a new command that overrides only the framing of the `session-artifact` pipeline, adding no new extraction, scrubbing, or publishing logic (keeping the shared pipeline intact and avoiding code duplication).
- Defined an audience section that explicitly inverts `team-recap`'s plain-language-first rule: technical facts lead, plain-language translation follows.
- Added eight agreed sections: At a glance, Architecture and code paths, Decisions with rationale, Tradeoffs and rejected options, Learnings, Tests and verification, Review follow-ups and tech debt, Files touched.
- Declared a unique `eng-artifact-url:` republish key with an explicit never-write warning naming all three sibling keys, preventing silent overwrites of live recap pages.
- Added PR mode guarded by the `gh auth status` + GitHub-remote preflight before any `gh pr view` call (matching the sibling command pattern).
- Implemented a diff-read budget: read full hunks for up to 20 files, fall back to `--name-only` for the remainder, and report how many files were summarized — preventing context blowout that uncapped `gh pr diff` causes.
- Extended `tests/plugins/test-artifact-tools.sh`: added `eng-recap.md` to the republish-key collision map (check 7), raised the PR-mode command count assertion, and added a diff-cap check.
- Bumped `artifact-tools` to `1.7.0` in `marketplace.json` with a `[1.7.0]` CHANGELOG entry.
- Updated `kit/plugins/artifact-tools/README.md` in all four locations (Commands table, Usage block, Plugin Structure tree, and a new `### eng-recap (command)` subsection) and the root `CLAUDE.md` plugin table.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | New command — engineering-audience framing | Created |
| `tests/plugins/test-artifact-tools.sh` | Smoke test — collision guard, PR-mode count, diff-cap | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Release notes — 1.7.0 entry | Modified |
| `kit/plugins/artifact-tools/README.md` | Plugin documentation — four-location update | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version bump to 1.7.0 | Modified |
| `CLAUDE.md` | Root plugin table — eng-recap row | Modified |

## How it works

**Framing-only design.** `eng-recap.md` overrides only the framing of the `session-artifact` pipeline: audience, sections, and republish key. It contains no copy of the transcript extraction, scrubbing, or `save-artifact` delivery logic. This keeps the pipeline as the single source of truth for how a session is read and published, and means the command degrades correctly if the pipeline changes.

**Inverted audience rule.** The audience section explicitly states the inversion of `team-recap`'s rule: lead with the technical fact, not the plain-language statement. This prevents an author from inadvertently writing a `team-recap` with a different title — the inversion is stated as such rather than restating the rule in opposite words.

**Diff-read budget.** For PR mode, the command reads full diff hunks via `gh pr diff` for at most 20 files. Files beyond that cap are covered with `--name-only` and the count of summarized files is reported in the output. This mirrors the cap-and-summarize policy in `diff-artifact/SKILL.md` and prevents the diff read from consuming context the recap itself needs.

**Republish-key isolation.** The shared session record stores each recap writer's artifact URL under a distinct frontmatter key. `eng-recap` declares `eng-artifact-url:` and carries a never-write warning naming `artifact-url:`, `product-artifact-url:`, and `team-artifact-url:`. Check 7 of the smoke test enforces this by maintaining an owners map that each command must appear in — a command absent from the map or using a sibling's key fails the check.

**Test validity.** Step 4 of the plan required deliberately breaking the command (swapping `eng-artifact-url` for `team-artifact-url`) and confirming the suite fails on the key collision before reverting. This ensures the collision check is real rather than decorative.

## How to use it

Activation trigger: `/artifact-tools:eng-recap`

```
# Recap the current session for an engineering audience
/artifact-tools:eng-recap

# Recap a specific PR by number
/artifact-tools:eng-recap #42

# Recap a PR by URL
/artifact-tools:eng-recap https://github.com/org/repo/pull/42
```

PR mode requires `gh auth status` and a GitHub remote — the command checks both before any `gh pr view` call. The recap is saved via the `save-artifact` handoff with stem `eng-recap` (session) or `pr-<number>-eng` (PR mode) and keyed under `eng-artifact-url:` in the shared session record.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `e1e8840` | 2026-08-15 | feat(git-agent): add post-merge-cleanup skill (4.19.0) (#565) |

<!-- generated:end -->

## References

- Plan: [add-eng-recap-command.md](plans/add-eng-recap-command.md)
