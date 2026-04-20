# plan-interview Plugin

Stress-tests implementation plans with structured multi-round interviews before coding begins. Surfaces technical trade-offs, UX/accessibility risks, edge cases, and out-of-scope concerns you might not have considered.

## Purpose

Writing a plan is not the same as stress-testing one. This plugin conducts a structured interview — asking targeted questions derived from the plan's own content — to expose gaps, over-engineering, and implicit assumptions before you commit to implementation. It's the difference between a plan that survives first contact with the code and one that doesn't. Also stress-tests `SKILL.md` files by auditing tool usage and generating `allowed-tools` recommendations.

## Components

| Component | Type | Invocation |
|-----------|------|-----------|
| `plan-interview` | Command | `/plan-interview:plan-interview [plan-file-path]` |
| `plan-status` | Command | `/plan-interview:plan-status [plan-file-path]` |
| `update-plan-status` | Command | `/plan-interview:update-plan-status [directory-path] [--force]` |
| `review-rename-plans` | Command | `/plan-interview:review-rename-plans [plan-file-or-directory]` |
| `plan-hygiene` | Command | `/plan-interview:plan-hygiene [directory-path]` |
| `deep-grill` | Command | `/plan-interview:deep-grill [plan-file-path]` |
| `plan-interview` | Skill | Auto-activates on stress-test/validate/interview requests |
| `plan-status` | Skill | Auto-activates on plan status check/update requests |
| `deep-grill` | Skill | Auto-activates on deep grill/walk decision branches requests |
| `documenting-plans` | Command | `/plan-interview:documenting-plans [plan-file-path]` |
| `documenting-plans` | Skill | Auto-activates on requests to document, generate docs from, or write reference docs for a plan |
| `plan-documenter` | Agent | Invoked via Agent tool: `plan-interview:plan-documenter` |
| `ExitPlanMode` | Hook | Auto-fires after exiting plan mode |

## Usage

### Command (explicit invocation)

```
/plan-interview:plan-interview                                   # auto-detects latest plan
/plan-interview:plan-interview ~/.claude/plans/my-feature.md     # specific plan file
/plan-interview:plan-interview docs/plans/refactor-plan.md       # project-relative path
```

### Review & Rename Plans

```
/plan-interview:review-rename-plans                          # scan project plans directory
/plan-interview:review-rename-plans docs/plans/my-plan.md    # review a single file
/plan-interview:review-rename-plans docs/plans/              # scan a specific directory
```

Reviews plan filenames against their content. Flags files whose names are random, generic, or misaligned with the plan's intent. Offers to rename using `git mv` to preserve history.

### Plan File Hygiene (batch rename)

```
/plan-interview:plan-hygiene                    # scan plansDirectory + additional dirs
/plan-interview:plan-hygiene docs/planning      # scan only docs/planning
/plan-interview:plan-hygiene openspec/plans     # scan only openspec/plans
```

Scans plan directories for files with random non-descriptive names (e.g., `precious-knitting-tulip.md`) and renames them to descriptive kebab-case names derived from their content headings. Presents a proposal table and asks for approval before renaming. Uses `git mv` to preserve history.

### Plan Status

Check whether a plan has been implemented and update its YAML frontmatter with
a lifecycle status and dates:

```
/plan-interview:plan-status                                    # auto-detects from IDE or settings
/plan-interview:plan-status docs/plans/my-feature.md          # specific plan file
```

Status values:

| Status | Meaning |
|--------|---------|
| `todo` | No implementation evidence found in codebase |
| `in-progress` | 1–79% of plan signals found in codebase |
| `completed` | 80%+ of plan signals found in codebase |

Type values (set for completed plans only):

| Type | Meaning |
|------|---------|
| `standard` | Default — a completed plan |
| `artifact` | Valuable reference documentation preserved long-term |

After analysis, the skill writes YAML frontmatter to the plan file (with user
confirmation):

```yaml
---
status: completed
type: standard
created: 2026-01-15
modified: 2026-03-26
---
```

Dates are sourced from git log. The `modified` field is omitted when it equals
`created`. Existing frontmatter fields are preserved.

### Batch Status

Process an entire directory of plan files at once — adds frontmatter to files
that don't have it, skips files already processed (unless `--force`):

