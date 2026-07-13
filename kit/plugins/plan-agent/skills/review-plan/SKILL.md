---
name: review-plan
model: opus
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
- **Implies `--skip-analysis`** — the Step 6b walkthrough never runs unattended.
- **Safe for unattended execution** — no user interaction required at any step.

Detection: check whether `$ARGUMENTS` (or the `args` string passed via `Skill()`) contains the `--background` token. If present, set `background_mode = true` and strip the token before further argument parsing. In the same pass, detect a `--skip-analysis` token (set `skip_analysis = true`) and a `--triage-top <N>` token (capture the integer `N`; default unset = full per-finding triage); strip both tokens before further argument parsing. `background_mode = true` forces `skip_analysis = true`, whether or not `--skip-analysis` was passed.

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

**Lead-vs-reviewer read split:** Reviewers read only the plan's spec — their briefs in `role-prompts.md` run the extractor (`node scripts/extract-plan-spec.mjs <plan>`), which derives the spec from the visible DOM (or an embedded digest on legacy plans) in a few thousand tokens instead of the full styled HTML. The lead (this skill) still reads the **full HTML**: Step 3b keyword scanning and Step 7's CSS-selector edits both need the real markup, not the spec.

Announce progress: "`Spawned 5 core reviewers`" or "`Spawned 7 reviewers (5 core + 2 UI)`".

### Step 5 — Wait, collect, and handle failures

Wait for all teammates to report via `SendMessage`. If a teammate errors or goes idle, respawn once. If it errors again, mark "`Reviewer unavailable`" and continue. Do not begin synthesis until all roles are either complete or marked unavailable.

### Step 6 — Synthesize findings

Read `references/output-template.md`. Gather each reviewer's findings (from their `SendMessage` output). Populate the template:

- **Executive Summary:** Synthesize overall assessment.
- **Role-by-Role:** Summarize each reviewer's findings.
- **Agreements & Conflicts:** Where reviewers agree (amplify), conflict (explain tradeoff).
- **Highest-Risk Issues:** Distilled list from all findings.
- **Inline Edits to Apply:** For each accepted improvement, a table row with: target HTML element (CSS selector), action (`edit`/`append`/`insert`), new content, and Source / Rationale — the originating reviewer plus a brief why. Step 6b's triage presents this Source / Rationale alongside each finding.
- **Revised Plan:** (Filled after Step 7.)

**Rejection path:** If the team consensus is "reject", populate the reject-only subsections per the template. Otherwise, omit reject-only content.

### Step 6b — Walkthrough & Analysis

An interactive triage of the synthesized findings before any edits are applied.

**Skip condition:** Skip Step 6b entirely when `skip_analysis = true`, when `background_mode = true`, or when `output_mode = "review only"` (chosen at Step 2). When skipped via `skip_analysis` or `background_mode`, Step 7 receives the full "Inline Edits to Apply" table; when skipped because `output_mode = "review only"`, Step 7 applies no edits — Pass 1 is skipped and only the Team Review is appended.

**Ask-first gate:** Ask `AskUserQuestion`: "Walk through the findings before applying?"
- **Walk through findings** _(default, recommended)_ — run the per-finding triage loop below.
- **Apply all** — bypass the walkthrough by choice; Step 7 applies the full table.
- **Review only** — set `output_mode = "review only"`; Step 7 applies no edits but still appends the Team Review.

Declining the gate is **not** equivalent to `--skip-analysis`: the gate was still shown. `--skip-analysis` suppresses the gate itself.

**Per-finding triage loop:** Iterate the rows of the "Inline Edits to Apply" table, batching at most 4 findings per `AskUserQuestion` call (one question per finding). Each question presents the finding's Source / Rationale (originating reviewer + why, from the synthesis table) and its proposed content, with options:
- **Accept** — keep the edit as-is.
- **Modify** — keep the edit, marked for revision.
- **Reject** — drop the edit.

**Modify semantics:** Modify does **not** collect inline free-text. It marks the finding for a single post-walkthrough edit pass that runs once after the triage loop, in which the developer revises the kept edits directly in the plan.

**`--triage-top <N>`:** When set, individually triage only the `N` highest-risk findings (ranked per the Highest-Risk Issues synthesis section) and batch-accept the remainder. Default unset = full per-finding triage. The flag is ignored whenever the walkthrough is skipped.

**Output:** Step 6b produces an `accepted_edits` list — findings accepted as-is plus modified findings with their revised content; rejected findings are excluded. `accepted_edits` is consumed by Step 7 Pass 1, and all triage decisions (accepted / modified / rejected) are retained for Step 7 Pass 2's triage record.

### Step 7 — Integrate panel findings into the source plan

Pass 1 is skipped when `output_mode = "review only"`; Pass 2 always runs. (When the Step 6b gate was declined via "Review only": no edits applied, Team Review still appended.)

**Pass 1 — Inline edits:** When the Step 6b walkthrough ran, iterate **only** `accepted_edits` — findings accepted as-is plus revised-modified findings. The full-table fallback — iterating every row of the "Inline Edits to Apply" table — fires **only** when the walkthrough was bypassed: `--skip-analysis`, background mode, or the "Apply all" gate choice. Declining the gate ("Review only") is **not** a fallback case. For each edit, apply one `Edit` call against the resolved plan:
- `edit` — replace targeted element's content.
- `append` — add to the end of the element.
- `insert after "[anchor]"` — insert new sibling after anchor.

HTML-escape all inserted content. Never modify `<style>` or `<script>`.

Skip rows whose target cannot be matched (log warning, continue).

**Pass 2 — Append team review:** Use `Edit` to append a new `<details>` section before `</main>`:
```html
<details id="team-review-TIMESTAMP" class="team-review">
  <summary>Team Review (YYYY-MM-DD HH:MM:SS UTC)</summary>
  <div class="review-body">
    <!-- Full synthesized report here, HTML-escaped -->
  </div>
</details>
```

When the Step 6b walkthrough ran, the review body also includes a triage-outcome summary — accepted findings (applied as-is), modified findings (with their revised content), and rejected findings (recorded but not applied) — per the "Triage Outcome" subsection of `references/output-template.md`.

Announce: "`Plan updated in place: <resolved-path>`"

### Step 8 — Clean up the team

Ensure all teammates are finished or shut down, then issue: "`Clean up the team.`" (lead cleanup, not teammate cleanup).

---

## Conditional Activation

This skill runs only when the user asks to review or improve an implementation plan. It does not auto-activate on other plan types (e.g., high-level roadmaps, spike plans).
