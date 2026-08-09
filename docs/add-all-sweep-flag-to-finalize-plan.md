# Add `--all` sweep flag to finalize-plan

> `finalize-plan` is strictly single-plan; plans fully implemented but never marked completed accumulate silently. This adds a `--all` sweep mode that discovers, scores, and batch-finalizes unmarked plans.

<!-- generated:start -->

**Status:** Shipped 2026-07-27 **Plan:** [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Added `--all` sweep routing clause to `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` — when `$ARGUMENTS` contains `--all`, resolution skips single-file mode and delegates to `references/sweep-mode.md`.
- Sweep discovery selects files carrying a `<meta name="plan-status">` tag valued `todo` or `in-progress` across the plans directory, excluding `index.html` and `archive/`; non-plan HTML without the tag is never a candidate.
- Cheap, non-interactive token-evidence scoring reuses the existing Steps 2/3a pass — token-less plans score 0% rather than prompting.
- Batch confirmation uses one two-question `AskUserQuestion` (multi-select plan picker + one criteria mode for the whole batch), replacing per-plan confirmation prompts.
- Expensive per-criterion verification and the objective-verification test run only on user-selected plans; all finalized files are delivered in one `SendUserFile` call.
- Updated `argument-hint` to `[plan-file.md|.html] [--all] [--dir <path>]` and `description` to include the sweep capability.
- Documented the flag in `kit/plugins/plan-agent/README.md` — feature table row, usage example, and sweep-mode paragraph in both finalize-plan sections.
- Added smoke test `tests/plugins/test-finalize-all-flag.sh` pinning the flag to the SKILL.md contract, README docs, and marketplace version.
- Bumped `plan-agent` to `2.13.0` in `.claude-plugin/marketplace.json` with a matching CHANGELOG entry.

> See [CHANGELOG v2.13.0](../kit/plugins/plan-agent/CHANGELOG.md#2130----all-sweep-flag-on-finalize-plan-2026-07-02) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions — added sweep routing clause and `--all` argument-hint | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/sweep-mode.md` | Sweep mode reference — S1–S5 discovery, scoring, confirmation, finalize, deliver | Created |
| `kit/plugins/plan-agent/README.md` | Plugin README — feature table row, usage example, sweep-mode description | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 2.13.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry — version 2.13.0, updated description | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test — pins sweep contract to SKILL.md, README, and marketplace version | Created |

## How it works

When `/plan-agent:finalize-plan --all` is invoked, Step 1 detects `--all` in `$ARGUMENTS` and immediately routes to `references/sweep-mode.md`, bypassing the single-file resolution path entirely.

**S1 — Discovery** uses `grep -lE` to find plan files whose `<meta name="plan-status">` tag is valued `todo` or `in-progress`. The search runs across the configured plans directory, skipping `index.html` and never descending into `archive/`. Files without the meta tag at all are excluded — they are not recognized plan files.

**S2 — Cheap scoring** reuses the token-evidence pass from Steps 2 and 3a: for each candidate, the skill scans for backtick-wrapped identifiers and file-path tokens without invoking the expensive per-criterion verification or the objective-verification test. Plans with no tokens score 0% rather than triggering an interactive prompt.

**S3 — Batch confirmation** presents one `AskUserQuestion` with a multi-select list of candidates (sorted by evidence percentage) and a second question for criteria mode (permissive vs. strict) — one prompt per sweep, not one per plan. The user picks which plans to finalize and how.

**S4 — Finalize selected** runs Steps 3b/3c (per-criterion verification and objective test) plus Step 5 (status write + HTML re-render) for only the confirmed plans. The Markdown spec is the source of truth: when a plan has a sibling `.md` spec, `status: completed` is written to the frontmatter and the HTML is re-rendered via `build-plan-html.mjs`; legacy HTML-only plans are edited in place.

**S5 — Delivery** collects all modified files and sends them in a single `SendUserFile` call with a per-plan summary table, so the user receives one compact report rather than interleaved per-plan notifications.

The `tests/plugins/test-finalize-all-flag.sh` smoke test asserts that the routing clause (`--all routes elsewhere`) and sweep-mode reference exist in `SKILL.md`, the `argument-hint` contains `--all`, README and CHANGELOG mention the flag, and `marketplace.json` is at `2.13.0`.

## How to use it

**Activation:** `/plan-agent:finalize-plan --all`

**Single-plan form (unchanged):** `/plan-agent:finalize-plan [plan-file.md|.html]`

```text
# Sweep all plans in the default plans directory
/plan-agent:finalize-plan --all

# Sweep a custom directory
/plan-agent:finalize-plan --all --dir ~/.claude/plans
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `7ded3be` | 2026-08-05 | feat(plan-agent): phase checkpoints and a Decisions ledger for plan specs (8.6.0) (#528) |
| `5650823` | 2026-08-02 | fix(plan-agent): invoke bundled scripts via bin/ on PATH (8.3.0) (#519) |
| `e274327` | 2026-08-01 | refactor(plan-agent): split five skills into cores plus references (#505) |
| `bd9b61e` | 2026-07-31 | feat(plan-agent): link plans to their tracking tickets end to end (#497) |
| `e41cd08` | 2026-07-28 | refactor: teach the plan-mode guard once, keep it everywhere (#481) |
| `1ea0a36` | 2026-07-27 | fix(docs): make session-record links relative to their directory (#472) |

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
- Changelog: [plan-agent CHANGELOG v2.13.0](../kit/plugins/plan-agent/CHANGELOG.md)
