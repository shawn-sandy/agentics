# Add `allowed-tools` Recommendation Capability to plan-interview

> Extends plan-interview to accept SKILL.md files as review targets, detect tool references in skill bodies, and recommend `allowed-tools` frontmatter additions.

<!-- generated:start -->

**Status:** Shipped 2026-03-26   **Plan:** [add-allowed-tools-recommendation-to-plan-interview.md](plans/add-allowed-tools-recommendation-to-plan-interview.md)   **Type:** feature

## What shipped

- SKILL.md files are now accepted as valid review targets in both the skill and command — skill detection runs automatically after file resolution in Step 1 based on filename or frontmatter shape.
- Step 2.5 (Skill Tool Analysis) was added in `skill-review` mode: scans the skill instruction body for known Claude tool names, classifies each as Declared / Missing / Undeclared, and outputs a suggested `allowed-tools` line.
- Step 6 in skill-review mode now offers to apply the `allowed-tools` recommendation directly to the reviewed skill file via `Edit`.
- `allowed-tools` frontmatter added to `kit/plugins/plan-interview/skills/plan-interview/SKILL.md` itself (was missing, despite the skill using `Grep` and `Bash`).
- `Grep` and `Bash` added to `kit/plugins/plan-interview/commands/plan-interview.md` `allowed-tools` (already used but undeclared).

> See [CHANGELOG v1.7.0](../kit/plugins/plan-interview/CHANGELOG.md#170---2026-03-26) for the authoritative feature list.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-interview/skills/plan-interview/SKILL.md` | Skill instructions — plan-interview | Modified |
| `kit/plugins/plan-interview/commands/plan-interview.md` | Command wrapper for plan-interview | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump 1.6.0 → 1.7.0 | Modified |
| `kit/plugins/plan-interview/CHANGELOG.md` | Plugin changelog | Modified |

## How it works

After file resolution in Step 1, the skill checks whether the resolved file should be treated as a skill rather than a plan. A file is classified as a skill when its filename is `SKILL.md`, or when its YAML frontmatter contains both `name:` and `description:` fields but no plan-style headings like `## Implementation` or `## Steps`. When detected, an internal `skill-review` mode is set and Step 2's plan-name validation is skipped.

Step 2.5 runs only in `skill-review` mode. It parses the existing `allowed-tools` frontmatter value (treating absence as empty), then scans the skill body for any of the 14 known Claude tool names — including filtered forms like `Bash(git *)`. Each detected tool is classified: **Declared** (already listed), **Missing** (found in instructions but absent from frontmatter), or **Undeclared** (in frontmatter but not detected in body, flagged for review). A sorted suggested `allowed-tools` line covering all detected tools is output alongside the analysis table.

The Step 5 summary template gained an **Allowed Tools Recommendation** section that re-presents the Step 2.5 table, but only in `skill-review` mode — plan reviews are unaffected.

Step 6 was updated so that when operating in `skill-review` mode and the user confirms saving, an additional prompt offers to apply the suggested `allowed-tools` line directly to the skill file's YAML frontmatter using `Edit`. This closes the feedback loop between audit and fix in a single workflow.

The `allowed-tools` line was also added to the plan-interview `SKILL.md` and command file themselves. The skill was already using `Grep` (in deep grill) and `Bash` (for `mv` rename) but had not declared them, which would cause permission prompts. The fix aligns the declaration with actual usage: `Read, Glob, Grep, Bash, AskUserQuestion, Write, Edit, TodoWrite`.

## How to use it

**Skill activation** — triggers automatically when you ask to "review this SKILL.md", "check allowed-tools", or "validate this skill file". Can also be invoked explicitly:

```
/plan-interview:plan-interview kit/plugins/my-plugin/skills/my-skill/SKILL.md
```

**Step 2.5 output example:**

```
### Skill Tool Analysis

| Status    | Tool            | Detected In                           |
|-----------|-----------------|---------------------------------------|
| Declared  | Read            | Step 1 — resolving skill file         |
| Missing   | Grep            | Step 4.5 — deep grill codebase search |
| Undeclared| Write           | Listed in allowed-tools, not detected |

Suggested frontmatter:
allowed-tools: AskUserQuestion, Bash, Edit, Glob, Grep, Read, TodoWrite
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |

<!-- generated:end -->

## References

- Plan: [add-allowed-tools-recommendation-to-plan-interview.md](plans/add-allowed-tools-recommendation-to-plan-interview.md)
- Changelog: [CHANGELOG v1.7.0](../kit/plugins/plan-interview/CHANGELOG.md#170---2026-03-26)
