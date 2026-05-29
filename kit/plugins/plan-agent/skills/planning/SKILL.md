---
name: planning
description: "Creates implementation plans from a free-text objective. Enforces verb-target filenames, structure, and HTML metadata. Use when running `/plan-agent:planning <objective>` to create a plan."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, TodoWrite, ToolSearch, Skill, EnterPlanMode, ExitPlanMode
disable-model-invocation: true
argument-hint: "<objective> [--quick] [--no-clarify] [--no-align] [--type feature|fix|refactor|docs|chore] [--template default|minimal|adr|spike] [--dir <path>] [--priority low|medium|high|critical] [--interview]"
---

# Plan Agent — Planning

> **Deferred tools:** `EnterPlanMode` and `ExitPlanMode` are deferred — their schemas are not loaded at session start.
> Before calling either, use `ToolSearch` with `select:EnterPlanMode` or `select:ExitPlanMode` to load the schema first.

## Invocation & Arguments

Read `$ARGUMENTS` on entry:

- **Objective (required):** all text that is not a flag. If empty after parsing, ask once via `AskUserQuestion` ("What is the objective for this plan?") and stop if still empty.
- `--quick` — shorthand for `--no-clarify --no-align`; skips both §1 Clarify and §5 Align.
- `--no-clarify` — skip §1 Clarify only. Use when the objective is well-specified but you still want §5 Align.
- `--no-align` — skip §5 Align only. Use when steps are pre-agreed but requirements need verification first.
- `--type <kind>` — preset `type:` in frontmatter (`feature`, `fix`, `refactor`, `docs`, `chore`).
- `--template <name>` — plan skeleton variant: `default` (default), `minimal`, `adr`, `spike`. Controls which skeleton is loaded in §2 (see **Skeleton** section).
- `--dir <path>` — override §2 directory resolution; write the plan to this path.
- `--priority <level>` — write `priority: <level>` to frontmatter (`low`, `medium`, `high`, `critical`). Overrides `planAgent.extraFrontmatter.priority` from settings if both are present.
- `--interview` — after writing the plan and before `ExitPlanMode`, call `Skill(skill: "plan-interview:plan-interview", args: "<plan-path>")`. If that plugin is absent, note "plan-interview plugin not found — skipping" and continue.

**Smart defaults when a flag is absent:**

- `--type` absent → infer from the leading verb of the objective:
  - `create`, `add`, `build`, `implement`, `introduce` → `feature`
  - `fix`, `repair`, `patch`, `resolve` → `fix`
  - `refactor`, `rename`, `extract`, `move`, `restructure`, `convert` → `refactor`
  - `document`, `docs` → `docs`
  - anything else → `chore`
- `--quick`, `--no-clarify`, `--no-align` are opt-in only and are never inferred automatically.

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
1. **Clarify** — If the request's objectives are ambiguous or have open requirements, use `AskUserQuestion` to resolve them before drafting; if the objectives are already clear, skip this step. Do not add friction to well-specified requests. *(Skip entirely when `--quick` or `--no-clarify`.)*
2. **Create** — Resolve the target directory in order: (1) `--dir` if provided, (2) the configured `plansDirectory` if set, (3) `docs/plans/` if it exists, (4) the default Claude user plans folder. Place the plan there using a `verb-target` kebab-case filename with a `.html` extension. Examples: `add-dark-mode-toggle.html`, `fix-login-redirect.html`, `refactor-auth-module.html`. **Always write HTML — never write markdown for plan output.**
3. **Frontmatter** — Embed plan metadata as `<meta>` tags inside the HTML `<head>`, not as YAML. Include: `status` (`todo` | `in-progress` | `completed`), `type`, `created` (YYYY-MM-DD), `repo-name`. Resolve `repo-name` from the basename of the `origin` git remote URL (strip trailing `.git`); if no remote exists, fall back to the basename of the current working directory. If `--priority` was set, also add `<meta name="plan-priority" content="<level>">`. Read `planAgent.extraFrontmatter` from `.claude/settings.json` (project first, then global) and render any extra key-value pairs as additional `<meta name="plan-<key>" content="<value>">` tags; `--priority` overrides any `priority` key from settings.
4. **Rename** — **Always** ensure the filename follows the `verb-target` kebab-case convention from §2 before committing. Two triggers require a rename: (a) the initial filename is auto-generated, placeholder, or otherwise non-descriptive (e.g. a random two-word slug), and (b) the plan's purpose shifts after creation. Re-evaluate before committing. A stale filename is a plan defect — do not commit until the name matches the content. Enforced by the `validate-plan-filename` `PostToolUse` hook (`${CLAUDE_PLUGIN_ROOT}/hooks/validate-plan-filename.py`), which flags non-`verb-target` plan filenames the instant a plan is written.
5. **Align** — After the plan's steps are drafted, use `AskUserQuestion` (batched, with questions covering each step) to confirm every step aligns with the stated objective before committing. This verifies step-to-objective alignment, not overall plan approval — approval is requested separately via `ExitPlanMode`. *(Skip entirely when `--quick` or `--no-align`.)*
6. **Commit** — **Always** commit plan files to version control alongside the related changes.
7. **Status** — **Always** update `status` in the HTML plan as the plan progresses: `todo` → `in-progress` → `completed`. Edit **both** the `<html data-status="…">` attribute and the `<meta name="plan-status" content="…">` tag so the CSS badge colour and the hook's completion check stay in sync. Also update the visible badge text. Note: `plan-interview:plan-status` operates on YAML-frontmatter `.md` files only — do not use it for HTML plans until that plugin is updated to support `.html`.

