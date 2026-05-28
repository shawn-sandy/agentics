---
name: reviewing-skills
description: "Scores SKILL.md files across 5 quality dimensions. Audits against Anthropic's authoring best practices and optionally generates a fix. Use when the user asks to review, audit, or score a skill."
allowed-tools: AskUserQuestion, Bash, Read, Write
---

## Overview

Performs a structured, scored audit of SKILL.md files against Anthropic's official Claude Code skill authoring best practices. Produces a scored report across 5 quality dimensions and optionally generates a corrected version.

Follow these steps exactly.

## When not to use

Does not review CLAUDE.md, commands, hooks, or general markdown.

## Table of Contents

- [Step 1: Resolve Target SKILL.md](#step-1-resolve-target-skillmd)
- [Step 2: Read and Measure](#step-2-read-and-measure)
- [Step 2b: Determine Guidelines Source](#step-2b-determine-guidelines-source)
- [Step 2c: Regression Risk Check (optional)](#step-2c-regression-risk-check-optional)
- [Steps 3–6: Audit, Score, Report, and Optionally Fix](#steps-36-audit-score-report-and-optionally-fix)
- [Quick Reference Checklist](#quick-reference-checklist)

---

## Step 1: Resolve Target SKILL.md

Determine which SKILL.md file to audit:

1. **Explicit path in message** — If the user provided a file path, use it directly.
2. **Conversation context** — If a skill has been recently discussed or created, use that one.
3. **Ask if still unclear** — "Which SKILL.md would you like me to review? Please provide the path."

Do NOT use `$ARGUMENTS` or `$PWD` — these variables are only available in commands, not skills.

---

## Step 2: Read and Measure

Read the target file and record:

| Metric | Value |
|--------|-------|
| Total lines | Count all lines |
| Word count | Count words in body (after closing `---`) |
| Frontmatter fields present | name, description, and any extras |
| Body lines | Lines after closing `---` |
| Reference files detected | Any `references/` paths mentioned or present in skill folder |
| Folder structure | Check for `scripts/`, `references/`, `assets/` subdirectories |
| Design pattern | Identify: Sequential, Orchestrator, Iterative, Adaptive, or none |

Note the presence or absence of:
- YAML frontmatter delimiters (`---`)
- `name:` field
- `description:` field
- "Use when..." trigger phrase in description
- Table of contents (for files ≥100 lines)
- SKILL.md filename casing (must be exactly `SKILL.md`)
- Kebab-case folder naming

---

## Step 2b: Determine Guidelines Source

**Default:** Use `references/best-practices.md` (static, always available).

**Fetch live from platform docs when user says:**
- "use latest", "check official docs", "fetch from platform", "use current guidelines", "pull from the website"

Live fetch URL:
```
https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
```

If live fetch fails: fall back to `references/best-practices.md` silently and note the failure in the audit output under a "Guidelines Source" line.

---

## Step 2c: Regression Risk Check (optional)

Compare the current SKILL.md against its last committed version to detect breaking changes and regressions.

**Skip entirely if any of the following are true:**
- Not inside a git repository (`git rev-parse --git-dir` returns non-zero)
- File has never been committed (`git log --oneline -- <path>` returns no output)
- User says "skip regression check", "no comparison", or "first review"

**If not skipped, run in order:**

1. Resolve the git-relative path:
   ```
   git ls-files --full-name <path-to-SKILL.md>
   ```
2. Retrieve the last committed version:
   ```
   git show HEAD:<git-relative-path>
   ```
   If this fails (file renamed, untracked, or path error): skip and note "No previous version found — file may have been renamed" in report. Do NOT attempt `git log --follow`; surface the limitation and move on.

**What to compare:** See `references/audit-steps.md` — Regression Risk section.

**Output:** A **Regression Risk** section in the audit report, appended after the Scores table and before the Grade line. Does not affect any dimension score.

---

## Steps 3–6: Audit, Score, Report, and Optionally Fix

Continue with `references/audit-steps.md` for:

- **Step 3:** Score 5 dimensions (2 pts each, max 10)
- **Step 4:** Output scored report with grade
- **Step 5:** Offer optimized version with targeted fixes
- **Step 6:** Write-to-disk confirmation (requires explicit second confirmation)

---

## Quick Reference Checklist

Use this for rapid pre-audit assessment:

**Frontmatter**
- [ ] YAML delimiters (`---`) present and matching
- [ ] `name:` field present, ≤64 chars, lowercase + numbers + hyphens only
- [ ] `name:` does not contain `anthropic` or `claude` as substring
- [ ] `description:` field present, ≤1024 chars
- [ ] Description written in third person
- [ ] "Use when..." trigger phrase present in description
- [ ] Description contains a capability statement (not only the trigger phrase)

**Body**
- [ ] Total lines <500
- [ ] Word count <5,000 (per Anthropic guide)
- [ ] No Windows-style paths (`\`)
- [ ] No hardcoded absolute paths
- [ ] No time-sensitive platform-state content ("as of 2024", "currently", "recently added")
- [ ] No first/second person in frontmatter description
- [ ] Consistent terminology throughout
- [ ] Complex workflows use a checklist pattern (copy-and-check-off steps)
- [ ] No "options without a default" pattern (pick one, mention alternatives)
- [ ] No assumed tool/package availability without explicit install instructions

**Structure**
- [ ] File named exactly `SKILL.md` (case-sensitive)
- [ ] Skill folder uses kebab-case naming
- [ ] Table of contents present in reference files (if ≥100 lines); optional suggestion for SKILL.md
- [ ] Reference files at depth ≤1 (no `references/sub/file.md`)
- [ ] Freedom level stated or implied
- [ ] Content distributed across three levels (frontmatter → body → references) where appropriate
- [ ] Feedback loops present for quality-critical or iterative tasks

**Design Pattern**
- [ ] Identifiable pattern (Sequential, Orchestrator, Iterative, or Adaptive)
- [ ] Body structure matches the chosen pattern

**Scripts** (apply if skill contains a `scripts/` folder or has bash/python code blocks with external tool invocations)
- [ ] MCP tools referenced with fully qualified `ServerName:tool_name` format
- [ ] No unexplained magic numbers (all constants documented)
- [ ] Error handling explicit — scripts handle failures rather than punting to Claude
- [ ] Required packages listed with install instructions

**Discoverability**
- [ ] "Use when..." trigger phrase clear and specific
- [ ] ≥3 searchable keywords in description
- [ ] Scope defined (what this skill does NOT cover)

**Regression Risk** (skip if not in git, file is new, or user opts out)
- [ ] `name:` field unchanged (BREAKING if changed)
- [ ] `description:` trigger phrases preserved (BREAKING if any removed)
- [ ] `description:` activation intent preserved (WARNING if `Use when...` clause or ≥3 domain keywords absent vs. previous)
- [ ] Reference files not removed (WARNING if any `references/` path disappeared)
- [ ] Line count not reduced >30% (WARNING if significant shrinkage)
- [ ] No new anti-patterns introduced vs. previous version (INFO)
