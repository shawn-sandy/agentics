# product-plans

Improve, optimize, and update product plans, PRDs, and feature proposals using
a simulated cross-functional team — coordinated by a lead that synthesizes all
findings into a structured 15-section report and (by default) applies
improvements directly to the source plan.

## Which tool to use?

| Situation | Use |
|-----------|-----|
| Product plan, PRD, or feature proposal | **`product-plans`** (this plugin) |
| Comprehensive PM / UX / Security / A11y review | **`product-plans`** (this plugin) |
| Technical implementation plan (code, files, APIs) | [`plan-interview`](../plan-interview/README.md) |
| Quick pre-coding gap check (single agent, fast) | [`plan-interview`](../plan-interview/README.md) |
| Walk every decision branch interactively | [`plan-interview:deep-grill`](../plan-interview/README.md) |

`product-plans` runs six specialist agents in parallel and is optimised for product-level documents with PM, UX, security, and accessibility concerns. `plan-interview` is a single-agent, interactive Q&A interview optimised for technical implementation plans and is faster to run.

## Overview

`product-plans` spawns a Claude Code Agent Team of six
specialist reviewers working in parallel:

| Role | Domain |
|------|--------|
| Product Manager | User value, strategy, scope, metrics, assumptions |
| Lead Developer | Feasibility, architecture, complexity, integration |
| UX Designer | Flows, usability, onboarding, empty/error states |
| Lead Frontend Engineer | Component design, state, performance, standards |
| Accessibility Expert | WCAG 2.2 AA, keyboard, screen reader, contrast |
| Security Expert | Auth, data handling, input validation, threat modeling |

A lead coordinator assigns work, collects findings, synthesizes across all
six dimensions, and writes the final report.

