# claude-md-optimizer Plugin

Audits and optimizes CLAUDE.md files against Claude Code best practices. Use this plugin when your CLAUDE.md feels bloated, when Claude seems to be ignoring instructions, or when you want a structured quality score before committing changes.

## Purpose

CLAUDE.md files are loaded as system instructions on every Claude Code session. A poorly structured file wastes context, conflicts with other instructions, or includes content irrelevant to most sessions — causing Claude to ignore parts of it silently. This plugin helps you measure and fix those problems before they cause frustration.

## Skills

| Skill | Activation |
|-------|-----------|
| `claude-md-optimizer` | Triggers when user asks to "optimize", "audit", "review", "clean up", or "analyze" a CLAUDE.md file. Also activates when user reports Claude ignoring instructions. |

## Usage

### Automatic activation (skill)

Just describe what you want:

```
Audit my CLAUDE.md file
Optimize my project's Claude instructions
My Claude is ignoring my CLAUDE.md instructions — what's wrong?
Review ~/.claude/CLAUDE.md for issues
```

### Providing a specific path

```
Audit /path/to/project/CLAUDE.md
Optimize the CLAUDE.md at ~/myproject/CLAUDE.md
```

### What the skill does

1. Resolves the target file (explicit path → `$PWD/CLAUDE.md` → `$PWD/.claude/CLAUDE.md` → `~/.claude/CLAUDE.md`)
2. Measures line count, instruction count, sections, and `@import` references
3. Scores 6 dimensions (Instruction Budget, Section Quality, 80% Rule, Progressive Disclosure, Safety & Hygiene, Structure)
4. Reports a scored audit with grade (Optimized / Functional / Needs work / Rewrite)
5. Optionally generates and writes an optimized version

## Installation

```
/plugin install claude-md-optimizer@agentics-kit
```

Or load directly for local testing:

```bash
claude --plugin-dir ./kit/plugins/claude-md-optimizer
```
