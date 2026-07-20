# memory-tools Plugin

Audits and optimizes CLAUDE.md project memory files against Claude Code best practices. Use this plugin when your CLAUDE.md feels bloated, when Claude seems to be ignoring instructions, or when you want a structured quality score before committing changes.

## Installation

### Via Marketplace (recommended)

```bash
/plugin install memory-tools@agentics-kit
```

### Local Development

```bash
claude --plugin-dir ./kit/plugins/memory-tools
```

## Usage

This plugin provides two auto-activated skills. Invoke them by describing what you want in plain language — no slash command required.

### Skills

| Skill | Activation | Allowed Tools |
|-------|-----------|---------------|
| `memory-tools:agentic-memory-management` | Auto — triggers when user asks to "audit", "optimize", "review", "clean up", or "diagnose" a CLAUDE.md or project memory file; also activates when user reports Claude ignoring instructions | `AskUserQuestion`, `Glob`, `Grep`, `Read`, `Write` |
| `memory-tools:path-rules-advisor` | Auto — triggers when user wants to create path-specific rules, add rules for file types or directories, or organize `.claude/rules/` | `AskUserQuestion`, `Edit`, `Glob`, `Read`, `Write` |

Both skills are auto-activated — there is no manual slash command. Just describe your intent.

---

### agentic-memory-management

Audits a CLAUDE.md file against a 6-dimension scoring rubric and optionally rewrites it.

**Optimization principle (v3.1.1):** The skill applies a core filter — keep only rules that would change Claude's behavior versus its built-in defaults; cut everything else. Tighten the rules that survive to crisp verb-first imperatives.

**Example prompts:**

```
Audit my CLAUDE.md file
Optimize my project's Claude instructions
My Claude is ignoring my CLAUDE.md instructions — what's wrong?
Diagnose my project memory file
Review ~/.claude/CLAUDE.md for issues
Audit /path/to/project/CLAUDE.md
```

**What the skill does:**

1. Resolves the target file: explicit path → `CLAUDE.md` in current directory → `.claude/CLAUDE.md` → `~/.claude/CLAUDE.md`
2. Measures line count, instruction count, sections, secrets (via Grep), and `@import` references with effective line count
3. Scores 6 dimensions: Instruction Budget, Section Quality, 80% Rule, Progressive Disclosure, Safety & Hygiene, Structure
4. Reports a scored audit with grade (Optimized / Functional / Needs work / Rewrite); names any default-restating rules driving Dimension 5 deductions
5. Optionally generates an optimized rewrite — gated by explicit `AskUserQuestion` confirmation
6. Optionally creates `.claude/rules/` files for extracted sections — also opt-in

**Does not cover:** SKILL.md files, slash commands, or general markdown files.

---

### path-rules-advisor

Analyzes your project structure and CLAUDE.md to recommend and generate scoped rule files in `.claude/rules/`.

**Two operating modes:**

- **Mode A — Argument provided:** User supplies a glob pattern and description (e.g., `src/api/**/*.ts - All endpoints must validate input`). The skill creates the rule file directly.
- **Mode B — Analysis mode:** No argument supplied. The skill reads the project structure and CLAUDE.md, then recommends which sections should become scoped rules and offers to generate them.

**Example prompts:**

```
Create path-specific rules for my TypeScript files
Add a rule for src/api/**/*.ts - All endpoints must validate input and return typed responses
Analyze my project and suggest what should go in .claude/rules/
Organize my Claude rules into scoped files
```

**Does not cover:** Creating or overwriting CLAUDE.md or global memory entries — use `agentic-memory-management` for that.

---

## Purpose

CLAUDE.md files are loaded as system instructions on every Claude Code session. A poorly structured file wastes context, conflicts with other instructions, or includes content irrelevant to most sessions — causing Claude to ignore parts of it silently. This plugin helps you measure and fix those problems before they cause frustration.

## Plugin Structure

```
kit/plugins/memory-tools/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── agentic-memory-management/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── audit-steps.md
│   └── path-rules-advisor/
│       └── SKILL.md
├── CHANGELOG.md
└── README.md
```

This is a skills-only plugin — no commands or agents.

## Version History

Current version: **4.0.0**

### Breaking Changes

- **v4.0.0** — Primary skill renamed from `agentic-memory-doctor` to `agentic-memory-management`. Update any `@import` references:
  - Old: `@<plugin-dir>/skills/agentic-memory-doctor/SKILL.md`
  - New: `@<plugin-dir>/skills/agentic-memory-management/SKILL.md`
  - Find stale live references: `git grep -n 'skills/agentic-memory-doctor/SKILL.md' -- ':!kit/plugins/memory-tools/README.md' ':!**/CHANGELOG.md' ':!docs/'`
- **v3.0.0** — Primary skill renamed from `memory-doctor` to `agentic-memory-doctor`.
- **v2.0.0** — Plugin renamed from `claude-md-optimizer` to `memory-tools`. Reinstall required.

See [CHANGELOG.md](CHANGELOG.md) for the full version history.
