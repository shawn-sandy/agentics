# Give engineers a recap written for them

> Adds `/artifact-tools:eng-recap` — a third recap command over the `session-artifact` pipeline, written for the engineer who has to touch the code next, leading with technical fact rather than plain language.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-eng-recap-command.md](plans/add-eng-recap-command.md)
**Type:** feature

## What shipped

- Added `kit/plugins/artifact-tools/commands/eng-recap.md` as the third recap command over the shared `session-artifact` pipeline
- Command leads with technical fact — the inverse of `team-recap`'s plain-language-first rule, stated explicitly
- Eight engineering-focused sections: At a glance, Architecture and code paths, Decisions, Tradeoffs and rejected options, Learnings, Tests and verification, Review follow-ups and tech debt, Files touched
- Diff read budget added: reads full hunks via `gh pr diff` for at most 20 files, falls back to `--name-only` for the remainder, reporting summarized file counts
- Declared `eng-artifact-url:` republish key with an explicit never-write warning naming the three sibling keys
- Extended `tests/plugins/test-artifact-tools.sh` with the new command in the republish-key collision map and a diff-cap check
- Bumped `artifact-tools` to `1.7.0` in marketplace with matching CHANGELOG entry
- Updated `artifact-tools/README.md` in all four locations (Commands table, Usage block, Structure tree, `### eng-recap` subsection) and the root `CLAUDE.md` plugin table

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | The new command — framing overrides only, delegates to `recap-core.md` | Created |
| `tests/plugins/test-artifact-tools.sh` | Extended check 7 (republish-key map), raised check 8 minimum, added diff-cap check | Modified |
| `.claude-plugin/marketplace.json` | Version bumped to `1.7.0`; description updated | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | `[1.7.0]` Added entry | Modified |
| `kit/plugins/artifact-tools/README.md` | Commands table, Usage block, Structure tree, new subsection | Modified |
| `CLAUDE.md` | `artifact-tools` row in reference-implementations table | Modified |

## How it works

`artifact-tools` ships a single shared pipeline in `skills/session-artifact/SKILL.md` that handles transcript extraction, security scrubbing, and artifact publishing. Each recap command overrides only the framing — the audience instructions and section list — without re-implementing the pipeline. `eng-recap` follows this pattern: it points to `${CLAUDE_PLUGIN_ROOT}/references/recap-core.md` for the full workflow and overrides only the audience and sections.

The core framing inversion is stated explicitly: `eng-recap` is the inverse of `team-recap`, which leads with plain language and glosses every technical name. `eng-recap` leads with the technical fact and assumes the vocabulary. Repo terms, framework names, internal acronyms, code signatures, and config values appear directly and are never glossed.

One material departure from the sibling commands is the diff read budget. `eng-recap` reads full diff hunks via `gh pr diff`, since changed signatures and new error paths are real signal for an engineering reader. To prevent context blowout, the budget caps at 20 files; for the remainder it uses `--name-only` and reports the count of summarized files. Commit bodies still lead for the _why_; hunks supply the _what_.

All three recap commands write their output as artifacts to a shared per-session record under `{plansDirectory}/sessions/`, distinguished only by a frontmatter key. A silent republish over a sibling's live page is a real risk. The republish key `eng-artifact-url:` is unique, and the command carries an explicit never-write warning naming `artifact-url:`, `product-artifact-url:`, and `team-artifact-url:`.

The test suite enforces the collision contract at check 7: `commands/eng-recap.md` must appear in the `owners` map mapping each command to its unique key. The test was verified to fail when `eng-artifact-url` is swapped for a sibling's key, confirming the check has teeth. PR mode is guarded by the same `gh auth status` + `git remote get-url origin | grep -qi 'github\.com'` preflight that the sibling commands use.

## How to use it

```text
# Recap the current session for an engineering reader
/artifact-tools:eng-recap

# Recap a specific pull request
/artifact-tools:eng-recap #42
/artifact-tools:eng-recap https://github.com/org/repo/pull/42
/artifact-tools:eng-recap --pr 42
```

The resulting artifact is published and saved under `{plansDirectory}/sessions/` with the stem `eng-recap` (session mode) or `pr-<number>-eng` (PR mode).

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-eng-recap-command.md](plans/add-eng-recap-command.md)
- Proposal: `docs/proposals/add-eng-recap-command.md`
- Sibling command: `kit/plugins/artifact-tools/commands/team-recap.md`
