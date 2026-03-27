# plan-interview Plugin

Stress-tests implementation plans with structured multi-round interviews before coding begins. Surfaces technical trade-offs, UX/accessibility risks, edge cases, and out-of-scope concerns you might not have considered.

## Purpose

Writing a plan is not the same as stress-testing one. This plugin conducts a structured interview — asking targeted questions derived from the plan's own content — to expose gaps, over-engineering, and implicit assumptions before you commit to implementation. It's the difference between a plan that survives first contact with the code and one that doesn't. Also stress-tests `SKILL.md` files by auditing tool usage and generating `allowed-tools` recommendations.

## Components

| Component | Type | Invocation |
|-----------|------|-----------|
| `plan-interview` | Command | `/plan-interview:plan-interview [plan-file-path]` |
| `review-rename-plans` | Command | `/plan-interview:review-rename-plans [plan-file-or-directory]` |
| `plan-hygiene` | Command | `/plan-interview:plan-hygiene [directory-path]` |
| `plan-interview` | Skill | Auto-activates on stress-test/validate/interview requests |
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

### Skill (automatic activation)

Describe your intent and the skill activates:

```
Stress-test this plan
Interview my implementation plan
Find gaps and risks in this plan
Validate my approach before I start coding
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

During any interview, you can request a **Deep Grill** session (Step 4.5). Claude walks through every decision branch with relentless follow-up questions, suggests answers, and explores the codebase with `Glob`/`Grep`/`Read`. Findings are collected in the final summary.

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
