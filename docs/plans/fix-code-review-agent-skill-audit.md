---
status: draft
scope: plugins/code-review/skills/code-review-agent/SKILL.md
---

# Fix code-review-agent SKILL.md Audit Findings

## Context

Skill audit scored **8/10 (Good)**. Two issues prevent a perfect score: missing canonical "Use when..." trigger phrase (costs 1 pt each on Frontmatter Validity and Discoverability) and broken markdown code block fencing in the Example Review section.

## Fixes

### 1. Add "Use when..." trigger phrase to description

**File:** `plugins/code-review/skills/code-review-agent/SKILL.md` lines 3-14

Reorder the description: capability summary first, then "Use when..." trigger, then scope exclusion. Preserves all original keywords and informal triggers.

Proposed description (743 chars, under 1024 limit):

```yaml
description: >
  Performs interactive, multi-dimensional code review covering six areas:
  code quality, potential bugs, security vulnerabilities, best practices,
  code complexity rating (Low/Medium/High/Very High), and breaking changes
  with regression risk assessment. Automatically resolves which files to
  review from git status, branch diffs, or explicit paths. Produces a
  structured report with severity-ranked findings. Use when the user asks
  to review code, check files for problems, look over a PR or branch diff,
  assess code quality or complexity, find bugs or security issues, detect
  breaking changes, or says "take a look at this" or "anything wrong with
  this code." Does not cover system architecture reviews, testing strategy,
  or accessibility audits.
```

### 2. Fix broken code block fencing in Example Review

**File:** `plugins/code-review/skills/code-review-agent/SKILL.md` lines 302-399

Three edits:

1. **Remove line 332** (premature ```````` closer) — keeps 4-backtick block open
2. **Change line 381** from ```` ``` ```` to ```````` — becomes proper 4-backtick closer
3. **Remove line 399** (```` ``` ````) — frees Tips/Scope from accidental code block

Result: full Example Review (Summary through Positive Observations) inside one fenced block; Tips and Scope render as normal body sections.

### 3. Bump version (PATCH)

**File:** `.claude-plugin/marketplace.json`

Bump `code-review` plugin version (patch) for metadata/formatting fix.

## Verification

1. Confirm description < 1024 chars and contains "Use when..."
2. Render SKILL.md in markdown previewer — Example Review fully fenced, Tips/Scope are normal headings
3. Re-run `/skill-reviewer:reviewing-skills` to verify 10/10

## Next Steps (out of scope)

- Consider splitting Review Checklist into `references/review-checklist.md`
- Consider splitting Example Review into `references/example-review.md`
- Add explicit multi-file iteration pattern for large reviews
