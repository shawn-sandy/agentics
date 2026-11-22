# Add engineering recap command to artifact-tools

> `/artifact-tools:eng-recap` is a third recap command over the session-artifact pipeline, written for the engineer who has to touch the code next — leading with technical facts, not plain-language summaries.

<!-- generated:start -->

**Status:** Shipped 2026-08-27 **Plan:** [add-eng-recap-command.md](plans/add-eng-recap-command.md)
**Type:** feature

## What shipped

- Added `kit/plugins/artifact-tools/commands/eng-recap.md` with an engineering-first framing that explicitly inverts `team-recap`'s plain-language-first rule.
- Eight agreed sections: At a glance, Architecture and code paths, Decisions with rationale, Tradeoffs and rejected options, Learnings, Tests and verification, Review follow-ups and tech debt, Files touched.
- `eng-artifact-url:` declared as the republish key with a never-write warning naming all three sibling keys.
- PR mode guarded by the `gh auth status` + GitHub-remote preflight; diff read capped at 20 files with `--name-only` fallback.
- Extended `tests/plugins/test-artifact-tools.sh` with collision-free republish-key coverage and a diff-cap check.
- Bumped `artifact-tools` to `1.7.0` with matching CHANGELOG entry.
- Updated README (Commands table, Usage block, Structure tree, component section) and root `CLAUDE.md`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | Command definition | Created |
| `tests/plugins/test-artifact-tools.sh` | Smoke test | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registration | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Version history | Modified |
| `kit/plugins/artifact-tools/README.md` | Plugin documentation | Modified |
| `CLAUDE.md` | Root plugin table | Modified |

## How it works

`eng-recap.md` overrides only the framing of the shared `session-artifact` pipeline — it does not re-implement transcript extraction, scrubbing, or publishing. The audience override states: lead with the technical fact, never the plain-language statement, the inverse of `team-recap`'s rule.

The diff-read budget is unique to this command: it reads full `gh pr diff` hunks for at most 20 files, falls back to `--name-only` for the remainder, and reports how many files were summarized. This prevents context blowout on large PRs while still giving the engineer code-level detail.

The republish key `eng-artifact-url:` is distinct from `artifact-url:`, `product-artifact-url:`, and `team-artifact-url:`. The command carries a never-write warning naming all three sibling keys — the only guarantee preventing silent republish collisions over live pages in the shared session record.

`test-artifact-tools.sh` check 7's `owners` map enforces the key assignment: a command whose key matches a sibling's fails the check. This was verified by deliberately swapping `eng-artifact-url` for `team-artifact-url`, confirming the suite exits non-zero, then reverting.

## How to use it

```
/artifact-tools:eng-recap
/artifact-tools:eng-recap #123
/artifact-tools:eng-recap --pr 456
```

Activated by description match. Produces a session or PR recap written for the engineer reading the code next.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `87285986` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-eng-recap-command.md](plans/add-eng-recap-command.md)
