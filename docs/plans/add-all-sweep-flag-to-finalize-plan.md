---
status: completed
type: feature
created: 2026-07-02
modified: 2026-07-02
repo-name: agentics
---

# Plan: Add `--all` sweep flag to finalize-plan

## Context

`/plan-agent:finalize-plan` is strictly single-plan: it resolves one filename (or the most recently modified plan) and finalizes it. Plans that are fully implemented but never marked completed accumulate silently in the plans directory — nothing discovers them. The user wants finalize-plan to be able to search for done-but-unmarked plans and mark them completed in one pass.

## Objective

Add a `--all` sweep mode to the `finalize-plan` skill that discovers every non-completed plan in the plans directory, scores each with the existing token-evidence pass, batch-confirms via one multi-select prompt, and finalizes only the selected plans.

## Steps

1. Add sweep mode to `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` — a `--all` routing clause in Step 1 plus a `## Sweep mode (--all)` section (S1 discover via `grep -L` on the completed meta tag, S2 cheap scoring reusing Steps 2/3a, S3 batch confirm via one two-question `AskUserQuestion` with `multiSelect`, S4 finalize selected plans via Steps 3b/3c/5, S5 single `SendUserFile` delivery). Update `argument-hint` and `description` frontmatter. — *Why:* Steps 2–5 are already a reusable per-plan pipeline; only discovery, confirmation, and delivery differ in a sweep. *Verify:* SKILL.md contains the routing clause, sweep section, `grep -L` discovery, and updated `argument-hint`.
2. Document the flag in `kit/plugins/plan-agent/README.md` — feature table row, usage example, sweep-mode paragraph in both finalize-plan sections. — *Why:* README is the user-facing contract for invocation syntax. *Verify:* `grep -- '--all' README.md` hits the table, usage block, and both descriptions.
3. Add a `2.13.0` CHANGELOG entry and bump `plan-agent` to `2.13.0` in `.claude-plugin/marketplace.json` (new behavior = minor), extending the marketplace description with the sweep clause. — *Why:* Marketplace version must exceed `main` for the change to ship; convention requires a CHANGELOG entry. *Verify:* both files carry `2.13.0` and the JSON validation hook passes.
4. Add `tests/plugins/test-finalize-all-flag.sh` pinning the flag to the SKILL.md contract, README docs, and marketplace version. — *Why:* Prevents the sweep contract from silently diverging across the four files. *Verify:* `bash tests/plugins/test-finalize-all-flag.sh` exits 0 with all checks passing.

## Tests

> Tier: 2 (non-code — skill markdown, docs, and metadata only)

### Objective-Verification Test

- **File:** `tests/plugins/test-finalize-all-flag.sh`
- **Type:** smoke test
- **Asserts:** the `--all` flag exists in the SKILL.md contract (routing clause, sweep section with `grep -L` discovery and `index.html` exclusion, multi-select batch confirmation, deferred expensive verification), is documented in the README, and ships as version 2.13.0 in both CHANGELOG and marketplace.json.
- **Run:** `bash tests/plugins/test-finalize-all-flag.sh`

## Acceptance Criteria

- [x] `/plan-agent:finalize-plan --all` is a documented invocation form in `argument-hint`, README table, and usage examples.
- [x] Sweep discovery uses `grep -L` on `<meta name="plan-status" content="completed">`, excludes `index.html`, and never descends into `archive/`.
- [x] Candidates are scored with the cheap token-evidence pass only; per-criterion verification and the objective test run solely on user-selected plans.
- [x] Confirmation is one `AskUserQuestion` (multi-select plan picker + one batch criteria mode), not one prompt per plan.
- [x] `plan-agent` is at `2.13.0` in `marketplace.json` with a matching CHANGELOG entry.
- [x] `tests/plugins/test-finalize-all-flag.sh` passes.

## Verification

Run `bash tests/plugins/test-finalize-all-flag.sh` — all seven checks pass. Manually invoke `/plan-agent:finalize-plan --all` in a repo with a mix of completed and non-completed plans: only non-completed plans appear as candidates, the table sorts by evidence, one prompt selects plans and criteria mode, and only selected plans are edited.

## Next Steps *(optional)*

- Report-only background agent for scheduled sweeps:
  ```text
  Create a background agent at kit/plugins/plan-agent/agents/agent-finalize-plans.md
  that sweeps the plans directory for done-but-unmarked plans (grep -L on
  <meta name="plan-status" content="completed">, excluding index.html and
  archive/), runs the cheap token-evidence scan from the finalize-plan skill's
  Step 3a on each candidate, and returns a report table of candidates with
  evidence scores — without editing any plan files. The main session then runs
  /plan-agent:finalize-plan per pick. Bump plan-agent minor in marketplace.json
  and add a CHANGELOG entry.
  ```
