# Plan: Update plan-interview README with plan-hygiene info

## Context

The `plan-hygiene` command exists at `plugins/plan-interview/commands/plan-hygiene.md` but the plugin README doesn't document it. The components table row was already added (line 15). Two things remain: a usage subsection and a Rules section with a copyable pre-commit rule.

## Changes

**File:** `plugins/plan-interview/README.md`

### 1. Add "Plan File Hygiene" usage subsection (after line 36, before "### Skill")

```markdown
### Plan File Hygiene (batch rename)

```
/plan-interview:plan-hygiene                    # scan plansDirectory + additional dirs
/plan-interview:plan-hygiene docs/planning      # scan only docs/planning
/plan-interview:plan-hygiene openspec/plans     # scan only openspec/plans
```

Scans plan directories for files with random non-descriptive names (e.g., `precious-knitting-tulip.md`) and renames them to descriptive kebab-case names derived from their content headings. Presents a proposal table and asks for approval before renaming. Uses `git mv` to preserve history.
```

### 2. Add "Rules" section (before "## Installation", after line 70)

Insert a `## Rules` section with a copyable rule for `.claude/rules/plan-hygiene.md`:

````markdown
## Rules

To automate plan-hygiene before commits, copy this rule into `.claude/rules/plan-hygiene.md`:

```markdown
---
description: Run plan file hygiene before committing changes
globs: ["docs/planning/**", "openspec/plans/**", "project-docs/06-implementation-plans/**"]
---

# Pre-Commit Plan Hygiene

Before creating any git commit, check if there are plan files with random non-descriptive names (e.g., `precious-knitting-tulip.md`) in the planning directories.

If random-named plan files exist, run `/plan-hygiene` first and complete the rename workflow before proceeding with the commit.
```
````

## Verification

1. Components table has 4 rows (3 commands + 1 skill) — already done
2. "Plan File Hygiene" subsection appears between "Review & Rename Plans" and "Skill"
3. "Rules" section appears between "After the interview" and "Installation"
4. Rule code block is properly fenced and copyable
