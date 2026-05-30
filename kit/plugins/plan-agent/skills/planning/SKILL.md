---
name: planning
description: "Creates a structured, self-contained HTML implementation plan from a stated objective — enforcing verb-target filenames, required sections, and HTML metadata. Use when the user wants to turn an objective into a detailed plan via /plan-agent:planning. Does not review or modify existing plans — for that use plan-interview:plan-interview."
allowed-tools: Read, Write, Edit, Glob, Bash, AskUserQuestion, Skill, ToolSearch, mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer
disable-model-invocation: true
argument-hint: "<objective> [--quick] [--no-clarify] [--no-align] [--type feature|fix|refactor|docs|chore] [--template default] [--dir <path>] [--priority low|medium|high|critical] [--interview]"
---

## Plan Agent — Planning

## Invocation & Arguments

Read `$ARGUMENTS` on entry (`$ARGUMENTS` substitution is valid here because this skill is command-invoked only — `disable-model-invocation: true`):

- **Objective (required):** all text that is not a flag. If empty after parsing, ask once via `AskUserQuestion` ("What is the objective for this plan?") and stop if still empty.
- `--quick` — shorthand for `--no-clarify --no-align`; skips both §1 Clarify and §5 Align.
- `--no-clarify` — skip §1 Clarify only. Use when the objective is well-specified but you still want §5 Align.
- `--no-align` — skip §5 Align only. Use when steps are pre-agreed but requirements need verification first.
- `--type <kind>` — preset `type:` in frontmatter (`feature`, `fix`, `refactor`, `docs`, `chore`).
- `--template <name>` — plan skeleton variant: `default` (only supported value; `minimal`, `adr`, and `spike` are planned but not yet implemented). Controls which skeleton is loaded in §2.
- `--dir <path>` — override §2 directory resolution; write the plan to this path.
- `--priority <level>` — write `priority: <level>` to frontmatter (`low`, `medium`, `high`, `critical`). Overrides `planAgent.extraFrontmatter.priority` from settings if both are present.
- `--interview` — after writing the plan, call `Skill(skill: "plan-interview:plan-interview", args: "<plan-path>")`. If that plugin is absent, note "plan-interview plugin not found — skipping" and continue.

**Smart defaults when a flag is absent:**

- `--type` absent → infer from the leading verb of the objective:
  - `create`, `add`, `build`, `implement`, `introduce` → `feature`
  - `fix`, `repair`, `patch`, `resolve` → `fix`
  - `refactor`, `rename`, `extract`, `move`, `restructure`, `convert` → `refactor`
  - `document`, `docs` → `docs`
  - anything else → `chore`
- `--quick`, `--no-clarify`, `--no-align` are opt-in only and are never inferred automatically.

Echo the resolved objective and effective flags before proceeding to §0.

## Workflow

Follow these steps exactly.

