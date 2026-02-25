---
name: reviewing-skills
description: Reviews SKILL.md files against Anthropic's official Claude Code skill authoring best practices. Use when the user asks to review, audit, score, or check the quality of a SKILL.md file specifically — not CLAUDE.md, commands, or general markdown. Use when the user says "review my skill", "audit this skill", "check skill quality", "score my SKILL.md", or "does this skill follow best practices".
---

## Overview

Performs a structured, scored audit of SKILL.md files against Anthropic's official Claude Code skill authoring best practices. Produces a scored report across 5 quality dimensions and optionally generates a corrected version.

Follow these steps exactly.

## Table of Contents

- [Step 1: Resolve Target SKILL.md](#step-1-resolve-target-skillmd)
- [Step 2: Read and Measure](#step-2-read-and-measure)
- [Step 2b: Determine Guidelines Source](#step-2b-determine-guidelines-source)
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
| Frontmatter fields present | name, description, and any extras |
| Body lines | Lines after closing `---` |
| Reference files detected | Any `references/` paths mentioned |

Note the presence or absence of:
- YAML frontmatter delimiters (`---`)
- `name:` field
- `description:` field
- "Use when..." trigger phrase in description
- Table of contents (for files ≥100 lines)

---

## Step 2b: Determine Guidelines Source

**Default:** Use `references/best-practices.md` (static, always available).

**Fetch live from platform docs when user says:**
- "use latest", "check official docs", "fetch from platform", "use current guidelines", "pull from the website"

Live fetch URL:
```
https://code.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
```

If live fetch fails: fall back to `references/best-practices.md` silently and note the failure in the audit output under a "Guidelines Source" line.

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

**Body**
- [ ] Total lines <500
- [ ] No Windows-style paths (`\`)
- [ ] No time-sensitive platform-state content ("as of 2024", "currently", "recently added")
- [ ] No first/second person in frontmatter description
- [ ] Consistent terminology throughout

**Structure**
- [ ] Table of contents present (if ≥100 lines)
- [ ] Reference files at depth ≤1 (no `references/sub/file.md`)
- [ ] Freedom level stated or implied

**Discoverability**
- [ ] "Use when..." trigger phrase clear and specific
- [ ] ≥3 searchable keywords in description
- [ ] Scope defined (what this skill does NOT cover)
