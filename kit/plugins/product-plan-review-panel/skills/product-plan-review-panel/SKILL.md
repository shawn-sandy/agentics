---
name: product-plan-review-panel
description: "Use when the user asks to review, critique, validate, stress-test, harden, or prepare a product plan, PRD, feature proposal, UX flow, technical plan, or implementation plan for development — runs a simulated cross-functional review panel (PM, Lead Developer, UX, Frontend, Accessibility) coordinated by a lead and produces a consolidated review plus a revised plan."
allowed-tools: Read, Glob, Bash, AskUserQuestion, TodoWrite, Edit, Write
---

# Product Plan Review Panel

Orchestrate a five-reviewer Agent Team — Product Manager, Lead Developer,
UX Designer, Lead Frontend Engineer, Accessibility Expert — coordinated by
a lead that synthesizes findings into a 14-section report and (by default)
a revised plan.

## When not to use

- **Do not invoke from plan mode.** This skill performs writes and spawns
  agent teammates; both require the session to be outside plan mode.
- **Not a code reviewer.** For code, use `code-review`. For conversational
  plan stress-testing without a panel, use `plan-interview`.
- **Requires Agent Teams.** Hard-stops if `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
  is not set or Claude Code is below v2.1.32. See Step 3.

## Table of Contents

- [Step 0 — Create progress todos](#step-0--create-progress-todos)
- [Step 1 — Resolve the plan file](#step-1--resolve-the-plan-file)
- [Step 2 — Choose output mode](#step-2--choose-output-mode)
- [Step 3 — Verify Agent Team availability](#step-3--verify-agent-team-availability)
- [Step 4 — Spawn the review team](#step-4--spawn-the-review-team)
- [Step 5 — Wait, collect, and handle failures](#step-5--wait-collect-and-handle-failures)
- [Step 6 — Synthesize findings](#step-6--synthesize-findings)
- [Step 7 — Persist the revised plan](#step-7--persist-the-revised-plan)
- [Step 8 — Clean up the team](#step-8--clean-up-the-team)

## Instructions

### Step 0 — Create progress todos

Use `TodoWrite` to create a todo for each step below (Steps 1–8), all
starting `pending`. Mark each `completed` as you finish that step.

### Step 1 — Resolve the plan file

Use the first match from this priority order:

1. **User message** — an explicit file path in the user's message.
2. **Open IDE file** — a `.md` file currently open in the editor whose
   content contains plan-style headings (`## Steps`, `## Context`,
   `## Implementation`, `## Plan`).
3. **Project settings** — `plansDirectory` key in `.claude/settings.json`;
   glob `*.md` from that path and use the most recently modified.
4. **Global settings** — same key in `~/.claude/settings.json`.
5. **Default** — glob `~/.claude/plans/*.md`; use the most recently modified.

If no file is found, tell the user and stop.

Announce: `"Reviewing plan: <resolved-path>"`

### Step 2 — Choose output mode

Ask the user:

> "After the panel review, should I produce a revised plan?"

Options (use `AskUserQuestion`):
- **Review + revised plan** _(preselected)_
- **Review only**

Record the choice as `output_mode` and continue.

### Step 3 — Verify Agent Team availability

Run `claude --version`. Parse the output using the pattern
`^(\d+)\.(\d+)\.(\d+)`. Compare only the first three numeric components
and ignore any pre-release suffix (e.g. `-beta`, `+dev`). If the version
is below `2.1.32`, stop and output:

> "Agent Teams require Claude Code ≥ 2.1.32. Your version is [version].
> Update with: `npm install -g @anthropic-ai/claude-code`
> Then restart Claude Code and re-run this skill."

Also check whether the feature flag is active:

```bash
echo "$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"
```

If the output is empty or `0`, stop and output:

> "Agent Teams are disabled. Enable by adding this to ~/.claude/settings.json:
> ```json
> { \"env\": { \"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS\": \"1\" } }
> ```
> Restart Claude Code and re-run this skill."

Do not fall back to in-prompt role-play.

### Step 4 — Spawn the review team

Get the absolute path of the resolved plan file:

```bash
realpath "<resolved-path>"
```

Read [references/role-prompts.md](references/role-prompts.md) to get the
five spawn-prompt templates. Substitute `<ABSOLUTE_PATH>` with the
`realpath` output. If session-specific constraints were discussed before
this skill started, add a `Session notes:` block to each prompt as
described at the top of the reference file.

Execute this directive:

```text
Create an agent team to review the product plan at <ABSOLUTE_PATH>.
Spawn all five teammates immediately so they review in parallel, using
these subagent types:
  - product-reviewer-pm
  - product-reviewer-lead-developer
  - product-reviewer-ux-designer
  - product-reviewer-frontend-engineer
  - product-reviewer-accessibility-expert
Brief each teammate with the matching spawn prompt from
references/role-prompts.md (with <ABSOLUTE_PATH> already substituted).
Wait for all five teammates to send their findings before synthesizing.
```

### Step 5 — Wait, collect, and handle failures

Wait for all five teammates to mark their tasks complete on the shared
task list.

**If a teammate stops on an error or goes idle without findings:**

1. Respawn it once with the same role prompt.
2. If it errors again, mark that role `Reviewer unavailable — not assessed`.
3. Surface the gap in **three places** in the report: the Executive
   Summary (section 1), that role's section in Role-by-Role Review
   (section 2), and as a named line item in Highest-Risk Issues (section 3).

Do not begin synthesis until all five roles are either complete or
explicitly marked unavailable.

### Step 6 — Synthesize findings

Read [references/output-template.md](references/output-template.md).

Before filling the template, compare the five reviewers' findings:

- **Agree**: where multiple reviewers flag the same issue, amplify it as
  a confirmed concern and note the overlap.
- **Conflict**: where recommendations contradict each other, explain the
  tradeoff and recommend a resolution in section 12 of the report.
- **Assumptions**: challenge any weak or unstated assumption surfaced by
  any reviewer.
- **Balance**: do not let the most technical perspective dominate —
  all five roles must be equally represented.

Reproduce the verbatim template with findings filled in. Omit section 14
if `output_mode = review only`.

### Step 7 — Persist the revised plan

Skip entirely if `output_mode = review only`.

Ask the user where to write the revised plan (`AskUserQuestion`):

- **Sibling file** — write `<original-stem>-revised.md` next to the
  source. Non-destructive; user diffs and picks the keeper.
- **Overwrite original** — replace the source in place. Only proceed if
  `git status --porcelain "<resolved-path>"` returns empty (source is
  clean). If the check fails, explain and fall back to the sibling option.
- **Append to original** — add `## Revised Plan` as a new section at the
  end of the source file.

Write using `Write` (sibling or overwrite) or `Edit` (append). The content
is section 14 of the synthesized output, written verbatim — do not
re-generate.

### Step 8 — Clean up the team

Ensure all active teammates have finished or been shut down, then issue:

```text
Clean up the team.
```

Per the [Agent Teams docs](https://code.claude.com/docs/en/agent-teams),
always use the lead to clean up; cleanup from a teammate leaves resources
in an inconsistent state.
