# Skill Reviewer

A Claude Code plugin for auditing SKILL.md files against Anthropic's official Claude Code skill authoring best practices. Produces a scored report and optionally generates a corrected version.

## Overview

The Skill Reviewer performs structured quality audits of SKILL.md files across 5 dimensions: frontmatter validity, body quality, structure and progressive disclosure, anti-pattern detection, and discoverability. Each dimension is scored 0–2 for a maximum of 10 points, with a grade from Excellent to Rewrite.

This plugin is the counterpart to `claude-md-optimizer` — while that plugin audits CLAUDE.md files, this one audits skill files.

## Features

- **5-Dimension Scoring** — Structured rubric covering frontmatter, body, structure, anti-patterns, and discoverability
- **Graded Reports** — Excellent / Good / Needs Work / Rewrite grades with per-dimension breakdown
- **Fix Generation** — Auto-corrects frontmatter errors; flags body issues with inline `<!-- SUGGESTION -->` comments
- **Live Docs Support** — Optionally fetches latest guidelines from the platform docs URL
- **Safe Write Confirmation** — Requires explicit second confirmation before overwriting files

## Installation

### Install via Marketplace (Recommended)

```bash
# Register the marketplace
/plugin marketplace add https://github.com/shawn-sandy/agentics

# Install the plugin
/plugin install skill-reviewer@agentics-kit
```

### Load Locally (Development)

```bash
claude --plugin-dir /path/to/agentics/plugins/skill-reviewer
```

## Usage

Once the plugin is loaded, the `reviewing-skills` skill activates automatically when you ask to review a SKILL.md file:

```
Review the SKILL.md at plugins/my-plugin/skills/my-skill/SKILL.md
```

```
Audit this skill and tell me if it follows best practices
```

```
Score my skill and generate a corrected version
```

### Using Live Guidelines

To fetch the latest criteria from the platform docs instead of the bundled reference:

```
Review my skill using the latest official guidelines
```

```
Check my SKILL.md against the current platform docs
```

## Plugin Structure

```
plugins/skill-reviewer/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── reviewing-skills/
│       ├── SKILL.md
│       └── references/
│           ├── audit-steps.md
│           └── best-practices.md
├── README.md
└── CHANGELOG.md
```

## Components

### Skill: `reviewing-skills`

**Auto-activates when:** User asks to review, audit, score, or check the quality of a SKILL.md file.

**Does NOT activate for:** CLAUDE.md files, command files, or general markdown.

**Audit process:**

1. Resolve the target SKILL.md (explicit path > conversation context > ask user)
2. Read and measure (line count, frontmatter fields, reference files)
3. Determine guidelines source (static reference or live fetch)
4. Score 5 dimensions (2 pts each, max 10)
5. Output scored report with grade and issue list
6. Offer to generate corrected version (frontmatter fixes + inline body annotations)
7. Confirm before writing to disk

**Scoring dimensions:**

| Dimension | Max Pts | What it checks |
|-----------|---------|----------------|
| Frontmatter Validity | 2 | name format, description rules, third person, trigger phrase |
| Body Quality | 2 | line count, conciseness, examples, no time-sensitive content |
| Structure & Progressive Disclosure | 2 | reference depth, TOC, freedom level, headings |
| Anti-pattern Detection | 2 | Windows paths, `$ARGUMENTS`, XML, reserved words |
| Discoverability | 2 | trigger clarity, keyword density, scope definition |

**Grade thresholds:**

| Score | Grade |
|-------|-------|
| 9–10 | Excellent |
| 6–8 | Good |
| 3–5 | Needs Work |
| 0–2 | Rewrite |

### Reference: `references/best-practices.md`

Detailed criteria with good/bad examples for all 5 scoring dimensions. Loaded by the skill during audits as the default guidelines source.

### Reference: `references/audit-steps.md`

Complete Steps 3–6 workflow: scoring rubric tables, report output format, fix generation rules, and write-to-disk confirmation logic.
