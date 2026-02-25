# Plan: Create `skill-reviewer` Plugin

## Context

No plugin currently reviews SKILL.md files for quality. While `claude-md-optimizer` handles CLAUDE.md auditing, there is no equivalent for skill files. The user provided the official Anthropic best practices guide and wants a skill that audits their SKILL.md files against those standards.

This plan creates a new plugin `skill-reviewer` with a single skill `reviewing-skills` that performs a structured, scored audit and optionally generates a corrected version.

---

## Files to Create

| File | Purpose |
|------|---------|
| `plugins/skill-reviewer/.claude-plugin/plugin.json` | Plugin manifest v1.0.0 |
| `plugins/skill-reviewer/skills/reviewing-skills/SKILL.md` | Short overview + Steps 1-2 only (~100-150 lines max) |
| `plugins/skill-reviewer/skills/reviewing-skills/references/audit-steps.md` | Steps 3-6 detail: scoring rubric, output format, fix generation, write confirmation |
| `plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md` | Detailed criteria with good/bad examples (TOC required) |
| `plugins/skill-reviewer/README.md` | Plugin documentation |
| `plugins/skill-reviewer/CHANGELOG.md` | Version history |

## Files to Modify

| File | Change |
|------|--------|
| `.claude-plugin/marketplace.json` | Append new plugin entry (version 1.0.0, category `development`) |

---

## Implementation Steps

1. Create `plugins/skill-reviewer/.claude-plugin/plugin.json`:
   ```json
   {
     "name": "skill-reviewer",
     "version": "1.0.0",
     "description": "Review SKILL.md files against Anthropic's official Claude Code skill authoring best practices",
     "author": { "name": "Agentics Project" },
     "license": "MIT",
     "keywords": ["skills", "plugin-authoring", "best-practices", "skill-review", "quality-audit"],
     "homepage": "https://github.com/shawn-sandy/agentics/tree/main/plugins/skill-reviewer",
     "repository": "https://github.com/shawn-sandy/agentics"
   }
   ```

2. Create `plugins/skill-reviewer/skills/reviewing-skills/SKILL.md` with:
   - **Frontmatter:** `name: reviewing-skills`, description in third person with "Use when..." trigger phrasing; add "...for SKILL.md files specifically — not CLAUDE.md, commands, or general markdown" to prevent activation collision with `plugin-dev:skill-reviewer`
   - **Step 1:** Resolve target SKILL.md — check user's message for explicit path first; fall back to conversation context; ask if still unclear. Do NOT use `$ARGUMENTS`/`$PWD` (command-only variables not available in skills)
   - **Step 2:** Read and measure (line count, frontmatter fields, body lines, reference files detected)
   - **Step 2b:** Determine guidelines source — default to `references/best-practices.md`; fetch live from `https://code.claude.com/docs/en/agents-and-tools/agent-skills/best-practices` when user says "use latest", "check official docs", or "fetch from platform"; if live fetch fails, fall back to static reference silently and note the failure in output
   - **Delegate to `references/audit-steps.md`** for Steps 3-6 (keeps SKILL.md body under 150 lines)
   - **Quick Reference Checklist** inline at bottom of SKILL.md

3. Create `plugins/skill-reviewer/skills/reviewing-skills/references/audit-steps.md` with:
   - **Step 3:** Score 5 dimensions (2 pts each, max 10):
     1. Frontmatter Validity — name: max 64 chars, lowercase+numbers+hyphens, no XML, no substring match of reserved words `anthropic`/`claude` (e.g., `claude-helper` fails); description: max 1024 chars, third person, "Use when..." required
     2. Body Quality — conciseness, <500 lines, consistent terminology, concrete examples, no time-sensitive content
     3. Structure & Progressive Disclosure — reference depth ≤1 level, TOC on files >100 lines, freedom level matches fragility
     4. Anti-pattern Detection — Windows paths (`\`), options without a default, time-sensitive content in main body, first/second person in description
     5. Discoverability — "Use when..." present, trigger clarity, ≥3 searchable keywords, scope defined
   - **Step 4:** Output scored report (table + grade: Excellent 9-10 / Good 6-8 / Needs work 3-5 / Rewrite 0-2)
   - **Step 5:** Offer optimized version — fix all Errors in frontmatter; flag body Warnings/Suggestions with `<!-- SUGGESTION: ... -->` inline comments; do not rewrite body content
   - **Step 6:** Confirm before writing to disk (requires explicit second confirmation; warn that this overwrites the file)

4. Create `plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md` with:
   - Table of contents (file will be >100 lines)
   - Frontmatter rules (name format, description rules, third-person requirement)
   - Naming convention table (bad vs good examples)
   - Body quality rules (conciseness, line limits, concrete examples)
   - Structure rules (progressive disclosure, reference depth, freedom level)
   - Anti-patterns table with Error/Warning severity labels
   - Discoverability patterns with trigger phrase examples

5. Create `plugins/skill-reviewer/README.md` — standard plugin README structure (Overview, Features, Installation, Usage, Plugin Structure, Components)

6. Create `plugins/skill-reviewer/CHANGELOG.md` with `[1.0.0] - 2026-02-25` initial release entry

6. Edit `.claude-plugin/marketplace.json`:
   - Bump top-level `"version"` from `"2.0.0"` to `"2.1.0"`
   - Append to `plugins` array:
   ```json
   {
     "name": "skill-reviewer",
     "source": "./plugins/skill-reviewer",
     "version": "1.0.0",
     "description": "Review SKILL.md files against Anthropic's official Claude Code skill authoring best practices",
     "category": "development",
     "tags": ["skills", "plugin-authoring", "best-practices", "skill-review", "quality-audit", "claude-code"]
   }
   ```

7. Verify version sync: plugin `"version": "1.0.0"` must match in both `plugin.json` and `marketplace.json` plugin entry

8. Commit: `feat(plugins/skill-reviewer): initial release v1.0.0`

---

## Verification

After implementation:

```bash
# Verify plugin structure
ls plugins/skill-reviewer/skills/reviewing-skills/

# Verify version sync
grep -r '"version"' plugins/skill-reviewer/.claude-plugin/ .claude-plugin/marketplace.json

# Load plugin locally for testing
claude --plugin-dir ~/devbox/agentics/plugins/skill-reviewer
```

Then test by prompting: _"Review the SKILL.md at plugins/wcag-compliance-reviewer/skills/wcag-compliance-reviewer/SKILL.md"_

Expected: Skill activates, runs 6 steps, outputs scored report.

---

## Key Design Decisions

- **Skill name `reviewing-skills`** — gerund form per Anthropic best practice (not `skill-reviewer`); demonstrates the rule it enforces
- **5 dimensions not 6** — SKILL.md files have narrower surface than CLAUDE.md; 5 gives full coverage without inflation
- **Two reference files** — `audit-steps.md` for rubric/workflow, `best-practices.md` for criteria; keeps SKILL.md body under 150 lines (passes its own 500-line rule — meta-correctness)
- **Reserved words = substring match** — `claude-helper` fails because it contains `claude` as substring per spec intent
- **Fix scope** — corrected version fixes frontmatter Errors, flags body Warnings with `<!-- SUGGESTION: -->` comments; preserves author's body content
- **Fetch fallback** — live-fetch failure silently falls back to static reference, noted in audit output
- **Marketplace 2.1.0** — minor bump; new plugin is backward-compatible addition
- **Two-confirmation write** — file overwrites require explicit second confirmation to prevent data loss
- **Pattern reference:** `plugins/wcag-compliance-reviewer/` — closest structural precedent (single-skill reviewer with reference files)
