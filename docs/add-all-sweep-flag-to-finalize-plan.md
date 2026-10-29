# Add `--all` sweep flag to finalize-plan

> Adds a `--all` sweep mode to `finalize-plan` that discovers every non-completed plan, scores each with token-evidence, and batch-confirms via one multi-select prompt before finalizing selected plans.

<!-- generated:start -->

**Status:** Shipped 2026-07-02  **Plan:** [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Added `--all` sweep mode to `plan-agent:finalize-plan` skill, enabling discovery and batch-finalization of done-but-unmarked plans in one pass.
- Sweep discovers plans via `grep -lE` for a `plan-status` meta tag valued `todo` or `in-progress`, excluding `index.html` and the `archive/` directory.
- Candidates are scored non-interactively using the existing cheap token-evidence pass from Steps 2/3a; token-less plans score 0% rather than prompting.
- Batch confirmation uses a single `AskUserQuestion` with `multiSelect`, not one prompt per plan (reducing friction for large backlogs).
- Updated `argument-hint` and `description` frontmatter in the skill to document the new flag.
- Documented the `--all` flag in the plugin README with a feature table row, usage example, and sweep-mode paragraph.
- Bumped `plan-agent` to `2.13.0` in `.claude-plugin/marketplace.json` with a matching CHANGELOG entry (new behavior = minor bump).
- Added `tests/plugins/test-finalize-all-flag.sh` to pin the flag's presence in the SKILL.md contract, README docs, and marketplace version.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin README | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test | Created |

## How it works

`finalize-plan` previously operated on exactly one plan per invocation, either resolving from a filename argument or picking the most recently modified plan. The sweep mode adds a new routing clause in Step 1 of `SKILL.md`: when `--all` is present, the skill switches to discovery mode before any per-plan logic runs.

Discovery uses `grep -lE` to find every HTML plan file whose `<meta name="plan-status">` tag carries a value of `todo` or `in-progress`. This is deliberately narrow — only files with the expected meta tag are candidates, `index.html` is excluded, and the `archive/` directory is never descended into, so historical plans don't pollute the sweep.

Scoring reuses the existing token-evidence pass from the normal finalize-plan workflow (Steps 2 and 3a). In sweep mode this runs non-interactively for every candidate: if no evidence tokens are found the plan scores 0% rather than halting to ask the user. This keeps the sweep latency proportional to the number of candidates rather than the number of interactive gates.

The single confirmation prompt uses `AskUserQuestion` with `multiSelect`, presenting all candidates sorted by evidence score alongside a criteria mode selector. This replaces what would otherwise be N separate confirm/skip prompts — one per plan — and enforces the design principle that a sweep shouldn't cost more keystrokes than manual finalization of each plan individually.

The test in `tests/plugins/test-finalize-all-flag.sh` runs seven checks asserting that the routing clause, sweep section, `grep -lE` discovery command, `index.html`/`archive/` exclusions, multi-select confirmation, deferred expensive verification, and documentation all agree with each other, preventing the four-file contract from silently diverging.

## How to use it

Invoke the sweep mode by passing `--all` to the skill:

```text
/plan-agent:finalize-plan --all
```

Claude discovers every non-completed plan in the plans directory, presents them ranked by evidence with a multi-select picker, and finalizes only the user-selected plans.

A single `AskUserQuestion` covers both plan selection and criteria mode — no per-plan prompting.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
