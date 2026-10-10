# Add `--all` sweep flag to finalize-plan

> Adds a `--all` sweep mode to `/plan-agent:finalize-plan` that discovers implemented but never-marked plans and finalizes them in a single batch operation.

<!-- generated:start -->

**Status:** Shipped 2026-07-02 **Plan:** [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Added `--all` sweep mode to the `finalize-plan` skill — a top-level routing clause in Step 1 redirects the entire flow when `--all` is present, replacing per-plan prompts with a batch sequence.
- Discovery phase selects all HTML plans carrying a `<meta name="plan-status">` tag valued `todo` or `in-progress`, excluding `index.html` and any file under `archive/` (non-plan HTML without the tag is never a candidate).
- Cheap, non-interactive token-evidence scoring reuses the existing Steps 2/3a pass; plans with no tokens score 0% instead of prompting, keeping the sweep silent until the confirmation step.
- A single two-question `AskUserQuestion` (multi-select plan picker + one batch criteria mode) replaces per-plan prompts — the expensive per-criterion verification and objective test run only on selected plans.
- All updated plan files are delivered in one `SendUserFile` call with a per-plan summary row.
- Updated `argument-hint` (`[plan-filename.html] [--all] [--dir <path>]`) and `description` frontmatter to document the new invocation form.
- Added `tests/plugins/test-finalize-all-flag.sh` that pins the `--all` contract to `SKILL.md`, `README.md`, and `marketplace.json` version across seven assertions.

> See [CHANGELOG v2.13.0](../kit/plugins/plan-agent/CHANGELOG.md#2130----all-sweep-flag-on-finalize-plan-2026-07-02) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions — added `--all` routing clause, `## Sweep mode (--all)` section, updated `argument-hint` and `description` | Modified |
| `kit/plugins/plan-agent/README.md` | User-facing docs — feature table row, usage example, sweep-mode paragraphs | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — 2.13.0 and 2.13.1 entries | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — `plan-agent` version bumped to 2.13.0 then 2.13.1 | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test — pins `--all` contract across SKILL.md, README, and version | Created |

## How it works

The feature adds a single routing clause at the top of `finalize-plan`'s Step 1: if `$ARGUMENTS` contains `--all`, the skill jumps immediately to **Sweep mode** and never enters the single-file resolution path.

Sweep discovery runs `grep -lE` against the plans directory for files that carry `<meta name="plan-status" content="todo|in-progress">`. This intentionally targets only HTML plans the `implementation-plan` skill generates; plain HTML without the tag is invisible to the sweep. `index.html` and any path containing `archive/` are excluded by pattern before the token-evidence pass begins.

The token-evidence pass (S2) reuses the existing Steps 2/3a cheap scoring logic verbatim — it reads the plan's acceptance-criteria checkboxes and estimates implementation coverage from file-presence tokens. Plans without evidence tokens score 0% automatically, avoiding any interactive prompt mid-sweep. Plans that cross the 80% threshold are flagged as "done but not marked completed."

Confirmation (S3) surfaces all flagged candidates in a single `AskUserQuestion` with `multiSelect: true`, so the user picks which plans to finalize in one interaction rather than one per plan. A second question in the same prompt chooses the criteria mode for the whole batch.

Finalization (S4) runs the standard Steps 3b/3c/5 per-criterion verification and objective-check only on selected plans. This preserves the existing depth of verification while keeping the sweep's discovery and scoring phases entirely non-interactive.

Delivery (S5) calls `SendUserFile` once with all updated plan files, accompanied by a per-plan summary row showing evidence score, criteria checked, and final status.

A follow-up commit (2.13.1) trimmed the skill's `description` frontmatter from 207 to 188 characters to comply with the 200-char three-part budget enforced by `plugin-patterns.md`.

## How to use it

Invocation syntax (see `argument-hint`): `/plan-agent:finalize-plan --all`

- `/plan-agent:finalize-plan --all` — sweeps the default plans directory (`plansDirectory` setting or `docs/plans/`)
- `/plan-agent:finalize-plan --all --dir path/to/plans` — sweeps a custom plans directory
- `/plan-agent:finalize-plan my-plan.html` — single-plan mode (unchanged)

The skill activation trigger in `description`: `Use via /plan-agent:finalize-plan.`

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `58f9092` | 2026-07-02 | fix(plan-agent): trim finalize-plan skill description to 200-char budget (2.13.1) (#367) |
| `408b79f` | 2026-07-02 | feat(plan-agent): add --all sweep flag to finalize-plan (2.13.0) (#366) |

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
- Changelog: [kit/plugins/plan-agent/CHANGELOG.md — v2.13.0](../kit/plugins/plan-agent/CHANGELOG.md)