```
/plan-interview:update-plan-status                          # uses plansDirectory setting or docs/plans/
/plan-interview:update-plan-status docs/plans/              # specific directory
/plan-interview:update-plan-status docs/plans/ --force      # re-analyze files with existing status
```

The command presents a summary table of all files and their computed
status/type before writing anything. Override options let you adjust
auto-classified artifact plans, documentation-focused plans, or zero-signal
files before confirming the write.

### Document Completed Plans

Convert a completed plan file into a developer-friendly prose reference document at `docs/<slug>.md`. The doc is synthesized from three sources: the plan body, live code inspection of every cited file path, and a scoped git history window.

```
/plan-interview:documenting-plans                                              # auto-detects from IDE or settings
/plan-interview:documenting-plans docs/plans/add-branch-agent-skill.md        # specific plan file
/plan-interview:documenting-plans ~/.claude/plans/my-feature.md               # absolute path
```

The skill automatically verifies the plan is `status: completed` before generating docs — if not, it runs `plan-status` first. The generated document includes:

- **What shipped** — capabilities list from Objective + Steps, rewritten in past tense
- **Files changed** — table of every cited file with Created/Modified/Relocated/Missing status
- **How it works** — prose walkthrough synthesized from plan Steps and actual code
- **How to use it** — activation triggers and examples (only when user-facing surface exists)
- **Commit history** — scoped `git log` window for the plan and its referenced files

Content inside `<!-- generated:start -->` / `<!-- generated:end -->` markers is regenerated on each run. Content outside the markers is preserved (suitable for hand-written notes or additions).

To describe your intent and auto-activate the skill:

```
Document this plan
Generate reference docs for this plan
Turn this completed plan into documentation
Write developer docs from this plan
```

### Batch Document All Plans (Agent)

The `plan-documenter` agent scans the plans directory for completed plans that
don't yet have corresponding docs in `docs/`, then runs the `documenting-plans`
skill for each one automatically.

Invoke via the Agent tool from another agent or automated workflow:

```json
{
  "subagent_type": "plan-interview:plan-documenter",
  "prompt": "Document all completed plans that are missing docs."
}
```

The agent resolves the plan directory from `.claude/settings.json`
(`plansDirectory` key), falling back to `docs/plans/`. It pre-filters to only
`status: completed` plans without an existing `docs/<slug>.md` file, then
processes each sequentially in alphabetical order. A summary table is produced
at the end.

If the turn limit is reached mid-batch, the agent reports partial progress.
Subsequent runs automatically skip already-documented plans.

#### Permission model

