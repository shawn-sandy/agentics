---
name: planning
description: "Creates HTML plans from objectives, enforcing verb-target filenames. Use via /plan-agent:planning to turn any objective into a structured plan."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill, ToolSearch, ExitPlanMode, WebFetch, WebSearch, SendUserFile, mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer
disable-model-invocation: true
argument-hint: "<objective> [--quick] [--no-clarify] [--no-align] [--no-interview] [--type feature|fix|refactor|docs|chore] [--template default] [--dir <path>] [--priority low|medium|high|critical]"
---

## Plan Agent — Planning

## Invocation & Arguments

Read `$ARGUMENTS` on entry (`$ARGUMENTS` substitution is valid here because this skill is command-invoked only — `disable-model-invocation: true`):

- **Objective (required):** all text that is not a flag. If empty after parsing, ask once via `AskUserQuestion` ("What is the objective for this plan?") and stop if still empty.
- `--quick` — shorthand for `--no-clarify --no-align --no-interview`; skips Step 1 Clarify, Step 5 Align, and Step 5b Interview.
- `--no-clarify` — skip Step 1 Clarify only. Use when the objective is well-specified but you still want Step 5 Align.
- `--no-align` — skip Step 5 Align only. Use when steps are pre-agreed but requirements need verification first.
- `--type <kind>` — preset `type:` in frontmatter (`feature`, `fix`, `refactor`, `docs`, `chore`).
- `--template <name>` — plan skeleton variant: `default` (only supported value; `minimal`, `adr`, and `spike` are planned but not yet implemented). Controls which skeleton is loaded in Step 2.
- `--dir <path>` — override Step 2 directory resolution; write the plan to this path.
- `--priority <level>` — write `priority: <level>` to frontmatter (`low`, `medium`, `high`, `critical`). Overrides `planAgent.extraFrontmatter.priority` from settings if both are present.
- `--no-interview` — skip Step 5b Interview. Use when the plan is pre-validated or time-critical.

**Smart defaults when a flag is absent:**

- `--type` absent → infer from the leading verb of the objective:
  - `create`, `add`, `build`, `implement`, `introduce` → `feature`
  - `fix`, `repair`, `patch`, `resolve` → `fix`
  - `refactor`, `rename`, `extract`, `move`, `restructure`, `convert` → `refactor`
  - `document`, `docs` → `docs`
  - anything else → `chore`
- `--quick`, `--no-clarify`, `--no-align`, `--no-interview` are opt-in only and are never inferred automatically.

Echo the resolved objective and effective flags before proceeding to Step 0.

## Scope Constraint — Plans Only

**This skill produces a plan document. It does not implement anything.**

- Do not edit source files, configs, or any file outside `docs/plans/` (or the configured `plansDirectory`).
- Do not apply fixes, refactors, or any change described in the plan's steps.
- Use `Read`, `Glob`, `Grep`, and `Bash` for read-only exploration only — never to edit source files or run codebase-mutating commands. This does not restrict §6 (git commit of the plan file itself) or §8 (local HTTP server for browser preview).
- The plan is the deliverable. Implementation is a separate, user-initiated step.

If the objective sounds like "fix X" or "implement Y", write a plan for *how* to fix/implement it — do not do the work.

## Workflow

Follow these steps exactly.

