# Give engineers a recap written for them

> `/artifact-tools:eng-recap` is the third recap command over the session-artifact pipeline, written for the engineer who has to touch the code next — leading with technical facts rather than translating for non-engineers.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-eng-recap-command.md](plans/add-eng-recap-command.md)
**Type:** feature

## What shipped

- Added `kit/plugins/artifact-tools/commands/eng-recap.md` — a new command that overrides framing only without reimplementing the session-artifact pipeline
- Audience section explicitly inverts `team-recap`'s plain-language-first rule: lead with the technical fact, never the translation
- Eight sections defined: At a glance (stat strip + where the work landed), Architecture and code paths, Decisions with rationale, Tradeoffs and rejected options, Learnings, Tests and verification, Review follow-ups and tech debt, Files touched
- Diff-read budget added under Source: full hunks via `gh pr diff` for at most 20 files, `--name-only` fallback for the remainder, with a report of how many files were summarized
- `eng-artifact-url:` republish key declared with an explicit never-write warning naming the three sibling keys to prevent silent overwrites on the shared session record
- PR mode guarded by `gh auth status` + github.com-remote preflight before any `gh pr view`
- `tests/plugins/test-artifact-tools.sh` extended: check 7's owners map, check 8 raised to `>= 3` PR-mode commands, new diff-cap check
- `artifact-tools` bumped to `1.7.0` in `.claude-plugin/marketplace.json` with matching CHANGELOG entry
- README updated in all four locations: Commands table, Usage block, Plugin Structure tree, `### eng-recap (command)` subsection
- `CLAUDE.md` plugin reference table updated

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | Command instructions — framing overrides over session-artifact pipeline | Created |
| `tests/plugins/test-artifact-tools.sh` | Smoke test — extended owners map, PR-mode count, diff-cap assertions | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry — version 1.7.0 | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Release notes — 1.7.0 entry | Modified |
| `kit/plugins/artifact-tools/README.md` | Plugin documentation — four locations updated | Modified |

## How it works

`eng-recap` is implemented as a framing-only override over the existing `session-artifact` pipeline. Rather than reimplementing extraction, scrubbing, or publishing, the command file specifies only Audience and Sections, then hands off to `save-artifact` for delivery.

The audience rule is stated as an explicit inversion of `team-recap`'s constraint: "Lead every section with the technical fact — the inverse of team-recap's rule." This makes the override's purpose legible to future maintainers reading both files.

The diff-read budget departs from both siblings. `eng-recap` reads full `gh pr diff` hunks for at most 20 files, falls back to `--name-only` for the rest, and reports the count. This keeps the technical depth a maintainer needs while preventing the context blowout that derailed earlier approaches.

The republish-key discipline uses `eng-artifact-url:` as the unique key for the shared session record, with a never-write warning naming `artifact-url:`, `product-artifact-url:`, and `team-artifact-url:`. Check 7 of `test-artifact-tools.sh` asserts every command in the owners map has its own unique key, making a silent collision a test failure rather than a runtime surprise.

## How to use it

`eng-recap` is invoked as a command in the artifact-tools plugin:

```
/artifact-tools:eng-recap                # recap from current session
/artifact-tools:eng-recap #42            # recap from PR #42
/artifact-tools:eng-recap --pr 42        # same, explicit flag form
```

The command auto-detects PR mode if `gh auth status` passes and the remote is a GitHub URL. In session mode it reads the session JSONL; in PR mode it reads commit messages plus diff hunks (up to 20 files, `--name-only` for the rest).

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `174d0ef` | 2026-10-27 | fix(marketplace): resolve claude.ai plugin validation issues (#660) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-eng-recap-command.md](plans/add-eng-recap-command.md)
- Related: `kit/plugins/artifact-tools/commands/team-recap.md` — structural template; Visual requirements and Destination sections copied nearly verbatim
