---
name: plan-review-agents
description: "Use when the user asks to review, improve, optimize, or update a product plan, PRD, feature proposal, or implementation plan; or asks for a cross-functional panel review, multi-role critique, or PM/Dev/UX/Frontend/Accessibility/Security team review."
allowed-tools: Read, Glob, Bash, AskUserQuestion, TodoWrite, Edit, Write, ToolSearch, ExitPlanMode
---

# Product Plan Review Panel

**Primary purpose: improve, optimize, and update the plan.** Orchestrate a
six-reviewer Agent Team — Product Manager, Lead Developer, UX Designer,
Lead Frontend Engineer, Accessibility Expert, Security Expert — coordinated by
a lead that synthesizes findings into a 15-section report and (by default)
applies concrete improvements directly to the source plan. Review-only mode
skips the edit pass and produces the report only. After integrating findings,
a self-contained HTML review artifact (`<plan-stem>-review.html`) is emitted
next to the source plan as a shareable, browser-openable companion.

## When not to use

- **Not a code reviewer.** For code, use `code-review`. For conversational
  plan stress-testing without a panel, use `plan-interview`.
- **Requires Agent Teams.** Hard-stops if `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
  is not set or Claude Code is below v2.1.32. See Step 3.

## Table of Contents

- [Step 0 — Exit plan mode and create progress todos](#step-0--exit-plan-mode-and-create-progress-todos)
- [Step 1 — Resolve the plan file](#step-1--resolve-the-plan-file)
- [Step 2 — Choose output mode](#step-2--choose-output-mode)
- [Step 3 — Verify Agent Team availability](#step-3--verify-agent-team-availability)
- [Step 4 — Spawn the review team](#step-4--spawn-the-review-team)
- [Step 5 — Wait, collect, and handle failures](#step-5--wait-collect-and-handle-failures)
- [Step 6 — Synthesize findings](#step-6--synthesize-findings)
- [Step 7 — Integrate panel findings into the source plan](#step-7--integrate-panel-findings-into-the-source-plan)
- [Step 8 — Emit self-contained HTML artifact](#step-8--emit-self-contained-html-artifact)
- [Step 9 — Clean up the team](#step-9--clean-up-the-team)

## Instructions

### Step 0 — Exit plan mode and create progress todos

**Background flag detection**: Scan `$ARGUMENTS` for the literal text
`--background`. If found, set `mode = background`; otherwise set
`mode = interactive`. This flag governs branching in Steps 1, 2, and 7 —
record it once here so subsequent steps can reference it without re-parsing.

`ExitPlanMode` is a deferred tool. Use `ToolSearch` with `select:ExitPlanMode`
first, then call `ExitPlanMode`. Both calls happen silently with no
user-visible output. This is a no-op when plan mode is already off.

Use `TodoWrite` to create a todo for each step below (Steps 1–9), all
starting `pending`. Mark each `completed` as you finish that step.

### Step 1 — Resolve the plan file

When `mode = background`: require an explicit file path in `$ARGUMENTS`.
Parse `$ARGUMENTS` using shell-style tokenization (respect quoted strings so
paths with spaces are preserved), discard tokens that start with `--`, and
take the first remaining token as the path (strip surrounding quotes if any).
This handles all orderings (`<path>`, `<path> --background`,
`--background <path>`) and quoted paths such as `"docs/plans/My Plan.md"`.
If no non-flag token is present, output:

> `Background mode requires a plan path`

and stop. Do not attempt the IDE, settings, or glob fallbacks — silent
file selection is unsafe when no human is watching.

When `mode = interactive`: use the first match from this priority order:

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

When `mode = background`: set `output_mode = "review + update plan in place"` without
calling `AskUserQuestion`. Continue to Step 3.

When `mode = interactive`: ask the user:

> "After the panel review, should I apply the improvements directly to the plan?"

Options (use `AskUserQuestion`):
- **Review + update plan in place** _(preselected)_
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

Get the absolute path of the resolved plan file by substituting the path
from Step 1 into the command below:

```bash
realpath "<path-from-step-1>"
```

Read [references/role-prompts.md](references/role-prompts.md) to get the
six spawn-prompt templates. Substitute `<ABSOLUTE_PATH>` with the
`realpath` output. If session-specific constraints were discussed before
this skill started, add a `Session notes:` block to each prompt as
described at the top of the reference file.

Execute this directive:

```text
Create an agent team to review the product plan at <ABSOLUTE_PATH>.
Spawn all six teammates immediately so they review in parallel, using
these subagent types:
  - product-reviewer-pm
  - product-reviewer-lead-developer
  - product-reviewer-ux-designer
  - product-reviewer-frontend-engineer
  - product-reviewer-accessibility-expert
  - product-reviewer-security-expert
