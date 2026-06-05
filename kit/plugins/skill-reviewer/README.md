# Skill Reviewer

A Claude Code plugin for auditing SKILL.md files and planning new skills. Aligned with Anthropic's "The Complete Guide to Building Skills for Claude" (Jan 2026).

## Overview

The Skill Reviewer provides four skills (three auto-activating, one manual-invoke), one slash command, and an always-on hook:

1. **reviewing-skills** — Structured quality audits of SKILL.md files across 5 dimensions (frontmatter, body quality, structure, anti-patterns, discoverability). Scored 0–10 with grades from Excellent to Rewrite.
2. **planning-skills** — Guided workflow for planning, designing, and scaffolding new Claude Code skills from scratch, including design pattern selection and file generation.
3. **auditing-allowed-tools** — Audits a SKILL.md to recommend (or patch) the minimal `allowed-tools` frontmatter it needs so users aren't prompted for permission mid-run. Also parses Claude Code session JSONL transcripts to report what tools Claude actually invoked, and can cross-reference a skill against a real session.
4. **optimizing-skill-frontmatter** — Optimizes two frontmatter fields in a single pass: rewrites `description:` to the three-part format (≤200 chars total, short description ≤80 chars) and sets `disable-model-invocation` to the correct value based on whether the skill is a workflow or advisory tool. Manual invoke only — use `/skill-reviewer:optimizing-skill-frontmatter` explicitly.
5. **check-description** (command) — `/skill-reviewer:check-description [path-or-glob]` — on-demand check of `description:` length for one or more SKILL.md files.
6. **Description-length hook** — fires automatically on every Write/Edit/MultiEdit to any SKILL.md in the current project and warns if the description exceeds the budget.

This plugin is the counterpart to `memory-tools` — while that plugin audits CLAUDE.md files, this one audits and helps create skill files.

All skills declare `allowed-tools` explicitly in their frontmatter for consistent, session-independent tool access.

## Installation

### Via Marketplace (recommended)

```bash
/plugin install skill-reviewer@agentics-kit
```

### Local Development

```bash
claude --plugin-dir ./kit/plugins/skill-reviewer
```

## Usage

Most skills activate automatically based on user intent. The exception is `optimizing-skill-frontmatter`, which requires explicit invocation — it is a write-heavy workflow skill that should not auto-fire on intent match.

### Commands

| Command | Description |
|---------|-------------|
| `/skill-reviewer:check-description [path-or-glob]` | Measure description-frontmatter length for one or more SKILL.md files and warn if any exceed the budget. |

### Skills

| Skill | Activation | Description |
|-------|-----------|-------------|
| `reviewing-skills` | Auto | Scores SKILL.md files across 5 quality dimensions. Audits against Anthropic's authoring best practices and optionally generates a fix. |
| `planning-skills` | Auto | Scaffolds a new skill with SKILL.md and supporting files. Walks a structured workflow covering frontmatter, body, references, and scripts. |
| `auditing-allowed-tools` | Auto | Audits and fixes `allowed-tools` for SKILL.md files. Recommends or patches permissions; cross-references against session transcripts. |
| `optimizing-skill-frontmatter` | Manual invoke only — use `/skill-reviewer:optimizing-skill-frontmatter` explicitly | Optimizes SKILL.md frontmatter fields. Rewrites descriptions to three-part format (≤200 chars) and tunes `disable-model-invocation`. |

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

### Auditing allowed-tools

```
What allowed-tools should kit/plugins/foo/skills/bar/SKILL.md have?
```

```
Fix the permissions on my skill so users don't get prompted mid-run
```

```
Audit allowed-tools for one of my skills
```

```
What tools did Claude actually use in this session?
```

```
Did foo/bar/SKILL.md actually need everything it declared? Check against the current session.
```

### Optimizing Skill Frontmatter

Manual invoke only — this skill writes to SKILL.md files and requires explicit invocation:

```bash
/skill-reviewer:optimizing-skill-frontmatter
```

Rewrites descriptions to the three-part format (short description ≤80 chars, capability sentence, trigger phrase; total ≤200 chars) and tunes `disable-model-invocation` to `true` for write-heavy workflow skills or omits it for read-only advisory skills.

### Checking Description Lengths

```bash
/skill-reviewer:check-description
```

```bash
/skill-reviewer:check-description kit/plugins/my-plugin/skills/my-skill/SKILL.md
```

### Using Live Guidelines

To fetch the latest criteria from the platform docs instead of the bundled reference:

```
Review my skill using the latest official guidelines
```

```
Check my SKILL.md against the current platform docs
```

## Hooks

### Description-length warning hook

The plugin ships a `PostToolUse` hook in `hooks.json` that fires automatically when Claude writes or edits any `SKILL.md` file in the current project. It warns if the `description:` frontmatter value exceeds the budget:

```text
OK: SKILL.md description is 142 chars (within budget for current installed-skill count) in kit/plugins/my-plugin/skills/my-skill/SKILL.md
WARNING: SKILL.md description is 214 chars (over budget for current installed-skill count) in kit/plugins/my-plugin/skills/my-skill/SKILL.md — run /skill-reviewer:optimizing-skill-frontmatter to optimize
```

**Description length budgets:** Claude Code's default `skillListingBudgetFraction` (1% of the context window) allocates roughly 8,000 chars total across all installed skills. The `optimizing-skill-frontmatter` skill targets the three-part format (≤200 chars total, short description ≤80 chars):

| Installed skills | Safe avg description length | Format target |
|---|---|---|
| ≤40 | ~200 chars | Full three-part (short + capability + trigger) |
| ~50 | ~160 chars | Two-part (capability + trigger) |
| ~100 | ~80 chars | Short description only |

The three-part format is designed so the short description (≤80 chars, always Sentence 1) survives even at ~100 skills — truncation never removes the label entirely.

**Scope:** only fires on SKILL.md files inside the current git repository. External plugins installed to `~/.claude/plugins/` or other locations outside the repo are skipped.

**Dedup:** fires only when the `description:` line actually changes, not on every write to the file.

**To disable the hook**, add an override to your user or project `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Write|Edit|MultiEdit", "hooks": [] }
    ]
  }
}
```

Or uninstall the plugin (`/plugin uninstall skill-reviewer`) if you no longer need it.

**Shared script:** the hook delegates to `scripts/measure-description.sh`. This script is also used by the `/skill-reviewer:check-description` command — updating the threshold or measurement logic in one place applies to both.

---

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
- **Frontmatter Optimization** — Rewrites descriptions to three-part format (≤200 chars total, short description ≤80 chars) and tunes `disable-model-invocation` in a single pass
- **Live Docs Support** — Optionally fetches latest guidelines from `platform.claude.com`
- **Safe Write Confirmation** — Requires explicit second confirmation before overwriting files

## Plugin Structure