Plugin agents do not support `permissionMode` — the field is ignored per the
[official plugins reference](https://code.claude.com/docs/en/plugins-reference).
This affects how the agent behaves depending on how it is invoked:

| Invocation method | Behavior | Unattended? |
|---|---|---|
| **Interactive** (Agent tool from conversation) | Agent runs normally. Write/Edit tool calls surface permission prompts that the user approves as they appear. | No |
| **Remote trigger** (scheduled via claude.ai/code/scheduled) | The trigger clones the repo and executes a prompt directly — it does not go through the plugin agent system. It has its own permission model and prompts are not surfaced. | Yes |

The key distinction: scheduled automation works because remote triggers bypass
the plugin system entirely, not because of any agent-level permission setting.
When setting up automation, use a remote trigger with an inline prompt rather
than expecting the plugin agent to run unattended.

#### Running independently

Describe your intent in conversation to auto-activate:

```
Batch document all completed plans
Generate docs for all completed plans that are missing documentation
```

Or invoke explicitly via the Agent tool:

```json
{
  "subagent_type": "plan-interview:plan-documenter",
  "prompt": "Document all completed plans that are missing docs."
}
```

#### Weekly scheduled run

A remote trigger can run a documentation sweep automatically on a schedule
(e.g., every Sunday at 6:00 AM ET). The trigger clones the repo fresh and
executes a prompt directly — it does not invoke the plugin agent, so there are
no permission prompts to block execution. Manage schedules at
https://claude.ai/code/scheduled or run on-demand:

```
/schedule run   # select the "Weekly Plan Documentation Sweep" trigger
```

#### Using in other repos

The agent is repo-agnostic — it resolves the plans directory at runtime. To use
it in another repo:

1. Install the plugin:

```
/plugin marketplace add shawn-sandy/agentics
/plugin install plan-interview@agentics-kit
```

2. (Optional) If your plans aren't in `docs/plans/`, set a custom directory in
   `.claude/settings.json`:

```json
{
  "plansDirectory": "path/to/your/plans"
}
```

3. Run the agent on demand — describe your intent or invoke explicitly:

```
Batch document all completed plans
```

#### Scheduling for multiple repos

Each repo needs its own scheduled trigger because remote agents clone a single
repo per run. To add a weekly sweep to another repo:

1. Run `/schedule` and choose "Create"
2. Set the GitHub URL to the target repo
3. Use the same prompt:
   > Scan for completed plans that don't yet have corresponding documentation.
   > For each completed plan, invoke the documenting-plans skill to generate
   > the doc. Report a summary when done.
4. Set the schedule (e.g., `0 10 * * 0` for Sunday 6:00 AM ET)

The agent prompt is identical across repos — only the GitHub URL changes. For
2-5 repos, individual triggers are the simplest approach.

### Deep Grill

Walk through every decision branch in a plan with focused questions and codebase
exploration:

```
/plan-interview:deep-grill                                    # auto-detects latest plan
/plan-interview:deep-grill docs/plans/my-feature.md          # specific plan file
/plan-interview:deep-grill ~/.claude/plans/my-feature.md     # absolute path
```

The deep grill is a standalone session — it does not modify the plan file. It
reads the plan, builds a decision tree, and walks each branch one at a time.
Results are presented as a summary at the end.

### Skill (automatic activation)

Describe your intent and the skill activates:

```
Stress-test this plan
Stress-test my agentic plan
Interview my implementation plan
Find gaps and risks in this plan
Validate my approach before I start coding
```

To run a standalone deep grill, describe your intent:

```
Deep grill this plan
Deep grill my agentic plan
Walk through each decision in my plan
Examine every branch in my implementation plan
```

To check the status of a plan, describe your intent and the `plan-status` skill
activates:

```
Check the status of this plan
Check the status of my agentic plan
Has this plan been implemented?
Update the plan status
What's the lifecycle status of this plan?
```

In skill-review mode, target a `SKILL.md` file instead:

```
Review this SKILL.md for tool coverage
Audit the allowed-tools in my skill
Check what tools this skill uses
```

### Hook (automatic prompt after plan mode)

When Claude exits plan mode via the `ExitPlanMode` tool, the plugin automatically suggests running the plan-interview skill. This is a prompt only — the interview does not start unless you confirm.

No action required to enable this; it activates automatically when the plugin is installed.

### Interview rounds

The number of rounds scales with plan complexity:

| Plan scope | Rounds |
|------------|--------|
| Short/focused (1–2 files) | 1 round: Technical & Trade-offs |
| Medium (feature with UI + logic) | 2 rounds: + UI/UX & Accessibility |
| Complex/multi-area | 3 rounds: + Edge Cases & Best Practices |

Any plan with UI signals (React, Tailwind, `.tsx`, form/modal/dialog terminology) always includes Round 2.

After the interview (or independently), run the **Deep Grill** skill to walk every decision branch with focused questions, suggested answers, and codebase exploration via `Glob`/`Grep`/`Read`. Say _"deep grill this plan"_ or invoke `/plan-interview:deep-grill [path]` directly.

### After the interview

The skill compiles a **Plan Interview Summary** with:

- Plan naming issues (if the filename or heading is non-descriptive)
- Key decisions confirmed
- Open risks and concerns
- Recommended next steps
- Simplification opportunities (if any)
- Allowed Tools Recommendation (skill-review mode only — suggested `allowed-tools` line for the paired command file)

You can optionally save the summary back to the plan file.

## Rules

To automate plan-hygiene before commits, copy this rule into `.claude/rules/plan-hygiene.md` and adjust paths as needed:

```markdown
---
description: Run plan file hygiene before committing changes
paths:
  - "**/plans/**"
  - "**/planning/**"
---

# Pre-Commit Plan Hygiene

Before creating any git commit, check if there are plan files with random non-descriptive names (e.g., `precious-knitting-tulip.md`) in the planning directories.

If random-named plan files exist, run `/plan-hygiene` first and complete the rename workflow before proceeding with the commit.
```

## Installation

```
/plugin install plan-interview@agentics-kit
```

Or load directly for local testing:

```bash
claude --plugin-dir ./kit/plugins/plan-interview
```