Brief each teammate with the matching spawn prompt from
references/role-prompts.md (with <ABSOLUTE_PATH> already substituted).
Wait for all six teammates to send their findings before synthesizing.
```

### Step 5 — Wait, collect, and handle failures

Wait for all six teammates to mark their tasks complete on the shared
task list.

**If a teammate stops on an error or goes idle without findings:**

1. Respawn it once with the same role prompt.
2. If it errors again, mark that role `Reviewer unavailable — not assessed`.
3. Surface the gap in **three places** in the report: the Executive
   Summary (section 1), that role's section in Role-by-Role Review
   (section 2), and as a named line item in Highest-Risk Issues (section 3).

Do not begin synthesis until all six roles are either complete or
explicitly marked unavailable.

### Step 6 — Synthesize findings

Read [references/output-template.md](references/output-template.md).

Before filling the template, compare the six reviewers' findings:

- **Agree**: where multiple reviewers flag the same issue, amplify it as
  a confirmed concern and note the overlap.
- **Conflict**: where recommendations contradict each other, explain the
  tradeoff and recommend a resolution in section 12 of the report.
- **Assumptions**: challenge any weak or unstated assumption surfaced by
  any reviewer.
- **Balance**: do not let the most technical perspective dominate —
  all six roles must be equally represented.

Reproduce the verbatim template with findings filled in. Omit section 15
if `output_mode = review only`.

### Step 7 — Integrate panel findings into the source plan

Skip entirely if `output_mode = review only`.

Integrate the synthesized findings into the source plan file at the
resolved path from Step 1. Two passes, both using `Edit`:

**Pass 1 — Apply inline edits.** Read section 15a ("Inline Edits to
Apply") of the synthesized output. For each row in the table, apply one
`Edit` call against the resolved plan path:

- `edit` — replace the matched section's body with the given content.
- `append` — add the given content to the end of the named section.
- `insert after "[anchor]"` — insert the given content as a new section
  immediately after the named anchor heading.

Apply rows in order. Skip any row whose section heading cannot be matched
in the source plan (log a one-line warning; do not stop).

**Pass 2 — Append panel review.** Use `Edit` to append a new
`## Panel Review` section at the very end of the source plan. The content
is the full verbatim synthesized report (sections 1–15b, including the
inline-edits table and the complete revised plan). Do not re-generate;
copy from synthesis.

Both interactive and background modes share this path. There is no
`AskUserQuestion`, no sibling file, no `git status --porcelain` guard.
Announce:

> `Plan updated in place: <resolved-path> (inline edits applied + Panel Review appended)`

The HTML review artifact will be announced separately in Step 8.

### Step 8 — Emit self-contained HTML artifact

When `output_mode = review only`, skip this step entirely (section 15b does
not exist; there is no revised plan to use as the primary surface). Otherwise,
this step runs in both interactive and background modes.

Read [references/html-spec.md](references/html-spec.md). Synthesize a single
self-contained HTML string from the retained `synthesized_report` string
produced in Step 6. Do **not** re-synthesize from reviewer outputs; do
**not** read external CSS. Apply `body class="theme-default"` (theme
selection is out of scope for v3.3.0).

**Derive the output path:**

1. Take the absolute path of the resolved plan file from Step 1.
2. Extract the basename (filename only, no directory).
3. Strip the `.md` extension.
4. Replace any character outside `[A-Za-z0-9._-]` with `-`.
5. Append `-review.html`.
6. Confirm the target directory is the same as the source plan's directory
   and is not a symlink.

**Write the file:**

All plan content and reviewer output interpolated into the HTML MUST be
HTML-escaped per the "Security & Escaping Contract" section of
`references/html-spec.md`. All content must be readable without JavaScript;
JS provides scroll-spy active-state in the TOC only (progressive enhancement).

Write the HTML string via `Write`; if the file already exists, overwrite it
silently. If `Write` fails (read-only directory, disk full, permission
denied), announce:

> `HTML artifact could not be written: <path> — <reason>`

and continue to Step 9 (cleanup must still run).

On success, announce:

> `HTML review artifact written: <resolved-html-path>`

### Step 9 — Clean up the team

Ensure all active teammates have finished or been shut down, then issue:

```text
Clean up the team.
```

Per the [Agent Teams docs](https://code.claude.com/docs/en/agent-teams),
always use the lead to clean up; cleanup from a teammate leaves resources
in an inconsistent state.
