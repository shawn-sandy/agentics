# claude-md-optimizer Plugin

Audits and optimizes CLAUDE.md files against Claude Code best practices. Use this plugin when your CLAUDE.md feels bloated, when Claude seems to be ignoring instructions, or when you want a structured quality score before committing changes.

## Purpose

CLAUDE.md files are loaded as system instructions on every Claude Code session. A poorly structured file wastes context, conflicts with other instructions, or includes content irrelevant to most sessions — causing Claude to ignore parts of it silently. This plugin helps you measure and fix those problems before they cause frustration.

## Skills

| Skill | Activation |
|-------|-----------|
| `claude-md-optimizer` | Triggers when user asks to "optimize", "audit", "review", "clean up", "check", "analyze", or "improve" a CLAUDE.md file. Also activates when user reports Claude ignoring instructions or CLAUDE.md appears bloated. |
| `path-rules-advisor` | Triggers when user wants to create path-specific rules, add rules for specific file types or directories, extract rules from CLAUDE.md into `.claude/rules/`, or check whether a project needs path-specific rules. |

## Usage

### claude-md-optimizer

Just describe what you want:

```
Audit my CLAUDE.md file
Optimize my project's Claude instructions
My Claude is ignoring my CLAUDE.md instructions — what's wrong?
Review ~/.claude/CLAUDE.md for issues
```

Or provide a specific path:

```
Audit /path/to/project/CLAUDE.md
Optimize the CLAUDE.md at ~/myproject/CLAUDE.md
```

**What it does:**

1. Resolves the target file (explicit path → `$PWD/CLAUDE.md` → `$PWD/.claude/CLAUDE.md` → `~/.claude/CLAUDE.md`)
2. Measures line count, instruction count, sections, and `@path/to/file` imports
3. Scores 6 dimensions (Instruction Budget, Section Quality, 80% Rule, Progressive Disclosure, Safety & Hygiene, Structure)
4. Reports a scored audit with grade (Optimized / Functional / Needs work / Rewrite)
5. Optionally generates an optimized version and offers to create `.claude/rules/` files for extracted content

### path-rules-advisor

**Mode A — Direct creation** (provide a glob pattern and description):

```
/path-rules-advisor src/api/**/*.ts - All endpoints must validate input and return typed responses
```

**Mode B — Analysis mode** (no arguments):

```
Check if my project needs path-specific rules
Extract rules from CLAUDE.md into separate files
```

**What it does:**

1. In Mode A: parses the glob pattern and description, generates a rule file with `paths:` frontmatter, and writes it to `.claude/rules/` after confirmation
2. In Mode B: scans your CLAUDE.md for path-scoped content, inventories existing `.claude/rules/` files, and recommends new rule files based on project structure

## Installation

```
/plugin install claude-md-optimizer@agentics-kit
```

Or load directly for local testing:

```bash
claude --plugin-dir ./plugins/claude-md-optimizer
```
