---
description: Plan mode rules — workflow, required structure, writing style, and scope discipline
---

# Plan Mode Instructions

## When to plan

- When a skill/slash-command requires write operations (git, filesystem, migrations), **do not** enter plan mode. Execute directly.
- Only produce a plan if the change spans multiple files or has unclear requirements; for simple fixes (missing dep, typo, small edit), apply the change directly.

## Workflow

0. **Assess** — Before drafting anything, determine whether the request warrants a plan: does it span multiple files, or involve unclear requirements? If not — single file, simple fix, typo, missing dep, direct skill/git operation — call `ExitPlanMode` immediately and apply the change directly. Never produce a plan document for requests that don't clear this threshold.
1. **Clarify** — If the request's objectives are ambiguous or have open requirements, use `AskUserQuestion` to resolve them before drafting; if the objectives are already clear, skip this step. Do not add friction to well-specified requests.
2. **Create** — Resolve the target directory in order: (1) the configured `plansDirectory` if set, (2) `docs/plans/` if it exists, (3) the default Claude default user plans folder. Place the plan there using a `verb-target` kebab-case filename. Examples: `add-dark-mode-toggle`, `fix-login-redirect`, `refactor-auth-module`.
3. **Frontmatter** — **Always** add YAML frontmatter at the top of every new plan file: `status: todo`, `type: <feature|fix|refactor|docs|chore>`, `created: YYYY-MM-DD`, `repo-name: <repo>`. Resolve `repo-name` from the basename of the `origin` git remote URL (strip trailing `.git`); if no remote exists, fall back to the basename of the current working directory.
4. **Rename** — **Always** ensure the filename follows the `verb-target` kebab-case convention from §2 before committing. Two triggers require a rename: (a) the initial filename is auto-generated, placeholder, or otherwise non-descriptive (e.g. a random two-word slug), and (b) the plan's purpose shifts after creation. Re-evaluate before committing. A stale filename is a plan defect — do not commit until the name matches the content. Enforced by the `validate-plan-filename` `PostToolUse` hook (ships with the `plan-agent` plugin), which flags non-`verb-target` plan filenames the instant a plan is written.
5. **Align** — After the plan's steps are drafted, use `AskUserQuestion` (batched, with questions covering each step) to confirm every step aligns with the stated objective before committing. This verifies step-to-objective alignment, not overall plan approval — approval is requested separately via `ExitPlanMode`.
6. **Commit** — **Always** commit plan files to version control alongside the related changes.
7. **Status** — **Always** update `status` (and `modified: YYYY-MM-DD`) in the frontmatter as the plan progresses: `todo` → `in-progress` → `completed`. Use `/plan-status` to automate this.

## Required Structure

Every plan must include the following sections:

- `context` — Background and motivation; why this work is needed.
- `objective` — One or two sentences summarising the goal.
- `steps` — A numbered list where each item has three parts: the action, a brief *why*, and a *verify* line stating how to confirm that step succeeded before moving on.
  - Per-step verification is local (did this step do what it should?); the top-level `verification` section covers end-to-end correctness.
- `tests` — Real application tests — actual test files written for the application or feature, run by the project's test runner, and committed to the codebase. Distinct from per-step verification and end-to-end verification, which are prose assertions inside the plan document; tests are executable code that ships with the project. Uses a two-tier depth model:
  - **Tier 1** (code-touching plans) — Any plan whose steps create, modify, or delete application source files. Include all applicable test sub-sections (unit, integration, E2E) plus the mandatory objective-verification test. Unit tests target a single function/module in isolation; integration tests exercise multiple modules/services working together; E2E tests drive a full user flow through the running application — include each "when applicable" based on what the steps touch.
  - **Tier 2** (non-code plans) — Plans whose steps only move/rename/delete non-source files, write docs, or update non-runtime metadata. Include only the mandatory objective-verification test; omit unit/integration/E2E sub-sections entirely rather than leaving them as empty stubs. Moving, renaming, or deleting application source files is Tier 1 — those changes affect imports, runtime behaviour, and build graphs.
  - **Objective-verification test** (mandatory, both tiers) — A real mock or smoke test file that runs against the application and directly asserts the plan's stated objective is accomplished. Always appears first in the Tests section as a highlighted hero card, before any unit/integration/E2E sub-sections.
  - The author selects the tier based on what the steps actually do, not the `type:` frontmatter field — a `type: chore` plan that changes import paths is Tier 1, while a `type: chore` plan that moves documentation directories is Tier 2.
- `acceptance-criteria` — A checklist of conditions that must be true for the plan to be considered done from the requester's perspective. Each item is a short, falsifiable statement (not a task). Distinct from `verification`: verification checks that steps ran correctly; acceptance criteria check that the result meets the definition of done.
- `verification` — How to confirm the entire plan was executed correctly end-to-end.
- `next-steps` *(optional)* — Out-of-scope follow-ups and unsolicited ideas; never place these in `steps`. Each item must be a short label with description followed by a fenced ` ```text ` block containing a self-contained prompt the user can paste directly into Claude — no plan-specific shorthand that loses meaning without the parent plan.
- `unresolved-questions` *(optional)* — Open questions needing user input; omit entirely if none. Each item must be a short label followed by a fenced ` ```text ` block containing a prompt that asks Claude to investigate and recommend — self-contained, no context rebuild required.

## Writing Style

Direct, imperative, developer-friendly — real names (file paths, function names, CLI flags), lists over prose, one idea per item, explicitly scoped. Plan only what was requested; unsolicited ideas go in `next-steps`.

## Skeleton

Copy `reference/SKELETON.md` as a starter for every new plan.
