# plan-interview Plugin

Stress-tests implementation plans with structured multi-round interviews before coding begins. Surfaces technical trade-offs, UX/accessibility risks, edge cases, and out-of-scope concerns you might not have considered.

## Purpose

Writing a plan is not the same as stress-testing one. This plugin conducts a structured interview — asking targeted questions derived from the plan's own content — to expose gaps, over-engineering, and implicit assumptions before you commit to implementation. It's the difference between a plan that survives first contact with the code and one that doesn't.

## Components

| Component | Type | Invocation |
|-----------|------|-----------|
| `plan-interview` | Command | `/plan-interview:plan-interview [plan-file-path]` |
| `review-rename-plans` | Command | `/plan-interview:review-rename-plans [plans-directory]` |
| `plan-interview` | Skill | Auto-activates on stress-test/validate/interview requests |

## Usage

### Command (explicit invocation)

```
/plan-interview:plan-interview                                   # auto-detects latest plan
/plan-interview:plan-interview ~/.claude/plans/my-feature.md     # specific plan file
/plan-interview:plan-interview docs/plans/refactor-plan.md       # project-relative path
```

### Review & Rename Plans (batch filename audit)

```
/plan-interview:review-rename-plans                          # auto-detect plans directory
/plan-interview:review-rename-plans docs/plans               # specific directory
/plan-interview:review-rename-plans ~/.claude/plans           # global plans directory
```

Scans all plan files in a directory, evaluates whether each filename matches the plan's intent, and offers to rename mismatched files interactively. Useful for cleaning up auto-generated or randomly-named plan files.

### Skill (automatic activation)

Describe your intent and the skill activates:

```
Stress-test this plan
Interview my implementation plan
Find gaps and risks in this plan
Validate my approach before I start coding
```

### Interview rounds

The number of rounds scales with plan complexity:

| Plan scope | Rounds |
|------------|--------|
| Short/focused (1–2 files) | 1 round: Technical & Trade-offs |
| Medium (feature with UI + logic) | 2 rounds: + UI/UX & Accessibility |
| Complex/multi-area | 3 rounds: + Edge Cases & Best Practices |

Any plan with UI signals (React, Tailwind, `.tsx`, form/modal/dialog terminology) always includes Round 2.

### After the interview

The skill compiles a **Plan Interview Summary** with:
- Plan naming issues (if the filename or heading is non-descriptive)
- Key decisions confirmed
- Open risks and concerns
- Recommended next steps
- Simplification opportunities (if any)

You can optionally save the summary back to the plan file.

## Installation

```
/plugin install plan-interview@agentics-kit
```

Or load directly for local testing:

```bash
claude --plugin-dir ./plugins/plan-interview
```
