---
name: review-plan
description: Plan review Agent Team. Reviews HTML implementation plans in parallel, synthesizes findings, and applies improvements in place. Use when the user asks to review or improve an implementation plan.
allowed-tools: Read, Glob, Grep, Bash, Edit, AskUserQuestion, TodoWrite, ToolSearch, ExitPlanMode
---

# Plan Review Team Skill

**Primary purpose: improve and update plans in place.** Orchestrate a seven-reviewer Agent Team — five core plan reviewers (architecture, completeness, testability, risk, conventions) plus two UI-conditional reviewers (UX, accessibility) — to review implementation plans, synthesize findings, and apply concrete improvements directly to the source plan.

## When not to use

- **Not a code reviewer.** For code, use `code-review`. For conversational plan stress-testing, use `plan-interview`.
- **Requires Agent Teams.** Hard-stops if the feature flag is unset or Claude Code is below v2.1.32.

## Background mode

When invoked with `--background` (typically via `/plan-agent:review-plan-bg <path>` or the `agent-review-plan` background agent):

- **Requires an explicit plan path** — will not glob or prompt for a file.
- **Skips all `AskUserQuestion` calls** — no interactive prompts.
- **Defaults to "review + update plan in place"** — always applies improvements directly.
- **Safe for unattended execution** — no user interaction required at any step.

Detection: check whether `$ARGUMENTS` (or the `args` string passed via `Skill()`) contains the `--background` token. If present, set `background_mode = true` and strip the token before further argument parsing.

## Workflow

### Step 0 — Exit plan mode and create progress todos

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** — skip this step entirely when not in plan mode. When calling: use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

Use `TodoWrite` to create todos for Steps 1–8. Mark each `completed` as done.

### Step 1 — Resolve the plan file

Default: glob `docs/plans/*.html` excluding `index.html`, use most recently modified. Accept an explicit `--dir <path>` argument to override.

**Background mode:** an explicit file path is mandatory — `--dir` (directory) arguments are rejected. If `$ARGUMENTS` contains `--dir` or if no non-flag token resolving to a file (not a directory) is present, output: "`Background mode requires an explicit plan file path, not a directory. Usage: /plan-agent:review-plan <file.html> --background`" and stop.

If no file is found, output: "`Plan file not found. Provide an explicit path or place a plan HTML file in docs/plans/.`" and stop.

Announce: `"Reviewing plan: <resolved-path>"`

### Step 2 — Choose output mode

Default to "review + update plan in place".

**Background mode:** skip the `AskUserQuestion` prompt entirely — always use "review + update plan in place".

**Interactive mode:** Optionally ask `AskUserQuestion`: "Should I apply improvements directly to the plan?"
- **Review + update plan in place** _(default)_
- **Review only**

### Step 3 — Verify Agent Teams availability

Run `claude --version` and parse semver. If below `2.1.32`, stop with: "`Agent Teams require Claude Code ≥ 2.1.32. Your version is [version]. Update with: npm install -g @anthropic-ai/claude-code`"

Check feature flag:
```bash
echo "$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"
```

If empty or `0`, stop with: "`Agent Teams are disabled. Enable by adding to ~/.claude/settings.json: { \"env\": { \"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS\": \"1\" } }`"

### Step 3b — Detect UI signals

Read the resolved plan HTML (excluding `<style>` and `<script>` blocks). Scan for UI signal keywords:

**UI signals:** React, Vue, Svelte, Angular, `.tsx`, `.jsx`, `.css`, `.html`, `className`, `style`, Tailwind, button, modal, form, dialog, dropdown, page, component.

If 2+ signals found or UI-specific keywords present, set `ui_signals_present = true`. Announce: "`UI signals detected — running 7 reviewers`" or "`No UI signals — running 5 core reviewers`".

### Step 4 — Spawn the review team

Get absolute path:
```bash
realpath "<path-from-step-1>"
```

Read `references/role-prompts.md` to get the seven spawn-prompt templates. Substitute `<ABSOLUTE_PATH>` with the `realpath` output.

Create an agent team and spawn:
- Always: `plan-reviewer-architecture`, `-completeness`, `-testability`, `-risk`, `-conventions`
- When `ui_signals_present`: also `plan-reviewer-ux`, `-accessibility`

Brief each with its matching prompt from `role-prompts.md`. Wait for all spawned teammates.

Announce progress: "`Spawned 5 core reviewers`" or "`Spawned 7 reviewers (5 core + 2 UI)`".

### Step 5 — Wait, collect, and handle failures

Wait for all teammates to report via `SendMessage`. If a teammate errors or goes idle, respawn once. If it errors again, mark "`Reviewer unavailable`" and continue. Do not begin synthesis until all roles are either complete or marked unavailable.

### Step 6 — Synthesize findings

Read `references/output-template.md`. Gather each reviewer's findings (from their `SendMessage` output). Populate the template:

- **Executive Summary:** Synthesize overall assessment.
- **Role-by-Role:** Summarize each reviewer's findings.
- **Agreements & Conflicts:** Where reviewers agree (amplify), conflict (explain tradeoff).
- **Highest-Risk Issues:** Distilled list from all findings.
- **Inline Edits to Apply:** For each accepted improvement, a table row with: target HTML element (CSS selector), action (`edit`/`append`/`insert`), and new content.
- **Revised Plan:** (Filled after Step 7.)

**Rejection path:** If the team consensus is "reject", populate the reject-only subsections per the template. Otherwise, omit reject-only content.

### Step 7 — Integrate panel findings into the source plan

Skip if `output_mode = "review only"`.

**Pass 1 — Inline edits:** For each row in the "Inline Edits to Apply" table, apply one `Edit` call against the resolved plan:
- `edit` — replace targeted element's content.
- `append` — add to the end of the element.
- `insert after "[anchor]"` — insert new sibling after anchor.

HTML-escape all inserted content. Never modify `<style>` or `<script>`. Skip rows whose target cannot be matched (log warning, continue).

**Pass 2 — Append team review:** Use `Edit` to append a new `<details>` section before `</main>`:
```html
<details id="team-review-TIMESTAMP" class="team-review">
  <summary>Team Review (YYYY-MM-DD HH:MM:SS UTC)</summary>
  <div class="review-body">
    <!-- Full synthesized report here, HTML-escaped -->
  </div>
</details>
```

Announce: "`Plan updated in place: <resolved-path>`"

### Step 8 — Clean up the team

Ensure all teammates are finished or shut down, then issue: "`Clean up the team.`" (lead cleanup, not teammate cleanup).

---

## Conditional Activation

This skill runs only when the user asks to review or improve an implementation plan. It does not auto-activate on other plan types (e.g., high-level roadmaps, spike plans).
