# Add eng-recap Command

> Adds `/artifact-tools:eng-recap` — a third recap command written for engineers, leading with technical facts, code paths, and tradeoffs rather than plain-language translation.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-eng-recap-command.md](plans/add-eng-recap-command.md)
**Type:** feature

## What shipped

- Created `kit/plugins/artifact-tools/commands/eng-recap.md` — a framing-only command that delegates the full extraction, scrub, and publish pipeline to `references/recap-core.md`, overriding only audience rules and sections.
- The audience section explicitly inverts `team-recap`'s plain-language-first rule: lead with the technical fact, assume vocabulary, use code freely.
- Eight fixed sections in order: At a glance, Architecture and code paths, Decisions, Tradeoffs and rejected options, Learnings, Tests and verification, Review follow-ups and tech debt, Files touched.
- Diff-read budget: reads full hunks for at most 20 files via `gh pr diff`, falls back to `--name-only` for the remainder, and reports how many files were summarized.
- Declares `eng-artifact-url:` as its republish key with an explicit never-write warning naming all three sibling keys (`artifact-url:`, `product-artifact-url:`, `team-artifact-url:`).
- Extended `tests/plugins/test-artifact-tools.sh` check 7 (republish-key map) and check 8 (PR-mode commands count), and added a diff-cap check.
- Bumped `artifact-tools` to `1.7.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry.
- Updated `kit/plugins/artifact-tools/README.md` in all four locations (Commands table, Usage block, Plugin Structure tree, and new `### eng-recap (command)` subsection).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | Command file — framing overrides only | Created |
| `tests/plugins/test-artifact-tools.sh` | Smoke test — extended checks 7, 8, plus diff-cap check | Modified |
| `.claude-plugin/marketplace.json` | `artifact-tools` bumped to `1.7.0` | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | `[1.7.0]` entry | Modified |
| `kit/plugins/artifact-tools/README.md` | Commands table, Usage block, Structure tree, new section | Modified |
| `CLAUDE.md` | `artifact-tools` row in reference-implementations table | Modified |

## How it works

The `artifact-tools` plugin shipped two recap commands over a shared pipeline: `product-doc` (stakeholder audience) and `team-recap` (mixed audience). Both are bound by a translate-for-non-engineers rule that crowds out the code paths, invariants, and rejected tradeoffs an engineering reader needs.

`eng-recap` is the inverse framing. The command file is intentionally short — it contains only audience rules and the section list. All pipeline mechanics (session-source resolution, PR gathering via `gh pr view`, the blocking `security-scrub` gate, page build, and `save-artifact` publish) are inherited from `references/recap-core.md` by reference. Re-implementing any of that would fork a pipeline that already works and diverge the moment the core changed.

The `Architecture and code paths` section is what differentiates `eng-recap` from its siblings and justifies reading the diff. The command opts into the diff budget: for pull-request mode it reads full hunks for up to 20 files, then switches to `--name-only` for the remainder and notes how many files were summarized. Commit bodies still lead for the *why*; hunks supply the *what* — changed signatures, new error paths, config values.

The republish-key collision risk is addressed by the `eng-artifact-url:` key, unique to this command, paired with an explicit never-write warning. All four commands that write to the shared per-session record in `{plansDirectory}/sessions/` declare different keys; check 7 of the smoke test enforces this as a map and fails immediately when a key is shared.

The `Learnings` section is always kept even when empty, because dropping it reads as "no dead ends were walked" rather than "nobody wrote them down." This is the one exception to the core's omit-empty-sections rule.

## How to use it

`/artifact-tools:eng-recap` generates an engineering recap of the current session or a pull request.

```text
/artifact-tools:eng-recap
/artifact-tools:eng-recap #123
/artifact-tools:eng-recap --pr 456
```

The command auto-detects PR mode when a GitHub remote is available (`gh auth status` + `git remote get-url origin | grep -qi 'github.com'`). Session mode is the fallback. The output is published as an artifact via `save-artifact` under the `eng-artifact-url:` key in the session record.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [add-eng-recap-command.md](plans/add-eng-recap-command.md)
