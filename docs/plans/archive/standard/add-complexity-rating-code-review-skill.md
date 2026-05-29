---
status: completed
type: standard
created: 2026-03-03
---

# Plan: Add Code Complexity Rating to code-review Skill

## Context

The `code-review` skill (v1.1.0) reviews code across four dimensions (quality, bugs, security, best
practices) but does not assess or report code complexity. Adding a complexity rating gives users
actionable insight into maintainability risk and cognitive load before they read the detailed issues.

---

## Changes Required

### 1. `plugins/code-review/skills/code-review/SKILL.md`

**a. Update frontmatter description**
Append complexity to the description field so the skill activation hint reflects the new capability:
```
description: Reviews code for best practices, bugs, security vulnerabilities, and complexity. Use when the user asks to review code, check a file for problems, review changed files, analyze code quality, or assess code complexity. Does not cover architecture reviews or testing strategy.
```

**b. Add Table of Contents entry**
Insert after `[4. Best Practices]`:
```
  - [5. Code Complexity](#5-code-complexity)
```

**c. Add Review Checklist section — "5. Code Complexity"**
Insert after `### 4. Best Practices` (before `## Review Format`):

```markdown
### 5. Code Complexity

Assess the overall complexity and rate it: **Low / Medium / High / Very High**

**Structural Complexity:**
- Nesting depth (>3 levels of conditionals/loops is a signal)
- Cyclomatic complexity (number of branching paths per function)
- Function/method length (>50 lines raises cognitive load)
- Number of responsibilities per module or class

**Coupling & Cohesion:**
- Number of imports relative to the file's purpose and language conventions
- How tightly modules depend on each other
- Whether data flows are easy to trace end-to-end

**Cognitive Load:**
- Is the logic easy to follow without deep context?
- Are there chained operations that are hard to debug?
- Are there global or shared mutable states?

**Rating Guide:**
| Rating | Signals |
|--------|---------|
| Low | Flat structure, few branches, clear data flow, imports typical for the language/framework |
| Medium | Some nesting or branching, moderate length, manageable coupling |
| High | Deep nesting, many branches, long functions, tight coupling |
| Very High | Multiple complexity signals combined; refactoring strongly advised |

**Notes:**
- When reviewing multiple files, rate each file individually. Include an aggregate rating only when
  reviewing more than 3 files.
- For files under ~30 lines with a single responsibility, note `Low (trivially simple)` and omit
  the detailed breakdown.
```

**d. Update Review Format**
Add a `Complexity Rating` block between `### Summary` and `### Critical Issues`:

```markdown
### Complexity Rating
**[Low / Medium / High / Very High]** — One-sentence rationale (e.g., "Deep nesting in 3 core
functions and tightly coupled imports drive the rating.").
```

**e. Update the Scope section**
Add a bullet clarifying that complexity assessment is code-level, not architectural:
```
- Complexity rating covers code-level coupling and nesting depth, not system architecture
```

**f. Update Example Review**
Add a `Complexity Rating` block between the Summary and Critical Issues in the example.

---

### 2. `plugins/code-review/.claude-plugin/plugin.json`

- Bump version: `"1.1.0"` → `"1.2.0"`
- Add `"complexity"` to the `keywords` array

---

### 3. `.claude-plugin/marketplace.json`

Bump `code-review` entry version: `"1.1.0"` → `"1.2.0"`

---

### 4. `plugins/code-review/CHANGELOG.md`

Add entry:
```markdown
## [1.2.0] - 2026-03-03

### Added
- Code complexity rating (Low/Medium/High/Very High) to Review Checklist (#5)
- Complexity Rating section in Review Format output (after Summary)
- Rating guide table with signals for each level
- Multi-file guidance: per-file rating, aggregate only when reviewing 3+ files
- Small-file handling: trivially simple files noted as Low without full breakdown
- Scope clarification: complexity covers code-level coupling, not architecture
- Updated frontmatter description to include complexity
- Updated example review to demonstrate complexity output
- Added "complexity" keyword to plugin.json
```

---

### 5. `plugins/code-review/README.md`

Update the review output section list to add `Complexity Rating` between `Summary` and
`Critical Issues`:
```
1. Summary
2. Complexity Rating
3. Critical Issues
4. Improvements
5. Positive Observations
```

---

## Verification

1. Load the plugin locally:
   ```
   claude --plugin-dir ~/devbox/agentics/plugins/code-review
   ```
2. Ask: `"Review this file for me"` or `"Review the changed files"` — confirm the skill activates.
3. Check that the review output includes a **Complexity Rating** section with a rating and rationale.
4. Test multi-file review — confirm each file gets its own rating.
5. Test a trivially small file — confirm it shows `Low (trivially simple)` without the full breakdown.
6. Confirm both `plugin.json` and `marketplace.json` show `1.2.0`.

---

## Interview Summary

### Key Decisions Confirmed
- Complexity assessment is qualitative (Claude reads the code; no tooling required)
- Rating scale: Low / Medium / High / Very High with a one-sentence rationale
- Complexity Rating section appears after Summary, before Critical Issues
- Version bump: 1.1.0 → 1.2.0 (MINOR — new feature)

### Plan Naming

| Element | Current | Issue | Suggested |
|---------|---------|-------|-----------|
| Filename | `tingly-wobbling-gizmo.md` | Random — unrelated to content | `add-complexity-rating-code-review-skill.md` |
| H1 Heading | `# Plan: Add Code Complexity Rating to code-review Skill` | Descriptive and accurate | _(no change)_ |

### Open Risks Addressed

| Risk | Resolution in Plan |
|------|--------------------|
| Multi-file ambiguity | Per-file rating; aggregate only for 3+ files |
| Hard `<5 dependency` threshold | Replaced with language-relative language |
| Small/trivial files | `Low (trivially simple)` note, no breakdown |
| README out of sync | Added as Change #5 |
| Frontmatter missing complexity | Added as Change #1a |
| Keywords gap | `"complexity"` added to `plugin.json` |
| Scope overlap with architecture | Scope clarification bullet added |

### Simplification Opportunities
None — approach is appropriately minimal (markdown edits only, no new abstractions).