```
plugins/skill-reviewer/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   └── check-description.md
├── hooks.json
├── scripts/
│   └── measure-description.sh
├── skills/
│   ├── reviewing-skills/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── audit-steps.md
│   │       └── best-practices.md
│   ├── planning-skills/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── design-patterns.md
│   ├── auditing-allowed-tools/
│   │   ├── SKILL.md
│   │   └── scripts/
│   │       └── session_tool_scan.py
│   └── optimizing-skill-frontmatter/
│       └── SKILL.md
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

### Skill: `auditing-allowed-tools`

**Auto-activates when:** User asks to audit, recommend, fix, or generate the `allowed-tools` frontmatter for a SKILL.md, or asks what tools/permissions Claude used during a session.

**Does NOT activate for:** General SKILL.md quality audits (use `reviewing-skills`), `settings.json` `permissions` rules, or hook configuration.

**Three operating modes:**

1. **Static audit** — reads a SKILL.md, scans the body for tool-usage signals (code fences, inline backticks, known CLI tokens, MCP references, script paths), and recommends the minimal `allowed-tools` declaration. Suggests restricted `Bash(<cli> *)` when a single CLI family is detected. Offers three apply modes: *add missing only*, *replace with minimal set*, or *report only*.
2. **Session audit** — resolves a session JSONL (explicit path, UUID, or newest under `~/.claude/projects/<encoded-cwd>/`) and runs `scripts/session_tool_scan.py` to report the tools Claude actually invoked, with a per-command breakdown for `Bash` and optional subagent aggregation.
3. **Cross-reference** — compares declared vs. statically detected vs. observed usage to flag undocumented runtime dependencies and overly broad declarations.

**Target resolution (Mode 1):** explicit path → conversation context (hand off from `reviewing-skills`) → `Glob`-based picker presented via `AskUserQuestion`.

**Script: `scripts/session_tool_scan.py`** — standalone Python 3, no third-party dependencies, streams JSONL line-by-line, tolerates truncated final lines, and emits structured JSON on stdout.

### Skill: `optimizing-skill-frontmatter`

**Manual invoke only** — use `/skill-reviewer:optimizing-skill-frontmatter` explicitly. This skill writes to SKILL.md files and should not auto-fire on intent match.

**Does NOT activate for:** General SKILL.md quality audits (use `reviewing-skills`), `allowed-tools` changes (use `auditing-allowed-tools`). This skill only touches `description:` and `disable-model-invocation`.

**What it does:** Optimizes two frontmatter fields in a single pass:

1. Rewrites `description:` to the **three-part format**: a short description (≤80 chars) capturing the essential function, a capability sentence with richer detail, and a "Use when…" trigger phrase. Total ≤200 chars.
2. Sets `disable-model-invocation` to `true` for write-heavy workflow skills or omits it for read-only advisory skills.

**Description format targets:**

| Installed skills | Safe avg description length | Format target |
|---|---|---|
| ≤40 | ~200 chars | Full three-part (short + capability + trigger) |
| ~50 | ~160 chars | Two-part (capability + trigger) |
| ~100 | ~80 chars | Short description only |

The short description (≤80 chars, always Sentence 1) is designed to survive even aggressive truncation at ~100 skills installed.

**Workflow summary:**

1. Exit plan mode (write-heavy skill)
2. Resolve target SKILL.md files
3. Measure current descriptions and classify as SKIP or REWRITE
4. Rewrite descriptions applying five rules (target format, three-part structure, trigger consolidation, negative-scope relocation, filler removal)
5. Apply edits
6. Tune `disable-model-invocation` based on tool usage signals
7. Verify results
8. Offer to optimize remaining project skills

### Command: `check-description`

**Invocation:** `/skill-reviewer:check-description [path-or-glob]`

**Use when:** you want to measure description lengths for SKILL.md files you have not edited this session, or to batch-check many files before committing.

```bash
# Check a single file
/skill-reviewer:check-description kit/plugins/my-plugin/skills/my-skill/SKILL.md

# Check all SKILL.md files in the repo
/skill-reviewer:check-description
```

With no argument, globs `**/SKILL.md` from `$PWD` and reports one line per file. For any over-budget file, suggests running `/skill-reviewer:optimizing-skill-frontmatter`.

Delegates to `scripts/measure-description.sh` — same logic and threshold as the always-on hook.

### Script: `scripts/measure-description.sh`

Single source of truth for description measurement. Called by both the PostToolUse hook and the `check-description` command. Accepts one file path and emits a single `OK:`, `WARNING:`, or `ERROR:` line. Update the threshold or measurement logic here to apply the change to both surfaces.

All existing `kit/plugins/` SKILL.md descriptions were audited and trimmed before this hook was shipped (see CHANGELOG v1.8.0).
