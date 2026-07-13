---
status: completed
type: feature
created: 2026-07-13
repo: agentics
glance: Plans and issues only linked in one direction — an issue could seed a plan, but a finished plan could not become a tracked ticket. Now create-issue accepts a plan file as a source and implementation-plan offers issue creation at the end of every plan run.
---
# Plan: Let create-issue ingest plans and offer issue creation at plan completion

## Objective
Add a `plan` source to the git-agent `create-issue` skill so a plan file (markdown spec or rendered HTML) can be turned into a GitHub/GitLab issue, and extend the plan-agent `implementation-plan` Step 8 menu with an optional "create a tracking issue" question that invokes it.

## Context
`implementation-plan` already ingests issues (Step 0.5 maps an issue URL or `#n` into a plan and records it as an `issue:` frontmatter key), but the reverse path did not exist: a drafted plan could not become a tracked ticket without hand-writing one. `create-issue` supported four sources (bug, feature, selection, session) and its Step 8 counterpart in plan-agent ended without any issue hand-off. Wiring the two skills together closes the loop — the same `issue:` frontmatter key carries the link in both directions.

## Files
- kit/plugins/git-agent/skills/create-issue/SKILL.md (modified) — `plan` source keyword + path implication, per-source mapping, template routing
- kit/plugins/git-agent/skills/create-issue/references/plan-issue.md (new) — plan-to-issue body skeleton
- tests/plugins/test-create-issue-plan-source.sh (new) — objective-verification smoke test
- kit/plugins/git-agent/README.md (modified) — plan source documented with example
- kit/plugins/git-agent/CHANGELOG.md (modified) — v3.12.0 entry
- kit/plugins/plan-agent/skills/implementation-plan/SKILL.md (modified) — Step 8 batched tracking-issue question + handler
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 2.22.0 entry
- .claude-plugin/marketplace.json (modified) — git-agent 3.11.1 → 3.12.0, plan-agent 2.21.0 → 2.22.0
- CLAUDE.md (modified) — plugin table rows for both plugins

## Steps
1. [x] Add the `plan` source to create-issue's SKILL.md: keyword parsing (a `.md`/`.html` token implies the source), resolution under the plans directory, and the mapping — plan title → issue title, Objective → Summary, Steps → `- [ ]` checklist, Acceptance Criteria carried over, `type:` frontmatter → label hint, plan path cited in the body. Why: the skill's phases are the runtime contract; the mapping must be explicit so drafts are deterministic. Verify: SKILL.md Phase 3 lists five sources and a `plan` per-source block; Phase 5 routes `plan` → `plan-issue.md`.
2. [x] Create `references/plan-issue.md` with the Objective / Plan / Steps / Acceptance Criteria / Additional Context body skeleton, title rule (plan title, no prefix), and label mapping. Why: the other four sources each have a template; the plan shape (objective + checklists) fits none of them. Verify: the file exists and the Reference Files list in SKILL.md names it.
3. [x] Extend implementation-plan Step 8 to batch a second AskUserQuestion — "Create a tracking issue for this plan?" — and on yes invoke `Skill(skill: "git-agent:create-issue", args: "plan <spec path>")`, record the returned issue URL as the spec's `issue:` frontmatter key, and re-render; if git-agent is not installed, note it and continue. Why: the Step 8 menu already carries the AskUserQuestion 4-option maximum, so the issue choice must ride as a second batched question, and a missing cross-plugin dependency must never block the plan flow. Verify: Step 8 shows two batched questions and a `Yes — create an issue` handler that names the fallback.
4. [x] Bump versions (git-agent 3.12.0, plan-agent 2.22.0) in marketplace.json, add CHANGELOG entries to both plugins, and update the README and CLAUDE.md plugin-table mentions. Why: marketplace versioning is manual per repo rules (new skill capability = minor), and docs drift is a defect. Verify: marketplace.json carries both new versions; both CHANGELOGs lead with the new entries; README and CLAUDE.md mention the plan source.

## Tests
Tier 2 — Steps edit skill markdown, templates, manifests, and docs only; no application source files change.
- Objective: the two skills are wired together and versioned. File: tests/plugins/test-create-issue-plan-source.sh; Type: smoke test; Asserts: create-issue SKILL.md declares the `plan` source and routes it to `references/plan-issue.md` (which exists), implementation-plan SKILL.md invokes `git-agent:create-issue` with a `plan` argument in Step 8, and marketplace.json reports git-agent ≥ 3.12.0 and plan-agent ≥ 2.22.0; Run: bash tests/plugins/test-create-issue-plan-source.sh

## Acceptance Criteria
- [x] `/git-agent:create-issue plan <path>` is a documented source: SKILL.md parses the keyword (and infers it from a `.md`/`.html` token), maps plan sections into the issue body, and routes drafting through `references/plan-issue.md`.
- [x] `references/plan-issue.md` exists with the objective/steps/criteria skeleton and the `type:` → label mapping.
- [x] implementation-plan Step 8 asks a batched "Create a tracking issue?" question and, on yes, invokes `git-agent:create-issue` with `plan <spec path>`, recording the issue URL as the `issue:` frontmatter key.
- [x] A missing git-agent plugin degrades to a one-line notice — issue creation never blocks the plan flow.
- [x] marketplace.json carries git-agent 3.12.0 and plan-agent 2.22.0 with matching CHANGELOG entries.
- [x] The smoke test passes.

## Verification
Run `bash tests/plugins/test-create-issue-plan-source.sh` and confirm every check passes. Read create-issue SKILL.md end to end: the five-source flow is coherent from parsing (Phase 3) through template selection (Phase 5) to creation, and the confirmation gate still guards every path. Read implementation-plan Step 8: the batched question, the `Yes` handler, and the not-installed fallback are all present, and the existing four-option menus are unchanged. Confirm `python3 -m json.tool .claude-plugin/marketplace.json` parses and shows both bumped versions.

## Next Steps

- End-to-end dry run of the plan source against a real plan
  ```text
  In the agentics repo, load the git-agent plugin (claude --plugin-dir
  ./kit/plugins/git-agent) and run /git-agent:create-issue plan
  docs/plans/add-plan-source-to-create-issue.md against a scratch repo.
  Confirm the drafted issue title matches the plan title, the body carries
  the objective, step checklist, and acceptance criteria, and the
  confirmation gate appears before any gh/glab call. Cancel at the gate —
  do not create a real issue.
  ```
- Offer the tracking-issue question in finalize-plan too
  ```text
  In the agentics repo, evaluate whether /plan-agent:finalize-plan should
  also offer "create a tracking issue" for plans that finish without one
  (no issue: frontmatter key). If yes, mirror the implementation-plan
  Step 8 pattern — a batched AskUserQuestion invoking
  git-agent:create-issue plan <spec path> with the not-installed fallback —
  bump the plan-agent minor version, and add a CHANGELOG entry.
  ```
