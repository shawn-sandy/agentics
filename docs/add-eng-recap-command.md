# Give engineers a recap written for them

> Adds `/artifact-tools:eng-recap` — a third recap command over the session-artifact pipeline written for the engineer who has to touch the code next, inverting the plain-language-first rule of `team-recap`.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-eng-recap-command](plans/add-eng-recap-command.md)
**Type:** feature

## What shipped

- Created `kit/plugins/artifact-tools/commands/eng-recap.md` — a framing-override command over the existing `session-artifact` pipeline
- Eight sections: At a glance, Architecture and code paths, Decisions with rationale, Tradeoffs and rejected options, Learnings, Tests and verification, Review follow-ups and tech debt, Files touched
- PR mode reads full diff hunks for at most 20 files, falls back to `--name-only` for the remainder with a count of summarized files
- Declares `eng-artifact-url:` republish key with a never-write warning naming all three sibling keys
- Bumped `artifact-tools` to `1.7.0` with CHANGELOG entry; updated README (Commands table, Usage block, Structure tree, component section) and root `CLAUDE.md`
- Extended `tests/plugins/test-artifact-tools.sh` checks 7 and 8, added a diff-cap check

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | Command — engineering recap framing | Created |
| `tests/plugins/test-artifact-tools.sh` | Smoke test — check 7 key-collision map, check 8 PR-mode commands, diff cap | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — artifact-tools 1.7.0 | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Release history — 1.7.0 entry | Modified |
| `kit/plugins/artifact-tools/README.md` | Plugin docs — eng-recap in four locations | Modified |
| `CLAUDE.md` | Repo index — artifact-tools row updated | Modified |

## How it works

`eng-recap` is a framing-only command: it overrides audience, sections, and republish key over the `session-artifact` pipeline while reusing its transcript extraction, scrub gate, and publish logic unchanged. This is deliberate — reimplementing any shared step would fork a pipeline that already works and create a drift surface.

The audience section explicitly inverts `team-recap`'s plain-language-first rule: `eng-recap` leads with the technical fact and puts context second, so code paths, invariants, and rejected tradeoffs lead each section rather than close it.

PR mode is handled with a documented diff budget: `gh pr diff` reads full hunks for at most 20 files. Beyond that threshold the command falls back to `--name-only` and reports how many files were summarized rather than read. This prevents context blowout on large PRs while keeping the diff-informed analysis `eng-recap` exists to provide.

The `eng-artifact-url:` key is unique in the shared session record. A never-write warning in the command body names all three sibling keys (`artifact-url:`, `product-artifact-url:`, `team-artifact-url:`) so an author cannot accidentally republish over a sibling's live page.

## How to use it

```
/artifact-tools:eng-recap               # recap the current session for engineers
/artifact-tools:eng-recap #42           # recap a specific PR
/artifact-tools:eng-recap --pr 42       # same, explicit flag
```

Activation: listed as the third recap command in the README Commands table and Usage block.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-eng-recap-command](plans/add-eng-recap-command.md)
- Related: `docs/proposals/add-eng-recap-command.md` — decision-complete proposal
