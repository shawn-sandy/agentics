# product-plan-review-panel

Review product plans, PRDs, and feature proposals using a simulated
cross-functional team — coordinated by a lead that synthesizes all findings
into a structured 14-section report and (by default) a revised plan.

## Overview

`product-plan-review-panel` spawns a Claude Code Agent Team of five
specialist reviewers working in parallel:

| Role | Domain |
|------|--------|
| Product Manager | User value, strategy, scope, metrics, assumptions |
| Lead Developer | Feasibility, architecture, complexity, integration |
| UX Designer | Flows, usability, onboarding, empty/error states |
| Lead Frontend Engineer | Component design, state, performance, standards |
| Accessibility Expert | WCAG 2.2 AA, keyboard, screen reader, contrast |

A lead coordinator assigns work, collects findings, synthesizes across all
five dimensions, and writes the final report.

**Requires**: Claude Code ≥ v2.1.32 and
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings. Agent Teams is
experimental — see the [Agent Teams docs](https://code.claude.com/docs/en/agent-teams).

## Features

- **Five parallel reviewers** — each runs in its own context window, truly
  independent (no role-bleed).
- **14-section consolidated report** — executive summary through final
  decision.
- **Reviewer failure handling** — dead reviewers are respawned once; if
  unavailable, the gap is flagged in three places.
- **Revised plan output** — by default the skill asks where to save the
  revised plan (sibling file, overwrite with git-safety check, or append).
- **Auto-activation** — triggers on any prompt asking to review, critique,
  validate, or stress-test a product plan, PRD, or feature proposal.

## Installation

```bash
/plugin install product-plan-review-panel@agentics-kit
```

Or load locally for testing:

```bash
claude --plugin-dir ~/devbox/agentics/kit/plugins/product-plan-review-panel
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

The skill activates automatically when you describe a review task:

```
Review this PRD and tell me what the team thinks.
Stress-test the plan at docs/plans/new-feature.md.
Critique this feature proposal before we start building.
```

Or point it at a specific file:

```
Run the review panel on docs/plans/my-feature.md
```

## Output

The skill produces:

1. A **14-section consolidated review** in the chat, ending with a
   `Final decision: approve / approve with revisions / reject` line.
2. Optionally, a **revised plan** written to a file destination of your
   choice (sibling, overwrite, or append).

The 14 sections are:

1. Executive summary
2. Role-by-role review (5 subsections)
3. Highest-risk issues
4. Blocking issues
5. Important but non-blocking improvements
6. UX recommendations
7. Accessibility requirements
8. Frontend implementation considerations
9. Technical feasibility concerns
10. Open questions before development
11. Recommended changes to the plan
12. Conflicts or tradeoffs between reviewers
13. Final decision
14. Revised product plan _(review + revised plan mode only)_

## Plugin Structure

```
product-plan-review-panel/
├── .claude-plugin/
│   └── plugin.json
├── agents/                          # Teammate-only subagent definitions
│   ├── product-reviewer-pm.md
│   ├── product-reviewer-lead-developer.md
│   ├── product-reviewer-ux-designer.md
│   ├── product-reviewer-frontend-engineer.md
│   └── product-reviewer-accessibility-expert.md
├── skills/
│   └── product-plan-review-panel/
│       ├── SKILL.md                 # Skill entry point (auto-activating)
│       └── references/
│           ├── role-prompts.md      # Per-role spawn-prompt templates
│           └── output-template.md  # Verbatim 14-section report template
├── CHANGELOG.md
└── README.md
```

## Components

### Skill: `product-plan-review-panel`

Auto-activates when the user asks to review, critique, validate,
stress-test, harden, or prepare a product plan, PRD, or feature proposal.

Triggers include: "review this plan", "critique the PRD", "stress-test
this proposal", "validate this feature spec", "prepare this plan for
development".

### Subagent definitions (teammate-only)

The five `agents/*.md` files define the reviewer roles. They are designed
exclusively for use as Agent Team teammates spawned by the
`product-plan-review-panel` skill. They are not intended for standalone
invocation via the `Task` tool or direct `subagent_type` references outside
this skill.

Each reviewer runs in its own context window, has `tools: Read, Glob, Grep,
Bash(git *)`, and produces a structured 9-item output schema that the lead
synthesizes into the final report.
