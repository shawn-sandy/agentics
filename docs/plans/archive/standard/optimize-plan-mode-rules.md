---
description: Optimize ~/.claude/rules/plan-mode.md for clarity and reduced redundancy
status: todo
---

# Optimize `plan-mode.md` Rule File

## Context

The rule file at [~/.claude/rules/plan-mode.md](/Users/shawnsandy/.claude/rules/plan-mode.md) governs how Claude builds plan files during plan mode. Because rule files load into every conversation's context, bloat and redundancy directly cost tokens on every turn. The current file (34 lines) has three issues worth fixing:

1. **Redundancy** — three separate bullets ask for "concise" writing (lines 12, 13, 16-17).
2. **Duplicated `Next Steps` guidance** — defined as a bullet in the main list (line 11) and again in a dedicated section (lines 28-33).
3. **Scattered workflow** — the operational sequence (ask → create → rename → commit) is interleaved with style and structural rules, so no part of the file answers "what do I do and when?" at a glance.

Goal: A shorter, better-grouped rule file that preserves every existing requirement.

## Objective

Rewrite `~/.claude/rules/plan-mode.md` into four clearly labeled sections — **Workflow**, **Required Structure**, **Writing Style**, **Scope Discipline** — eliminating duplication without dropping any existing rule.

## Critical Files

- [~/.claude/rules/plan-mode.md](/Users/shawnsandy/.claude/rules/plan-mode.md) — the only file modified.

## Requirements Preserved (checklist)

Every rule in the current file must survive the rewrite:

- [ ] Ask user for confirmation before writing a plan file
- [ ] Plan sections: Objective / Steps / Next Steps
- [ ] Each step = single, concise action
- [ ] Brief, developer-friendly explanations per recommendation
- [ ] Bullet points / numbered lists only (no long paragraphs)
- [ ] Scope discipline — extras go in Next Steps
- [ ] Unresolved questions section at plan's end
- [ ] Rename plan file to reflect its purpose
- [ ] Commit plan files to version control
- [ ] `Next Steps` items: brief, one line, marked out-of-scope

## Steps

1. **Replace the file body** (keep frontmatter `description: Rules for planMode behavior and structure`) with the proposed content below.
   - *Why:* A full replacement is cleaner than 6+ targeted edits across overlapping bullets.

2. **Verify no rule was dropped** by cross-checking the Requirements Preserved checklist above against the new content.
   - *Why:* A rewrite that loses a rule is a regression, even if the file reads better.

3. **Commit** the change with a conventional message, e.g. `docs(rules): consolidate plan-mode.md for clarity`.
   - *Why:* Rule files live under version control so changes are reviewable and revertable.

## Proposed Final Content

```markdown
---
description: Plan mode rules — workflow, required structure, writing style, and scope discipline
---

# Plan Mode Instructions

## Workflow

1. **Ask first** — Before writing any plan file, confirm with the user that they want one.
2. **Create** — Place plans in `docs/plans/` with a descriptive filename (e.g. `optimize-build-process.md`).
3. **Rename** — Update the filename if the plan's purpose shifts during drafting.
4. **Commit** — Always commit plan files to version control alongside the related change.

## Required Structure

Every plan must include:

- **Objective** — One-sentence statement of the goal.
- **Steps** — Numbered list; each step is a single, testable action with a brief developer-friendly explanation of *why*.
- **Next Steps** — Optional follow-ups, one line each, clearly marked out-of-scope.
- **Unresolved Questions** — Open questions needing user input (omit the section entirely if none).

## Writing Style

- Bullet points and numbered lists only — no long paragraphs.
- Keep every line concise; if a step needs more than a sentence, it's probably two steps.

## Scope Discipline

- Plan only what was explicitly requested.
- Surface unrequested ideas in **Next Steps**, never in the main Steps.
```

## Why This Layout

- **Workflow first** answers "what do I do, in what order?" — the question a fresh session asks.
- **Required Structure** folds the old standalone `Next Steps` section back into one place.
- **Writing Style** replaces three overlapping bullets with two direct ones.
- **Scope Discipline** stays its own section because it's a behavioral guardrail, not a formatting rule.

## Verification

1. Open [~/.claude/rules/plan-mode.md](/Users/shawnsandy/.claude/rules/plan-mode.md) and confirm the file matches the proposed content byte-for-byte in structure (frontmatter intact, four H2 sections present).
2. Walk the Requirements Preserved checklist — every item must map to a line in the new file.
3. Start a new Claude Code session, enter plan mode on any small task, and confirm the generated plan still includes Objective / Steps / Next Steps and asks for confirmation before writing.

## Resolved Decisions

1. **Unresolved Questions section stays optional** — included only when real questions exist, to avoid empty placeholder sections.
2. **Frontmatter `description` updated** to `"Plan mode rules — workflow, required structure, writing style, and scope discipline"` so it doubles as a quick outline of the file.

## Next Steps (out of scope)

- Audit the other files in `~/.claude/rules/` for similar redundancy (not part of this task).
- Consider adding a `path:` scope to the frontmatter so the rule only loads when a plan file is actually being written (would save tokens on non-planning turns).
