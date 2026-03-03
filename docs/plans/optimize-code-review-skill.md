# Plan: Optimize code-review SKILL.md

## Context

Audit of `plugins/code-review/skills/code-review/SKILL.md` scored **8/10 (Good)**.
Two warnings were identified (missing TOC, no scope definition in description) and
a new requirement added: the skill must adaptively resolve which files to review
before running the checklist — supporting explicit paths, git status, and branch diffs.

---

## Files to Modify

| File | Change |
|------|--------|
| `plugins/code-review/skills/code-review/SKILL.md` | Core changes (TOC, description, Step 0, freedom level) |
| `plugins/code-review/.claude-plugin/plugin.json` | Version bump: `1.0.0` → `1.1.0` |
| `.claude-plugin/marketplace.json` | Version sync: `1.0.0` → `1.1.0` |
| `plugins/code-review/CHANGELOG.md` | Add entry (create file if absent) |

---

## Changes

### 1. Fix description (frontmatter)

- Change "Review code" to "Reviews code" (third-person verb)
- Add scope exclusion sentence

```yaml
description: Reviews code for best practices, bugs, and security vulnerabilities. Use when the user asks to review code, check a file for problems, review changed files, or analyze code quality. Does not cover architecture reviews or testing strategy.
```

### 2. Add Step 0 — File Resolution (new section, Adaptive pattern)

Insert before `## Review Checklist`. This step resolves target files before any
review begins.

```markdown
## Step 0: Resolve Target Files

Before reviewing, identify which files to check using this priority order:

1. **Explicit path in message** — If the user named a file or directory, use it directly. Skip to the Review Checklist.

2. **Local changes (git status)** — If no file was specified, run:
   `git status --short`
   - If this fails (not a git repo), skip to step 4.
   - If files are listed, show the list and ask: "I found these changed files — which would you like me to review?" Review confirmed files. Skip binaries, lock files (*.lock, package-lock.json, yarn.lock), and generated files; note any skipped.
   - If no files are listed, continue to step 3.

3. **Branch diff** — Run each in order until files are returned:
   - `git diff main...HEAD --name-only`
   - `git diff master...HEAD --name-only`
   - `git diff HEAD~1 --name-only`
   If files are returned, show the list and confirm before reviewing. Skip non-reviewable files as above.
   If all return empty or fail (e.g., detached HEAD), continue to step 4.

4. **Fallback** — Ask: "Which file or files would you like me to review?"

Once target files are confirmed, proceed to the Review Checklist for each file.
```

### 3. Add freedom level (body — opening paragraph)

Append to the opening sentence (line 6):

> "Adapt the checklist depth to the code's complexity and context."

### 4. Add table of contents (body — after opening paragraph)

```markdown
## Table of Contents

- [Step 0: Resolve Target Files](#step-0-resolve-target-files)
- [Review Checklist](#review-checklist)
  - [1. Code Quality](#1-code-quality)
  - [2. Potential Bugs](#2-potential-bugs)
  - [3. Security Vulnerabilities](#3-security-vulnerabilities)
  - [4. Best Practices](#4-best-practices)
- [Review Format](#review-format)
- [Example Review](#example-review)
- [Tips for Effective Reviews](#tips-for-effective-reviews)
- [Scope](#scope)
```

### 5. Fix second-person in body (line 106)

Change: `Structure your review as follows:`
To: `Structure the review as follows:`

---

## Version Bump

- Current: `1.0.0`
- New: `1.1.0` (MINOR — new adaptive file resolution behavior added)
- Edit `plugins/code-review/.claude-plugin/plugin.json` → `"version": "1.1.0"`
- Edit `.claude-plugin/marketplace.json` → matching entry `"version": "1.1.0"`
- Add to `plugins/code-review/CHANGELOG.md` (create if absent):

```markdown
## [1.1.0] - YYYY-MM-DD

### Added
- Adaptive file resolution (Step 0): supports explicit path, git status, branch diff, and fallback prompt
- Table of contents

### Fixed
- Description rewritten to third person with scope exclusion
- Second-person "your review" corrected to "the review"
- Freedom level statement added to opening paragraph
```

---

## Verification

1. Run `skill-reviewer:reviewing-skills` on the updated SKILL.md — expect 9–10/Excellent
2. Verify version matches in both `plugin.json` and `marketplace.json`:
   `grep -r '"version"' plugins/code-review/.claude-plugin/ .claude-plugin/marketplace.json`
3. Confirm TOC anchors resolve (all headings present and match links)
4. Manually test skill activation with: "review src/index.ts" (explicit path)
5. Manually test skill activation with no file mentioned (git status path)

---

## Commit

```
feat(plugins/code-review): add adaptive file resolution and optimize SKILL.md — bump to v1.1.0
```

## Post-implementation

- Rename this plan file: `wobbly-pondering-dream.md` → `optimize-code-review-skill.md`

---

## Interview Summary

**Interviewed:** 2026-03-03
**Score before:** 8/10 (Good) | **Expected after:** 9–10 (Excellent)

### Key Decisions

- Branch diff uses 3-fallback chain: `main` → `master` → `HEAD~1`
- Multi-file results: list files and confirm before reviewing all
- Non-reviewable files (lock, binary, generated): skip and note as skipped
- Non-git-repo guard: fallthrough to ask-user fallback

### Risks Addressed

- Empty diff case: explicit "if no files returned, continue to next step" logic
- Detached HEAD: handled by fallthrough chain
- Non-git-repo: handled by step 2 failure guard
