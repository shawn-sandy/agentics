---
name: author
description: "Authors implementation plans from a free-text objective, enforcing verb-target filenames and required structure. Invoke as `/plan-agent:author <objective>`."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, TodoWrite, ToolSearch, Skill, EnterPlanMode, ExitPlanMode
disable-model-invocation: true
argument-hint: "<objective> [--quick] [--type feature|fix|refactor|docs|chore] [--dir <path>] [--interview]"
---

# Plan Agent — Author

> **Deferred tools:** `EnterPlanMode` and `ExitPlanMode` are deferred — their schemas are not loaded at session start.
> Before calling either, use `ToolSearch` with `select:EnterPlanMode` or `select:ExitPlanMode` to load the schema first.

## Invocation & Arguments

Read `$ARGUMENTS` on entry:

- **Objective (required):** all text that is not a flag. If empty after parsing, ask once via `AskUserQuestion` ("What is the objective for this plan?") and stop if still empty.
- `--quick` — skip §1 Clarify and §5 Align.
- `--type <kind>` — preset `type:` in frontmatter (`feature`, `fix`, `refactor`, `docs`, `chore`).
- `--dir <path>` — override §2 directory resolution; write the plan to this path.
- `--interview` — after writing the plan and before `ExitPlanMode`, call `Skill(skill: "plan-interview:plan-interview", args: "<plan-path>")`. If that plugin is absent, note "plan-interview plugin not found — skipping" and continue.

**Smart defaults when a flag is absent:**

- `--type` absent → infer from the leading verb of the objective:
  - `create`, `add`, `build`, `implement`, `introduce` → `feature`
  - `fix`, `repair`, `patch`, `resolve` → `fix`
  - `refactor`, `rename`, `extract`, `move`, `restructure`, `convert` → `refactor`
  - `document`, `docs` → `docs`
  - anything else → `chore`
- `--quick` absent → treat as `--quick` if the objective is detailed and specific (≥ 8 words with concrete file paths or names); keep Clarify/Align for vague objectives.

Echo the resolved objective and effective flags before proceeding to §0.

## Enter plan mode

`EnterPlanMode` is a deferred tool — load it before calling it.

1. Use `ToolSearch` with `select:EnterPlanMode` to load the schema.
2. Call `EnterPlanMode`. If already in plan mode, skip this step silently.

## When to plan

- When a skill/slash-command requires write operations (git, filesystem, migrations), **do not** enter plan mode. Execute directly.
- Only produce a plan if the change spans multiple files or has unclear requirements; for simple fixes (missing dep, typo, small edit), apply the change directly.

## Workflow

0. **Assess** — Before drafting anything, determine whether the request warrants a plan: does it span multiple files, or involve unclear requirements? If not — single file, simple fix, typo, missing dep, direct skill/git operation — use `ToolSearch` with `select:ExitPlanMode`, then call `ExitPlanMode` immediately and apply the change directly. Never produce a plan document for requests that don't clear this threshold.
1. **Clarify** — If the request's objectives are ambiguous or have open requirements, use `AskUserQuestion` to resolve them before drafting; if the objectives are already clear, skip this step. Do not add friction to well-specified requests. *(Skip entirely when `--quick` or when the objective is detailed.)*
2. **Create** — Resolve the target directory in order: (1) `--dir` if provided, (2) the configured `plansDirectory` if set, (3) `docs/plans/` if it exists, (4) the default Claude user plans folder. Place the plan there using a `verb-target` kebab-case filename. Examples: `add-dark-mode-toggle`, `fix-login-redirect`, `refactor-auth-module`.
3. **Frontmatter** — **Always** add YAML frontmatter at the top of every new plan file: `status: todo`, `type: <kind>` (use `--type` value if provided, otherwise the inferred type from the objective verb), `created: YYYY-MM-DD`, `repo-name: <repo>`. Resolve `repo-name` from the basename of the `origin` git remote URL (strip trailing `.git`); if no remote exists, fall back to the basename of the current working directory.
4. **Rename** — **Always** ensure the filename follows the `verb-target` kebab-case convention from §2 before committing. Two triggers require a rename: (a) the initial filename is auto-generated, placeholder, or otherwise non-descriptive (e.g. a random two-word slug), and (b) the plan's purpose shifts after creation. Re-evaluate before committing. A stale filename is a plan defect — do not commit until the name matches the content. Enforced by the `validate-plan-filename` `PostToolUse` hook (`${CLAUDE_PLUGIN_ROOT}/hooks/validate-plan-filename.py`), which flags non-`verb-target` plan filenames the instant a plan is written.
5. **Align** — After the plan's steps are drafted, use `AskUserQuestion` (batched, with questions covering each step) to confirm every step aligns with the stated objective before committing. This verifies step-to-objective alignment, not overall plan approval — approval is requested separately via `ExitPlanMode`. *(Skip entirely when `--quick`.)*
6. **Commit** — **Always** commit plan files to version control alongside the related changes.
7. **Status** — **Always** update `status` (and `modified: YYYY-MM-DD`) in the frontmatter as the plan progresses: `todo` → `in-progress` → `completed`. Use `plan-interview:plan-status` (optional cross-plugin helper — requires `plan-interview` plugin) to automate this.

After §7, if `--interview` was set: call `Skill(skill: "plan-interview:plan-interview", args: "<plan-path>")` to stress-test the plan. If the plugin is absent, note "plan-interview plugin not found — skipping" and continue.

Then use `ToolSearch` with `select:ExitPlanMode` and call `ExitPlanMode` to present the plan for approval.

## Required Structure

Every plan must include the following sections:

- `context` — Background and motivation; why this work is needed.
- `objective` — One or two sentences summarising the goal.
- `steps` — A numbered list where each item has three parts: the action, a brief *why*, and a *verify* line stating how to confirm that step succeeded before moving on.
  - Per-step verification is local (did this step do what it should?); the top-level `verification` section covers end-to-end correctness.
- `acceptance-criteria` — A checklist of conditions that must be true for the plan to be considered done from the requester's perspective. Each item is a short, falsifiable statement (not a task). Distinct from `verification`: verification checks that steps ran correctly; acceptance criteria check that the result meets the definition of done.
- `verification` — How to confirm the entire plan was executed correctly end-to-end.
- `next-steps` *(optional)* — Out-of-scope follow-ups and unsolicited ideas; never place these in `steps`. Each item must be a short label with description followed by a fenced ` ```text ` block containing a self-contained prompt the user can paste directly into Claude — no plan-specific shorthand that loses meaning without the parent plan.
- `unresolved-questions` *(optional)* — Open questions needing user input; omit entirely if none. Each item must be a short label followed by a fenced ` ```text ` block containing a prompt that asks Claude to investigate and recommend — self-contained, no context rebuild required.

## Writing Style

Direct, imperative, developer-friendly — real names (file paths, function names, CLI flags), lists over prose, one idea per item, explicitly scoped. Plan only what was requested; unsolicited ideas go in `next-steps`.

## Skeleton

Copy `reference/SKELETON.md` from this plugin's skill directory as a starter for every new plan. Locate it by reading the same directory that contains this `SKILL.md` file — use `Glob` with pattern `**/plan-agent/skills/author/reference/SKELETON.md` if the path is uncertain, to avoid accidentally loading the global `~/.claude/rules/reference/SKELETON.md` which has different content.
