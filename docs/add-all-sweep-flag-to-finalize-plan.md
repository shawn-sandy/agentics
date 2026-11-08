# Add `--all` sweep flag to finalize-plan

> `finalize-plan --all` discovers every non-completed plan in the plans directory, scores each with token-evidence checks, batch-confirms via one multi-select prompt, and finalizes only the selected plans.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Added `--all` sweep mode to `finalize-plan` that discovers every non-completed plan in the plans directory (via `grep -lE` for `todo`/`in-progress` plan-status tags, excluding `index.html` and `archive/`)
- Cheap non-interactive scoring reuses existing token-evidence pass to rank candidates before confirmation
- Batch confirmation via a single `AskUserQuestion` with `multiSelect` — one prompt for all plans rather than one prompt per plan
- Finalization of selected plans via the existing per-plan Steps 3b/3c/5 pipeline with a single `SendUserFile` delivery
- Updated `argument-hint` and `description` frontmatter to document the new invocation form
- README table row, usage example, and sweep-mode paragraph added to `kit/plugins/plan-agent/README.md`
- `plan-agent` bumped to `2.13.0` in `.claude-plugin/marketplace.json` with matching CHANGELOG entry
- Smoke test `tests/plugins/test-finalize-all-flag.sh` pins the flag to the SKILL.md contract, README docs, and marketplace version

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions — `--all` routing clause and sweep section | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation — table row, usage, sweep description | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry — version 2.13.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes — 2.13.0 entry | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test — SKILL.md contract, README docs, marketplace version | Created |

## How it works

The core insight is that `finalize-plan`'s Steps 2–5 are already a reusable per-plan pipeline — only discovery, confirmation, and delivery differ between single-plan and sweep modes. The `--all` flag adds a routing clause at the top of Step 1 in `finalize-plan/SKILL.md` that branches into a `## Sweep mode (--all)` section when the flag is detected.

Discovery uses `grep -lE` to find files with a `plan-status` meta tag valued `todo` or `in-progress`, explicitly excluding `index.html` and never descending into the `archive/` subdirectory. This keeps non-plan HTML out of the candidate set.

Each candidate is scored with the cheap token-evidence pass only (Steps 3a token checks), non-interactively. Plans with no recognized tokens score 0% rather than triggering an interactive prompt. The score table is presented as the multi-select picker so users can see evidence quality before confirming.

Confirmation is a single `AskUserQuestion` with `multiSelect`: one plan picker plus one batch criteria mode question. The expensive per-criterion verification and objective test run only on the user-selected plans, deferring cost to what the user actually cares about.

Delivery after all selected plans are finalized uses a single `SendUserFile` rather than one file per plan, matching the sweep's batch nature.

## How to use it

The `--all` flag is documented in `finalize-plan`'s `argument-hint` frontmatter and in the README:

```
/plan-agent:finalize-plan --all          # sweep mode: discover, score, batch-confirm
/plan-agent:finalize-plan                # single-plan mode (unchanged)
/plan-agent:finalize-plan my-plan.md     # explicit single plan (unchanged)
```

In sweep mode, `finalize-plan` presents a scored candidate table and a multi-select prompt. Only plans the user selects proceed to full verification and completion.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `5764be8` | 2026-11-05 | fix(plan-agent): drop gallery tabs whose page does not exist (9.22.1) (#670) |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `8a8a392` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |
| `58f14cd` | 2026-10-30 | feat(design-system-tools): add customize-design and align-design-md skills (0.3.0) (#666) |
| `cc28a20` | 2026-10-28 | fix(settings-sync): restore switches back to this machine's branch (1.3.1) (#665) |
| `2f8b101` | 2026-10-28 | fix(settings-sync): back up each machine to its own branch (1.3.0) (#662) |
| `174d0ef` | 2026-10-27 | fix(marketplace): resolve claude.ai plugin validation issues (#660) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `86412c3` | 2026-10-26 | fix(git-agent): finish post-merge-cleanup inside an app session's worktree (4.23.1) (#657) |
| `82227d6` | 2026-10-20 | feat(mcp-tools): add plugin with fix-playwright-mcp skill (0.1.0) (#655) |
| `1c31569` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `d9fdb0b` | 2026-10-10 | feat(git-agent-launcher): add the kit's first mod (0.1.0) (#648) |
| `052d88c` | 2026-10-08 | refactor(git-agent): commit-agent pushes without asking (4.23.0) (#646) |
| `6a6cf33` | 2026-09-28 | feat(design-system-tools): add plugin with from-design-md skill (0.1.0) (#643) |
| `3056b57` | 2026-09-28 | fix: retire dated prompt patterns in plan-agent and git-agent (#641) |
| `417a957` | 2026-09-26 | feat(plan-agent): offer prototype and design canvas together in Step 8 (9.19.0) (#640) |
| `5e1b3c2` | 2026-09-26 | feat(git-agent): sync with the base branch before pushing (4.22.0) (#639) |
| `7a4214f` | 2026-09-26 | feat(memory-tools): implementing-insights publishes a live record per item (4.4.0) (#638) |
| `19a9ae8` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
