# Give engineers a recap written for them

> Adds `/artifact-tools:eng-recap` — an engineering-audience recap command that leads with technical facts, code paths, decisions, and tradeoffs rather than translating for non-engineers.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-eng-recap-command.md](plans/add-eng-recap-command.md)
**Type:** feature

## What shipped

- Created `kit/plugins/artifact-tools/commands/eng-recap.md` — the third recap command over the `session-artifact` pipeline, written for the engineer who touches the code next; explicitly inverts `team-recap`'s plain-language-first rule.
- Defined eight engineering sections: At a glance, Architecture and code paths, Decisions with rationale, Tradeoffs and rejected options, Learnings, Tests and verification, Review follow-ups and tech debt, Files touched.
- Added a diff-read budget under Source: full hunks for at most 20 files, `--name-only` fallback for the rest, with a report of how many files were summarized.
- Declared `eng-artifact-url:` as the republish key with a never-write warning naming the three sibling keys (`artifact-url:`, `product-artifact-url:`, `team-artifact-url:`), preventing silent overwrites of live pages.
- Extended `tests/plugins/test-artifact-tools.sh` checks 7 and 8 to cover `eng-recap.md` and added a diff-cap assertion.
- Bumped `artifact-tools` to `1.7.0` in `.claude-plugin/marketplace.json` with a `[1.7.0]` CHANGELOG entry.
- Updated `kit/plugins/artifact-tools/README.md` in four places (Commands table, Usage block, Structure tree, new subsection) and the root `CLAUDE.md` plugin table.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | Command — framing overrides only, no new pipeline | Created |
| `tests/plugins/test-artifact-tools.sh` | Smoke test — republish-key map and diff-cap assertions | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry — artifact-tools 1.7.0 | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Changelog — [1.7.0] entry | Modified |
| `kit/plugins/artifact-tools/README.md` | Plugin docs — four locations updated | Modified |
| `CLAUDE.md` | Root reference table — artifact-tools row | Modified |

## How it works

The `eng-recap` command is a framing-only override atop the `session-artifact` pipeline already used by `product-doc` and `team-recap`. It does not re-implement transcript extraction, scrubbing, or publishing — those live in `skills/session-artifact/SKILL.md` and are invoked unchanged via `Skill`.

The key architectural choice is the Audience override: every section leads with the technical fact rather than a plain-language statement. This is stated explicitly as the inverse of `team-recap`'s rule, so a maintainer reading either command sees the contrast without needing to hold both files in mind simultaneously.

PR mode is guarded by the same `gh auth status` + `git remote get-url origin | grep -qi 'github\.com'` preflight as `team-recap`, emitting `PR_MODE_OK` or `PR_MODE_UNAVAILABLE` before any `gh pr view`. The diff-read budget adds the one departure from siblings: `gh pr diff` is read hunk-by-hunk for at most 20 files, falling back to `--name-only` for the rest, with the summary count reported so the reader knows which files were not read in full.

The republish-key discipline is the safety critical part. All recap writers share one per-session record under `{plansDirectory}/sessions/`, keyed by a frontmatter field. `eng-recap` uses `eng-artifact-url:` and explicitly warns against writing `artifact-url:`, `product-artifact-url:`, or `team-artifact-url:`, so a copied-from-a-sibling command cannot silently republish over a live page. Check 7 of `tests/plugins/test-artifact-tools.sh` asserts this for every command in the map, and the plan verified this by temporarily swapping the key and confirming the test failed.

## How to use it

`eng-recap` is activated by its description: "Publish an engineering recap of this session or a pull request — architecture, code paths, tradeoffs, learnings, tests, and review follow-ups, written for the engineer who touches this code next."

```
/artifact-tools:eng-recap            # recap the current session
/artifact-tools:eng-recap #42        # recap PR #42 (requires GitHub remote)
/artifact-tools:eng-recap --pr 42    # same, alternate form
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-eng-recap-command.md](plans/add-eng-recap-command.md)
- Related: `kit/plugins/artifact-tools/commands/team-recap.md` — structural template
- Related: `docs/proposals/add-eng-recap-command.md` — decision-complete proposal
