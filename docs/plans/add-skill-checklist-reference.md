---
status: in-progress
created: 2026-04-01
---

# Plan: Add Best Practices Checklist Reference to plan-interview Skill

## Context

The plan-interview skill reviews skills (in `skill-review` mode) but doesn't reference the official Anthropic checklist for effective skills. Adding this checklist gives the skill a concrete evaluation rubric to use during Step 2.5 (Skill tool analysis) and Step 5 (review summary).

Source: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#checklist-for-effective-skills

## Changes

### 1. Add reference appendix to SKILL.md

**File:** `plugins/plan-interview/skills/plan-interview/SKILL.md`

Append a `## Reference: Skill Authoring Checklist` section at the end of the file (after Step 6) containing the three-category checklist from the best practices guide:

- **Core quality** (10 items) -- description, body length, progressive disclosure, terminology, examples, etc.
- **Code and scripts** (8 items) -- error handling, constants, packages, paths, validation, feedback loops
- **Testing** (4 items) -- evaluations, model testing, real usage, team feedback

The checklist will be formatted as markdown checkbox lists, attributed to the source URL.

### 2. Current file size check

- Current: 435 lines
- Added: ~35 lines (heading + checklist + source link)
- Total: ~470 lines -- under the 500-line recommended limit

No separate reference file needed.

## Verification

1. Confirm the file is under 500 lines after the edit
2. Load the plugin locally and trigger skill-review mode on a test skill to verify the checklist renders in context

## Next Steps

- Consider referencing specific checklist items in Step 2.5 and Step 5 instructions to make the review more structured (out of scope for this change)
- Consider adding the full best practices guide as a bundled reference file for deeper skill reviews (out of scope)