After §7, if `--interview` was set: call `Skill(skill: "plan-interview:plan-interview", args: "<plan-path>")` to stress-test the plan. If the plugin is absent, note "plan-interview plugin not found — skipping" and continue.

Then use `ToolSearch` with `select:ExitPlanMode` and call `ExitPlanMode` to present the plan for approval.

## Required Structure

Every HTML plan must include the following sections rendered as visible, styled HTML elements (not inline HTML comments):

- **context** — Background and motivation; why this work is needed.
- **objective** — One or two sentences summarising the goal. Render prominently — large text, highlighted card.
- **steps** — A numbered list where each item has three parts: the action, a brief *why*, and a *verify* line. Render each step as a card with an expandable Verify section. Per-step verification is local; the top-level `verification` section covers end-to-end correctness.
- **acceptance-criteria** — Interactive checkboxes (`<input type="checkbox">`) the user can tick off in the browser. Each item is a short, falsifiable statement.
- **verification** — How to confirm the entire plan was executed correctly end-to-end.
- **next-steps** *(optional)* — Out-of-scope follow-ups and unsolicited ideas; never place these in `steps`. Include a prompt block the user can paste into Claude. If any next-step items are visionary or blue-sky (ambitious, speculative, non-immediate), label them with a `🔭 Wish List` badge and group them in a collapsible "Wish List" subsection at the bottom of Next Steps. Realistic, actionable items stay in the main list. Each prompt `<pre>` must be followed by a copy button.
- **unresolved-questions** *(optional)* — Collapsible `<details>` section. Omit entirely if none. Each `<pre>` prompt inside an unresolved item must be followed by a copy button.

## HTML Output Requirements

Every plan is a **single self-contained `.html` file** — no external CSS, no CDN links, no external scripts. All styles and behaviour must be inlined.

The file must:
- Use a clean, modern visual design with a clear typographic hierarchy
- Include a status badge (colour-coded: grey = todo, amber = in-progress, green = completed) in the page header
- Render the step list as numbered cards with an expandable *Verify* disclosure (`<details><summary>Verify</summary>…</details>`)
- Render acceptance criteria as interactive browser checkboxes with strikethrough on check
- Group blue-sky / wish-list items under a `🔭 Wish List` collapsible inside Next Steps — use a distinct visual treatment (dashed border, muted colour) so they are clearly non-committal
- Use a progress indicator showing how many acceptance-criteria items are checked
- Be readable without JavaScript (checkboxes work natively); minimal JS is allowed only to enhance interactivity (e.g. progress bar update on checkbox change)
- Include `<meta name="plan-status">`, `<meta name="plan-type">`, `<meta name="plan-created">`, and `<meta name="plan-repo">` tags for machine readability
- **HTML-escape all user-supplied content** before inserting it into the file — replace `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`, `"` → `&quot;`, `'` → `&#39;`. This applies especially to file paths, function names, CLI flags, and any prompt text placed inside `<pre>` blocks
- Include a **"Copy prompt"** button (`<button class="copy-prompt-btn" type="button" onclick="copyPrompt(this)" aria-label="Copy prompt to clipboard">Copy prompt</button>`) immediately after every `<pre>` block inside `.next-step-prompt` and `.unresolved-prompt` elements. Do not remove these when filling placeholders.

## Writing Style

Direct, imperative, developer-friendly — real names (file paths, function names, CLI flags), lists over prose, one idea per item, explicitly scoped. Plan only what was requested; unsolicited ideas go in `next-steps`. Blue-sky ideas always go to the Wish List subsection.

**Tone:** Write like an enthusiastic senior engineer briefing the team — concrete, direct, zero filler. **Objective:** a rallying statement, not a ticket summary (*"Ship a dark-mode toggle that persists across all three themes"* not *"Add dark mode"*). **Step actions:** lead with a strong imperative verb phrase (*"Wire up the ThemeContext provider"* not *"ThemeContext setup"*). Do not add extra emoji to prose — section icons are provided by the skeleton HTML.

## Skeleton

Copy `reference/SKELETON.html` from this plugin's skill directory as a starter for every new plan. Locate it by reading the same directory that contains this `SKILL.md` file — use `Glob` with pattern `**/plan-agent/skills/planning/reference/SKELETON.html` if the path is uncertain. Fill every placeholder (wrapped in `{curly braces}`) before writing the file. The skeleton includes copy buttons after every prompt `<pre>`; do not remove them when filling placeholders. The `--template` flag is reserved for future HTML skeleton variants; use `default` (or omit it) for now.

Each step card in the skeleton includes a `<span class="step-chip">todo</span>` before the action text. Always write `todo` as the initial chip value — the chip visually updates to `done` via CSS when the `.step-card.completed` class is applied. Do not change the chip text from `todo` in the initial HTML output.
