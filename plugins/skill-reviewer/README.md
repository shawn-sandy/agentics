# Skill Reviewer

A Claude Code plugin for auditing SKILL.md files and planning new skills. Aligned with Anthropic's "The Complete Guide to Building Skills for Claude" (Jan 2026).

## Overview

The Skill Reviewer provides two skills:

1. **reviewing-skills** — Structured quality audits of SKILL.md files across 5 dimensions (frontmatter, body quality, structure, anti-patterns, discoverability). Scored 0–10 with grades from Excellent to Rewrite.
2. **planning-skills** — Guided workflow for planning, designing, and scaffolding new Claude Code skills from scratch, including design pattern selection and file generation.

This plugin is the counterpart to `claude-md-optimizer` — while that plugin audits CLAUDE.md files, this one audits and helps create skill files.

## Features

- **5-Dimension Scoring** — Structured rubric covering frontmatter, body, structure, anti-patterns, and discoverability
- **Graded Reports** — Excellent / Good / Needs Work / Rewrite grades with per-dimension breakdown
- **Fix Generation** — Auto-corrects frontmatter errors; flags body issues with inline `<!-- SUGGESTION -->` comments
- **Design Pattern Guidance** — Identifies and recommends Sequential, Orchestrator, Iterative, or Adaptive patterns
- **Skill Scaffolding** — Generates complete skill folders with SKILL.md, references, and scripts
- **Word Count & Folder Checks** — Validates against Anthropic's 5,000-word limit and folder structure conventions
- **Script Quality Checks** — Detects assumed installs, unqualified MCP tool references, voodoo constants, and missing error handling
- **Workflow Pattern Guidance** — Checklist, feedback loop, template, and conditional workflow patterns in best-practices reference
- **Regression Risk Check** — Optional git-based comparison (Step 2c) detects breaking changes (`name:` renamed, trigger phrase removed) and regressions (reference files removed, >30% line reduction, new anti-patterns) vs. last committed version; classified as BREAKING | WARNING | INFO and reported separately from the 1–10 score
- **Live Docs Support** — Optionally fetches latest guidelines from `platform.claude.com`
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

Once the plugin is loaded, skills activate automatically based on user intent.

### Reviewing Skills

```
Review the SKILL.md at plugins/my-plugin/skills/my-skill/SKILL.md
```

```
Audit this skill and tell me if it follows best practices
```

```
Score my skill and generate a corrected version
```

### Planning Skills

```
Help me plan a new skill for code formatting
```

```
I want to create a skill that reviews PR descriptions
```

```
What design pattern should I use for a deploy workflow skill?
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
│   ├── reviewing-skills/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── audit-steps.md
│   │       └── best-practices.md
│   └── planning-skills/
│       ├── SKILL.md
│       └── references/
│           └── design-patterns.md
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
4. Run Regression Risk Check (optional — compares against last committed version via git)
5. Score 5 dimensions (2 pts each, max 10)
6. Output scored report with grade, regression risk section, and issue list
7. Offer to generate corrected version (frontmatter fixes + inline body annotations)
8. Confirm before writing to disk

**Scoring dimensions:**

| Dimension | Max Pts | What it checks |
|-----------|---------|----------------|
| Frontmatter Validity | 2 | name format, description rules, third person, trigger phrase |
| Body Quality | 2 | line count (<500 ideal), conciseness, examples, no time-sensitive content |
| Structure & Progressive Disclosure | 2 | reference depth, TOC, freedom level, headings, feedback loops |
| Anti-pattern Detection | 2 | Windows paths, `$ARGUMENTS`, XML, reserved words, assumed installs, MCP tool format, script error handling |
| Discoverability | 2 | trigger clarity, keyword density, scope definition |

**Body Quality threshold:** `<500 lines` is the official Anthropic limit for optimal performance. Skills in the 400–499 line range score 2/2 (previously 1/2 in v1.1.0 — this is a scoring threshold change).

**Grade thresholds:**

| Score | Grade |
|-------|-------|
| 9–10 | Excellent |
| 6–8 | Good |
| 3–5 | Needs Work |
| 0–2 | Rewrite |

### Reference: `references/best-practices.md`

Detailed criteria with good/bad examples for all 5 scoring dimensions. Includes three-level progressive disclosure, folder structure rules, design patterns, skill packs, and word count thresholds. Aligned with Anthropic's guide.

### Reference: `references/audit-steps.md`

Complete Steps 3–6 workflow: scoring rubric tables, report output format, fix generation rules, and write-to-disk confirmation logic. Includes word count, folder structure, and design pattern in report output.

### Skill: `planning-skills`

**Auto-activates when:** User asks to plan, design, create, or scaffold a new skill.

**Does NOT activate for:** Reviewing existing skills, auditing SKILL.md files, or general planning tasks.

**Planning workflow:**

1. Understand the skill goal (purpose, triggers, tools, output)
2. Select a design pattern (Sequential, Orchestrator, Iterative, Adaptive)
3. Plan the folder structure (SKILL.md, references/, scripts/, assets/)
4. Draft the YAML frontmatter (name + description with triggers)
5. Outline the SKILL.md body structure
6. Generate the skill files on disk

### Reference: `references/design-patterns.md`

Comprehensive reference for four Anthropic design patterns with recommended SKILL.md outlines, structure signals, key considerations, a decision tree, and pattern combination guidance.