1. **Clarify** — If the request's objectives are ambiguous or have open requirements, use `AskUserQuestion` to resolve them before drafting; if the objectives are already clear, skip this step. Do not add friction to well-specified requests. *(Skip entirely when `--quick` or `--no-clarify`.)*
2. **Create** — Resolve the target directory in order: (1) `--dir` if provided, (2) the configured `plansDirectory` if set, (3) `docs/plans/` if it exists, (4) the default Claude user plans folder. Place the plan there using a `verb-target` kebab-case filename with a `.html` extension. Examples: `add-dark-mode-toggle.html`, `fix-login-redirect.html`, `refactor-auth-module.html`. **Always write HTML — never write markdown for plan output.**
3. **Frontmatter** — Embed plan metadata as `<meta>` tags inside the HTML `<head>`, not as YAML. Include: `status` (`todo` | `in-progress` | `completed`), `type`, `created` (YYYY-MM-DD), `repo-name`. Resolve `repo-name` from the basename of the `origin` git remote URL (strip trailing `.git`); if no remote exists, fall back to the basename of the current working directory. If `--priority` was set, also add `<meta name="plan-priority" content="<level>">`. Read `planAgent.extraFrontmatter` from `.claude/settings.json` (project first, then global) and render any extra key-value pairs as additional `<meta name="plan-<key>" content="<value>">` tags; `--priority` overrides any `priority` key from settings.
4. **Rename** — **Always** ensure the filename follows the `verb-target` kebab-case convention from §2 before committing. Two triggers require a rename: (a) the initial filename is auto-generated, placeholder, or otherwise non-descriptive (e.g. a random two-word slug), and (b) the plan's purpose shifts after creation. Re-evaluate before committing. A stale filename is a plan defect — do not commit until the name matches the content. Enforced by the `validate-plan-filename` `PostToolUse` hook (`${CLAUDE_PLUGIN_ROOT}/hooks/validate-plan-filename.py`), which flags non-`verb-target` plan filenames the instant a plan is written.
5. **Align** — After the plan's steps are drafted, use `AskUserQuestion` (batched, with questions covering each step) to confirm every step aligns with the stated objective before committing. This verifies step-to-objective alignment, not overall plan approval — confirm overall approval directly with the user after presenting the plan. *(Skip entirely when `--quick` or `--no-align`.)*
6. **Commit** — **Always** commit plan files to version control alongside the related changes.
7. **Status** — **Always** update `status` in the HTML plan as the plan progresses: `todo` → `in-progress` → `completed`. Edit **both** the `<html data-status="…">` attribute and the `<meta name="plan-status" content="…">` tag so the CSS badge colour and the hook's completion check stay in sync. Also update the visible badge text. Note: `plan-interview:plan-status` operates on YAML-frontmatter `.md` files only — do not use it for HTML plans until that plugin is updated to support `.html`.
8. **Open** — After committing, open the plan in a browser via a local Python HTTP server to confirm it renders correctly. This step is mandatory — do not skip it. Steps:
   1. Find a free port: run `python3 -c "import socket; s=socket.socket(); s.bind(('', 0)); print(s.getsockname()[1]); s.close()"` and capture the output as `<port>`.
   2. Start the server in the background from the plan's parent directory: `cd <plan-dir> && python3 -m http.server <port> &`.
   3. Load the browser tools via `ToolSearch` with `select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__computer`, then call `mcp__claude-in-chrome__tabs_context_mcp` with `createIfEmpty: true` to get a tab ID.
   4. Navigate to `http://localhost:<port>/<plan-filename>` using `mcp__claude-in-chrome__navigate`.
   5. Take a screenshot with `mcp__claude-in-chrome__computer` (`action: screenshot`, `save_to_disk: true`) and send it to the user to confirm the plan rendered.
   6. Report the URL (`http://localhost:<port>/<plan-filename>`) to the user. Leave the server running so the user can continue browsing.

After §8, if `--interview` was set: call `Skill(skill: "plan-interview:plan-interview", args: "<plan-path>")` to stress-test the plan. If the plugin is absent, note "plan-interview plugin not found — skipping" and continue.

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

Copy `reference/SKELETON.html` from this plugin's skill directory as a starter for every new plan. Locate it by reading the same directory that contains this `SKILL.md` file — use `Glob` with pattern `**/plan-agent/skills/planning/reference/SKELETON.html` if the path is uncertain. Fill every placeholder (wrapped in `{curly braces}`) before writing the file. The skeleton includes copy buttons after every prompt `<pre>`; do not remove them when filling placeholders. `minimal`, `adr`, and `spike` template variants are planned but not yet implemented — use `SKELETON.html` for all plans until those variants ship.

Each step card in the skeleton includes a `<span class="step-chip">todo</span>` before the action text. Always write `todo` as the initial chip value — the chip visually updates to `done` via CSS when the `.step-card.completed` class is applied. Do not change the chip text from `todo` in the initial HTML output.
