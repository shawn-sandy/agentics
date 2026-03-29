# plan-interview Plugin

Stress-tests implementation plans with structured multi-round interviews before coding begins. Surfaces technical trade-offs, UX/accessibility risks, edge cases, and out-of-scope concerns you might not have considered.

## Purpose

Writing a plan is not the same as stress-testing one. This plugin conducts a structured interview — asking targeted questions derived from the plan's own content — to expose gaps, over-engineering, and implicit assumptions before you commit to implementation. It's the difference between a plan that survives first contact with the code and one that doesn't. Also stress-tests `SKILL.md` files by auditing tool usage and generating `allowed-tools` recommendations.

## Components

| Component | Type | Invocation |
|-----------|------|-----------|
| `plan-interview` | Command | `/plan-interview:plan-interview [plan-file-path]` |
| `plan-status` | Command | `/plan-interview:plan-status [plan-file-path]` |
| `status-sweep` | Command | `/plan-interview:status-sweep [directory-path] [--force]` |
| `review-rename-plans` | Command | `/plan-interview:review-rename-plans [plan-file-or-directory]` |
| `plan-hygiene` | Command | `/plan-interview:plan-hygiene [directory-path]` |
| `deep-grill` | Command | `/plan-interview:deep-grill [plan-file-path]` |
| `plan-interview` | Skill | Auto-activates on stress-test/validate/interview requests |
| `plan-status` | Skill | Auto-activates on plan status check/update requests |
| `deep-grill` | Skill | Auto-activates on deep grill/walk decision branches requests |
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
/plan-interview:status-sweep                          # uses plansDirectory setting or docs/plans/
/plan-interview:status-sweep docs/plans/              # specific directory
/plan-interview:status-sweep docs/plans/ --force      # re-analyze files with existing status
```

The command presents a summary table of all files and their computed
status/type before writing anything. Override options let you adjust
auto-classified artifact plans, documentation-focused plans, or zero-signal
files before confirming the write.

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
Interview my implementation plan
Find gaps and risks in this plan
Validate my approach before I start coding
```

To run a standalone deep grill, describe your intent:

```
Deep grill this plan
Walk through each decision in my plan
Examine every branch in my implementation plan
```

To check the status of a plan, describe your intent and the `plan-status` skill
activates:

```
Check the status of this plan
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
claude --plugin-dir ./plugins/plan-interview
```