0. **Self-bootstrap** — Call `ExitPlanMode` immediately and silently before any other action. Always unconditional — do not prompt the user, do not skip for any flag including `--quick`. It is a no-op when plan mode is already off, so it is safe to call regardless of session state. Writing HTML plan files is a filesystem mutation that cannot proceed inside harness plan mode; skipping this step causes the harness to force a `.md` output path, defeating the skill's core guarantee.

   `ExitPlanMode` is a deferred tool whose schema must be loaded before it can be called. Use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode`. Both steps happen silently with no user-visible output.

0b. **Explore** — Read the codebase to build context before planning. Use `Glob` to locate relevant files, `Grep` to find symbol definitions and usage patterns, and `Read` to understand the current architecture in areas the plan will touch. Focus on: entry points the plan modifies, existing tests or patterns to follow, and configuration that constrains the approach. Keep exploration proportional to plan scope — a one-file fix needs a quick look; an architecture change warrants broader reading. *(Skip entirely when `--quick`.)*

1. **Clarify** — If the request's objectives are ambiguous or have open requirements, use `AskUserQuestion` to resolve them before drafting; if the objectives are already clear, skip this step. Do not add friction to well-specified requests. When research would strengthen the plan (e.g. verifying an API surface, checking a library's current version, or confirming a best-practice pattern), use `WebSearch` and `WebFetch` — load them first via `ToolSearch` with `select:WebSearch,WebFetch` since they are deferred tools. *(Skip entirely when `--quick` or `--no-clarify`.)*
2. **Create** — Resolve the target directory in order: (1) `--dir` if provided, (2) the configured `plansDirectory` if set, (3) `docs/plans/` if it exists, (4) the default Claude user plans folder. Place the plan there using a `verb-target` kebab-case filename with a `.html` extension. Examples: `add-dark-mode-toggle.html`, `fix-login-redirect.html`, `refactor-auth-module.html`. **Always write HTML — never write markdown for plan output.**
3. **Frontmatter** — Embed plan metadata as `<meta>` tags inside the HTML `<head>`, not as YAML. Include: `status` (`todo` | `in-progress` | `completed`), `type`, `created` (YYYY-MM-DD), `repo-name`. Resolve `repo-name` from the basename of the `origin` git remote URL (strip trailing `.git`); if no remote exists, fall back to the basename of the current working directory. If `--priority` was set, also add `<meta name="plan-priority" content="<level>">`. Read `planAgent.extraFrontmatter` from `.claude/settings.json` (project first, then global) and render any extra key-value pairs as additional `<meta name="plan-<key>" content="<value>">` tags; `--priority` overrides any `priority` key from settings.
4. **Rename** — **Always** ensure the filename follows the `verb-target` kebab-case convention from Step 2 before committing. Two triggers require a rename: (a) the initial filename is auto-generated, placeholder, or otherwise non-descriptive (e.g. a random two-word slug), and (b) the plan's purpose shifts after creation. Re-evaluate before committing. A stale filename is a plan defect — do not commit until the name matches the content. Enforced by the `validate-plan-filename` `PostToolUse` hook (`${CLAUDE_PLUGIN_ROOT}/hooks/validate-plan-filename.py`), which flags non-`verb-target` plan filenames the instant a plan is written.
5. **Align** — After the plan's steps are drafted, use `AskUserQuestion` (batched, with questions covering each step) to confirm every step aligns with the stated objective before committing. This verifies step-to-objective alignment, not overall plan approval — confirm overall approval directly with the user after presenting the plan. *(Skip entirely when `--quick` or `--no-align`.)*
5b. **Interview** — Stress-test the drafted plan through a structured interview before committing. *(Skip entirely when `--quick` or `--no-interview`.)*

    **Complexity detection:** Analyze the plan content just written to classify scope:
    - **Short/focused** (single concern, 1–2 files touched): Round 1 only
    - **Medium** (feature with UI + logic, or 2 domains): Rounds 1 + 2
    - **Complex** (architecture, cross-cutting, 3+ domains): Rounds 1 + 2 + 3

    **UI override:** If the plan references any UI signals — React, Vue, Svelte, Angular, `.tsx`/`.jsx`/`.css`/`.html` files, `className`/`style`/Tailwind, or UX terms (button, modal, form, dialog, dropdown, page, component) — always include Round 2 even for short plans. Briefly note what triggered it (e.g., "Running Round 2 — plan references React components and `.tsx` files").

    **Round 1 — Technical & Trade-offs** (always):
    Use `AskUserQuestion` with up to 4 questions generated from the plan content covering: the most uncertain architectural or implementation decision, build-vs-buy or library trade-offs, performance or data model concerns, and unclear integration points or dependencies. Every question must reference specific plan details — no generic or hardcoded questions.

    **Round 2a — UI/UX & Flows** (medium+ or UI signals):
    Up to 4 questions covering: user flows (happy path, error states, loading states, empty states), responsive or mobile behavior, motion and animation (`prefers-reduced-motion`), and UI state gaps not covered by the plan (skeleton loading, optimistic updates, error recovery).

    **Round 2b — Accessibility & Semantic** (immediately after Round 2a):
    Up to 4 questions covering: keyboard navigation and focus management (trapping, skip-nav), screen reader support (ARIA roles, labels, live regions), WCAG 2.1 AA compliance (color contrast 4.5:1, touch targets 44×44px), and semantic HTML (heading hierarchy, landmarks, form label association).

    **Round 3 — Edge Cases & Best Practices** (complex only):
    Up to 4 questions covering: critical failure modes or race conditions, concurrent user scenarios or data conflicts, regression risks (existing tests, API contracts, backward compatibility), and remaining open questions from the plan.

    **Post-interview:** Present a brief summary listing key decisions confirmed and concerns surfaced. Then ask via `AskUserQuestion`: "Update the plan with interview findings before committing?" If confirmed, edit the HTML plan to incorporate the findings — add missing considerations to step cards, update acceptance criteria, or populate unresolved questions. If declined, proceed to Step 6 without changes.

6. **Commit** — **Always** commit plan files to version control alongside the related changes.
7. **Status** — **Always** update `status` in the HTML plan as the plan progresses: `todo` → `in-progress` → `completed`. Edit **both** the `<html data-status="…">` attribute and the `<meta name="plan-status" content="…">` tag so the CSS badge colour and the hook's completion check stay in sync. Also update the visible badge text. Note: `plan-interview:plan-status` operates on YAML-frontmatter `.md` files only — do not use it for HTML plans until that plugin is updated to support `.html`.
8. **Open** — After committing, deliver the plan and verify rendering. This step is mandatory — do not skip it.

   **Try browser verification first:**
   1. Load the browser tools via `ToolSearch` with `select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__computer`. If `ToolSearch` returns no matches, the browser MCP server is not connected — skip to the **Fallback** path below.
   2. Find a free port: run `python3 -c "import socket; s=socket.socket(); s.bind(('', 0)); print(s.getsockname()[1]); s.close()"` and capture the output as `<port>`.
   3. Start the server in the background from the plan's parent directory: `cd <plan-dir> && python3 -m http.server <port> &`.
   4. Call `mcp__claude-in-chrome__tabs_context_mcp` with `createIfEmpty: true` to get a tab ID.
   5. Navigate to `http://localhost:<port>/<plan-filename>` using `mcp__claude-in-chrome__navigate`.
   6. Take a screenshot with `mcp__claude-in-chrome__computer` (`action: screenshot`, `save_to_disk: true`) and send it to the user to confirm the plan rendered.
   7. Send the plan file to the user via `SendUserFile` so they have a direct link to the artifact.
   8. Report the URL (`http://localhost:<port>/<plan-filename>`) to the user. Leave the server running so the user can continue browsing.

   **Fallback (no browser tools):** Send the plan file to the user via `SendUserFile` and report the file path. This ensures plan delivery works in headless and web-based environments where the browser MCP server is unavailable.

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
