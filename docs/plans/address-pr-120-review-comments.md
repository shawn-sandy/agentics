---
status: completed
type: artifact
created: 2026-05-15
modified: 2026-05-15
---

# Plan: Address PR #120 review comments

## Context

PR #120 (`feat/revised-plugin-panel-2026-05-14` → `main`) was just opened and immediately drew automated review from Codex and Copilot. The PR adds the `product-plans` plugin (v2.2.0) — six-reviewer panel, background mode, security expert. Reviews surfaced one architectural defect (background mode is non-functional as shipped), several documentation inconsistencies (v2.2.0 added the Security reviewer but only renumbered section bodies, not surrounding metadata), and three stale plan files with a typo (`directoryt`) and non-descriptive slugs that should not ship.

Already applied prior to this plan (under webhook-activity authorization):

- PR base retargeted: `feat/plan-interview-html` → `main` (resolves the prior `CONFLICTING` state; now `MERGEABLE`).
- `kit/plugins/product-plans/skills/product-plans/references/output-template.md:5` — corrected "Section 14 is omitted" → "Section 15 (Revised Product Plan) is omitted" (off-by-one introduced when v2.2.0 added Security as section 9, renumbering everything below).

## Objective

Apply the remaining Copilot review fixes in one bundled commit so PR #120 ships with a functional background mode, consistent documentation, and clean plan hygiene.

## Steps

1. **Fix the `agent-product-plans` tool list** — *Why:* the agent currently declares `tools: Skill, Read` and invokes a skill that calls `Write`; subagent tool grants are not transitive across `Skill` invocations, so writes silently fail and background mode is non-functional (the PR's own panel-review plan documents this failure mode). *Verify:* after edit, `tools:` reads `Skill, Read, Write, Edit, Glob, Grep, Bash` in `kit/plugins/product-plans/agents/agent-product-plans.md:10`, and a dry-run dispatch of `/product-plans:product-plans-bg <some-plan>.md` writes a sibling `-revised.md` file.

2. **Add plan-mode bootstrap to `product-plans-bg` command** — *Why:* the command dispatches a write-performing agent, but dispatching from plan mode blocks (the existing `*-immutable-anchor.md` plan file in this PR was created specifically to work around this); mirror the git-agent pattern (`ToolSearch select:ExitPlanMode` then `ExitPlanMode`). *Verify:* `kit/plugins/product-plans/commands/product-plans-bg.md` frontmatter `allowed-tools` includes `Agent, ToolSearch, ExitPlanMode`, and the workflow has a Step 0 that loads and calls `ExitPlanMode` silently before the dispatch step.

3. **Rewrite Step 1 arg parsing in the skill** — *Why:* the current rule "everything before any `--` flag" only works for path-first ordering; if a user runs `--background docs/plans/foo.md` the parse extracts an empty path and the skill stops with `Background mode requires a plan path` instead of running. *Verify:* `kit/plugins/product-plans/skills/product-plans/SKILL.md` Step 1 splits `$ARGUMENTS` on whitespace, filters tokens matching `--<word>` as flags, and picks the first non-flag token as the path; mental-test against three orderings: `<path>`, `<path> --background`, `--background <path>`.

4. **Bring `product-plans/README.md` in sync with v2.2.0** — *Why:* the README still advertises "14-section" output and lists 14 sections, the plugin-structure tree omits `product-reviewer-security-expert.md`, and the auto-activation trigger description omits Security; the file is the user-facing entry point and these inconsistencies are immediately visible. *Verify:* all instances of "14-section" and "14 sections" updated to 15; Security Requirements added as section 9 (push existing 9-13 down to 10-14, Final decision becomes 14, Revised plan becomes 15); plugin tree includes `product-reviewer-security-expert.md`; auto-activation trigger description mentions `PM/Dev/UX/Frontend/Accessibility/Security`.

5. **Revert stray blank line in plan-to-html SKILL.md** — *Why:* the diff introduces a duplicate blank line between lines 163 and 165 (already separated by a single blank), no structural purpose; trivial cleanup that keeps the diff focused on intentional changes. *Verify:* `kit/plugins/plan-interview/skills/plan-to-html/SKILL.md` has a single blank line between the `--background` paragraph and the "Otherwise, ask the user…" paragraph.

6. **Expand plan-interview CHANGELOG v1.22.1 entry** — *Why:* the current entry only mentions the Step 6 HTML branching fix, but the v1.22.1 commit also flipped `--no-open` → `--background` in `plan-hygiene.md` and `review-rename-plans.md` (a user-visible behavior change: `--background` suppresses the theme prompt) and reorganized `git add` for HTML outputs from glob to explicit per-file; both belong in the changelog. *Verify:* `kit/plugins/plan-interview/CHANGELOG.md` v1.22.1 entry includes bullets for the `--background` switch and the `git add` reorganization, distinct from the SKILL.md fix bullet.

7. **Delete three stale plan files with the `directoryt` typo** — *Why:* `rename-the-skill-directoryt-joyful-puffin.md`, `rename-the-skill-directoryt-joyful-puffin-revised.md`, and `docs-plans-rename-the-skill-directoryt-j-immutable-anchor.md` all carry the typo and non-descriptive auto-generated slugs; the descriptive replacement (`add-background-mode-product-plans.md`) already ships in this PR, and the `*-immutable-anchor.md` file is a one-shot procedural artifact created only to satisfy plan mode at the time. *Verify:* the three files no longer exist under `docs/plans/`; `add-background-mode-product-plans.md` remains and is the sole record of this background-mode work.

8. **Update this plan file's status to `completed` and commit alongside the fixes** — *Why:* per the global plan-mode rule, plan files commit with their related changes and the status field tracks lifecycle. *Verify:* this file's frontmatter `status: completed` and `modified: 2026-05-15` are set, and the file appears in the same commit as the fixes.

## Verification

- Run `gh pr view 120 --json mergeable,mergeStateStatus,statusCheckRollup` and confirm `mergeable: MERGEABLE` is preserved.
- Re-read each modified file and confirm the section count, agent tool list, command `allowed-tools`, and CHANGELOG bullets match the steps above.
- Mentally simulate `/product-plans:product-plans-bg docs/plans/foo.md` from plan mode: the command bootstraps out, dispatches the agent, the agent has Write/Edit and successfully writes `docs/plans/foo-revised.md`.
- Run `git status` and confirm only the targeted paths plus this plan file are changed (no scope creep).
- After commit and push, watch for the Copilot/CodeRabbit re-review on the new HEAD — the flagged comments should be resolved.

## Next Steps *(optional)*

- Audit remaining auto-named plan files in `docs/plans/`:
  ```text
  Scan docs/plans/*.md for files whose names look auto-generated (random
  word pairs, *-anchor suffixes, *-mccarthy/*-puffin/*-hermann style names)
  and review each: rename to a descriptive kebab-case based on the plan
  title, or delete if the plan was a one-shot procedural artifact. Skip
  any plan whose frontmatter status is "completed" and whose name already
  matches its content.
  ```