**Requires**: Claude Code ≥ v2.1.32 and
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings. Agent Teams is
experimental — see the [Agent Teams docs](https://code.claude.com/docs/en/agent-teams).

## Features

- **Six parallel reviewers** — each runs in its own context window, truly
  independent (no role-bleed).
- **15-section consolidated report** — executive summary through final
  decision.
- **Reviewer failure handling** — dead reviewers are respawned once; if
  unavailable, the gap is flagged in three places.
- **In-place plan update** — by default the skill applies panel improvements
  directly to the source plan (inline edits + appended Panel Review section
  with dated heading). Choose "Review only" to get the report without
  modifying the file.
- **Rejection remediation** — when the panel rejects a plan, section 14
  includes a consolidated Rejection Summary and a self-contained Remediation
  Prompt (fenced `text` block) the user can copy-paste into a fresh Claude
  session to fix the issues and re-run the review.
- **Decision banner** — the HTML artifact shows a color-coded decision banner
  (green/amber/red) for all outcomes. Reject banners include the remediation
  prompt with a copy button and clipboard fallback.
- **Background mode** — pass `--background` to suppress all interactive
  prompts: auto-selects update-in-place mode and updates the source plan
  without blocking the session. Fire via
  `/product-plans:product-plans-bg <path>` to run the whole panel unattended.
- **Auto-activation** — triggers on prompts asking for a cross-functional
  panel review, multi-role critique, or PM/Dev/UX/Frontend/Accessibility/Security
  team review of a product plan, PRD, or feature proposal.

## Installation

### Via Marketplace (recommended)

```bash
/plugin install product-plans@agentics-kit
```

### Local Development

```bash
claude --plugin-dir ./kit/plugins/product-plans
```

## Enable Agent Teams

Add to `~/.claude/settings.json` before using this skill:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## Usage

### Skills

#### `plan-review-agents` — Auto-activated

Runs a six-role Agent Team to review product plans in place. Activates
automatically when you ask to improve, optimize, or review a product plan,
PRD, or feature proposal.

Trigger phrases include: "review or improve a product plan", "cross-functional
panel review", "multi-role critique", "PM/Dev/UX/Frontend/Accessibility/Security
team review of a product plan, PRD, or feature proposal".

For technical implementation plans, use `plan-interview:plan-interview` instead.

Example prompts:

```
Improve this product plan.
Optimize docs/plans/new-feature.md before we start building.
Update this PRD based on expert feedback.
Run a cross-functional panel review on this PRD.
Get the PM, Dev, and UX team's take on this feature proposal.
I need a multi-role critique of docs/plans/new-feature.md.
```

Or point it at a specific file:

```
Run the review panel on docs/plans/my-feature.md
```

### Commands

#### `/product-plans:product-plans-bg <path>`

Run the product-plans review panel in the background. Pass the plan path as
argument. Returns immediately with a one-line ack; Claude notifies you when
the panel finishes and the plan has been updated in place.

```
/product-plans:product-plans-bg docs/plans/my-feature.md
```

If no path is provided, outputs a usage error and stops without dispatching.

You can also trigger background mode via the skill directly:

```
Review this plan in the background: docs/plans/my-feature.md --background
```

### Agents

| Agent | Invocation |
|-------|------------|
| `agent-product-plans` | Dispatched by `/product-plans:product-plans-bg`; not for direct invocation |
| `product-reviewer-pm` | Teammate-only — spawned by `plan-review-agents` skill as part of Agent Team |
| `product-reviewer-lead-developer` | Teammate-only — spawned by `plan-review-agents` skill as part of Agent Team |
| `product-reviewer-ux-designer` | Teammate-only — spawned by `plan-review-agents` skill as part of Agent Team |
| `product-reviewer-frontend-engineer` | Teammate-only — spawned by `plan-review-agents` skill as part of Agent Team |
| `product-reviewer-accessibility-expert` | Teammate-only — spawned by `plan-review-agents` skill as part of Agent Team |
| `product-reviewer-security-expert` | Teammate-only — spawned by `plan-review-agents` skill as part of Agent Team |

The six `product-reviewer-*` agents are designed exclusively for use as Agent
Team teammates spawned by the `plan-review-agents` skill. They are not
intended for standalone invocation.

## Output

The skill produces:

1. A **15-section consolidated review** in the chat, ending with a
   `Final decision: approve / approve with revisions / reject` line.
2. By default (update-in-place mode): inline edits applied to the source plan
   + a dated `## Panel Review (YYYY-MM-DD HH:MM:SS UTC)` section appended.
   Re-runs append new dated sections without stripping old ones — reviewers
   see historical reviews for context. Choose "Review only" to skip this.
3. A **self-contained HTML review artifact** (`<plan-stem>-review.html`)
   written next to the source plan. Combines the revised plan (section 15b)
   as the primary document with the full 15-section panel review as a
   collapsible appendix. Opens in any browser with no external dependencies —
   safe to upload to any static file host or attach to a ticket. Always
   emitted alongside the in-place plan update; skipped only in "Review only"
   mode.

The 15 sections are:

1. Executive summary
2. Role-by-role review (6 subsections)
3. Highest-risk issues
4. Blocking issues
5. Important but non-blocking improvements
6. UX recommendations
7. Accessibility requirements
8. Frontend implementation considerations
9. Security requirements
10. Technical feasibility concerns
11. Open questions before development
12. Recommended changes to the plan
13. Conflicts or tradeoffs between reviewers
14. Final decision _(includes Rejection Summary and Remediation Prompt when rejected)_
15a. Inline edits to apply _(update-in-place mode only)_
15b. Complete revised plan _(update-in-place mode only)_

## Plugin Structure

```
product-plans/
├── .claude-plugin/
│   └── plugin.json
├── agents/                          # Subagent definitions
│   ├── agent-product-plans.md       # Background panel agent (dispatched by command)
│   ├── product-reviewer-pm.md
│   ├── product-reviewer-lead-developer.md
│   ├── product-reviewer-ux-designer.md
│   ├── product-reviewer-frontend-engineer.md
│   ├── product-reviewer-accessibility-expert.md
│   └── product-reviewer-security-expert.md
├── commands/
│   └── product-plans-bg.md          # /product-plans:product-plans-bg dispatcher
├── skills/
│   └── plan-review-agents/
│       ├── SKILL.md                 # Skill entry point (auto-activating)
│       └── references/
│           ├── role-prompts.md      # Per-role spawn-prompt templates
│           ├── output-template.md  # Verbatim 15-section report template
│           └── html-spec.md       # HTML artifact layout/a11y/security spec
├── CHANGELOG.md
└── README.md
```

## Components

### Skill: `plan-review-agents`

Auto-activates when the user asks to improve, optimize, or update a product
plan, PRD, or feature proposal — or asks for a cross-functional panel review,
multi-role critique, or PM/Dev/UX/Frontend/Accessibility/Security team review.
For technical implementation plans, use `plan-interview:plan-interview` instead.

Triggers include: "improve this product plan", "optimize this PRD",
"update this proposal based on expert feedback", "cross-functional panel
review", "multi-role critique", "get the team's take on this PRD",
"PM/Dev/UX review of this proposal".

### Command: `product-plans-bg`

Invoke as `/product-plans:product-plans-bg <path>`.

Dispatches `agent-product-plans` with `run_in_background: true` and returns
a one-line ack immediately. The agent runs the full panel and updates the
source plan in place without blocking the user's session.

If no path is provided, outputs a usage error and stops without dispatching.

### Agent: `agent-product-plans`

Background wrapper agent (`background: true`,
`tools: Skill, Read, Write, Edit, Glob, Grep, Bash`, `maxTurns: 30`).
Confirms the plan file exists, then invokes the `plan-review-agents` skill with
`--background` and reports the updated path on completion. Dispatched by
the `product-plans-bg` command.

### Subagent definitions (teammate-only)

The six `agents/product-reviewer-*.md` files define the reviewer roles. They
are designed exclusively for use as Agent Team teammates spawned by the
`plan-review-agents` skill. They are not intended for standalone invocation via
the `Task` tool or direct `subagent_type` references outside this skill.

Each reviewer runs in its own context window, has `tools: Read, Glob, Grep,
Bash(git *)`, and produces a structured 9-item output schema that the lead
synthesizes into the final report.
