---
status: in-progress
type: feature
created: 2026-09-26
modified: 2026-09-26
repo-name: agentics
glance: implementing-insights ends with a ledger printed to chat and nothing the team can open later. This gives every implemented recommendation its own claude.ai artifact, a record page published when work starts and republished to the same URL at every status change, so the team can follow each insight from report to merged change.
---

# Plan: Add live insight records to implementing-insights

## Objective

Make `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` publish one artifact per implemented recommendation and republish it to the same URL at each status change, so every implemented insight leaves a record the team can view.

## Context

`implementing-insights` (memory-tools 4.3.1) triages a usage-insights report, implements the open items, and ends with an outcome ledger printed to chat. Once the session ends there is nothing to check: no page records what each recommendation was, why it was judged open, where it landed, or whether its PR merged. The requester wants a record per implemented insight that the team can view and that updates as the implementation moves.

Decisions:

- **One artifact per implemented item, not per report run.** The request reads "an artifact for each insight we implement", and the skill already treats each item as its own change and PR. Already-implemented and conflicting items stay in the ledger only; they have no implementation to track.
- **Republish a static page, following `artifact-tools:plan-artifact`.** That skill already solves the stable-URL problem by republishing to one URL. A shared-database page is not needed for a record Claude updates at four lifecycle points.
- **The PR body carries the record URL.** Merges often happen in a later session, and the PR is the durable anchor that session already reads with `gh pr view`.
- **Publishing stays in the main session.** Step 5 may fan out to subagents, which may not have the `Artifact` tool; they return the PR URL and the orchestrator republishes.
- **Read-back verification uses `Artifact` `action: "read"`, not WebFetch.** Artifacts are private by default, so a web fetch cannot reach them.

## Files

- kit/plugins/memory-tools/skills/implementing-insights/SKILL.md (modified) — Insight records section; Steps 5, 6, 7 and error handling hook into it; `Artifact` in allowed-tools
- kit/plugins/memory-tools/skills/implementing-insights/references/insight-record.html (new) — a filled worked example of the record page, meeting the artifact page contract
- tests/plugins/test-insight-records.sh (new) — pins the skill-to-template contract and the template's theme contract
- kit/plugins/memory-tools/README.md (modified) — implementing-insights "What the skill does", allowed tools, structure tree, current version
- docs/guides/how-to/memory-tools.md (modified) — implementing-insights entry names the records
- kit/plugins/memory-tools/CHANGELOG.md (modified) — 4.4.0 entry
- .claude-plugin/marketplace.json (modified) — memory-tools 4.3.1 to 4.4.0
- README.md (modified) — Plugin Reference Table regenerated

## Steps

1. [x] Add tests/plugins/test-insight-records.sh asserting that SKILL.md lists `Artifact` in allowed-tools, names references/insight-record.html and the file exists, puts the record URL in the PR body, verifies each publish by reading the page back, gives the ledger a record column, and that the template has a title, no document wrapper tags, a full token palette on bare `:root`, both dark-theme blocks, a token body background, a style for every lifecycle status, and only allowlisted external hosts. Why: the feature is prose plus a template, so an unpinned contract drifts on the next edit. Verify: `bash tests/plugins/test-insight-records.sh` fails before the skill is edited.
2. [x] Write references/insight-record.html as a filled example record: title, status pill, updated date, summary grid (bucket, layer, target, change), recommendation with evidence, triage, change and verification, dated timeline. Why: the repo requires a worked example for structured output, and a template that already meets the artifact contract keeps every published record legible in both themes. Verify: the template assertions in the new test pass, and the page renders in light and dark at 390px and 1280px in a browser with no axe violations.
3. [x] Add the Insight records section to SKILL.md and hook it into Step 5 (first publish before the change, URL in the PR body), Step 6 (republish on merge or close), Step 7 (record column in the ledger), and error handling (local file is the record when publishing fails); add `Artifact` to allowed-tools and a sentence to the Overview. Why: this is the behavior the requester asked for. Verify: `bash tests/plugins/test-insight-records.sh` passes and `bash tests/plugins/test-description-budget.sh` still passes.
4. [x] Update the plugin README, the how-to guide, and the CHANGELOG; bump memory-tools to 4.4.0 in marketplace.json and regenerate the root README table with `node scripts/build-readme-table.mjs`. Why: the version guard fails any plugin edit without a bump, and the README is the reference surface. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` and `node scripts/build-readme-table.mjs --check` exit 0.
5. [x] Publish a real record for this change by following the new section: first publish as In progress, open the PR with the URL in its body, republish as PR open, and read it back. Why: a live publish, republish, and read-back is the only end-to-end proof that the loop works. Verify: `Artifact` `action: "read"` on the URL returns the page with the title and the PR open status.
6. [x] Render this plan with `plan-agent-render` and rebuild the index with `bash docs/plans/build-index.sh`. Why: plan HTML is generated, never hand-written. Verify: the HTML file exists and `docs/plans/index.html` names the plan.

## Tests

Tier 1 — This plan changes plugin source (SKILL.md and its reference file are what ships)

### Objective-Verification Test

- **File:** `tests/plugins/test-insight-records.sh`
- **Type:** structural smoke test
- **Asserts:** SKILL.md allows `Artifact`, names the template that exists, routes the record URL into the PR body, reads each publish back, and gives the ledger a record column; the template meets the artifact theme contract and styles every lifecycle status the skill names
- **Run:** `bash tests/plugins/test-insight-records.sh`

### Unit Tests

- **File:** `tests/plugins/test-exitplanmode-guard.sh`, `tests/plugins/test-description-budget.sh`, `tests/plugins/test-verification-gate-rule.sh`
- **Targets:** the plan-mode guard, the description budget, the verification-gate rule
- **Key cases:** all pass unchanged

## Acceptance Criteria

- [ ] Running implementing-insights publishes one artifact per implemented item before its change is made, and no artifact for already-implemented or conflicting items
- [x] Each status change (In progress, PR open, Merged, Closed, Done) republishes to the same URL and adds a dated timeline entry
- [ ] A later session can find a record from its PR body and republish it to the same URL
- [ ] The final ledger links each item's record, or its local path when publishing failed
- [x] The record page is legible in light and dark themes at phone and desktop widths
- [x] memory-tools is 4.4.0 in marketplace.json with a matching CHANGELOG entry

## Verification

`bash scripts/verify.sh` exits 0 on this machine, with any SKIP recorded as a skip. The record published in Step 5 reads back through `Artifact` with its title and current status, at the same URL after the republish.
