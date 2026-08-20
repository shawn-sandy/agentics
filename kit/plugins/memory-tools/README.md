# memory-tools Plugin

Audits and optimizes Claude Code configuration — CLAUDE.md memory files, scoped rules, and usage-insights follow-through. Use this plugin when your CLAUDE.md feels bloated, when Claude seems to be ignoring instructions, when you want a structured quality score before committing changes, or when you have a usage-insights report whose recommendations need triaging and implementing.

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

This plugin provides three auto-activated skills. Invoke them by describing what you want in plain language — no slash command required.

### Skills

| Skill | Activation | Allowed Tools |
|-------|-----------|---------------|
| `memory-tools:agentic-memory-management` | Auto — triggers when user asks to "audit", "optimize", "review", "clean up", or "diagnose" a CLAUDE.md or project memory file; also activates when user reports Claude ignoring instructions | `AskUserQuestion`, `Glob`, `Grep`, `Read`, `Write` |
| `memory-tools:path-rules-advisor` | Auto — triggers when user wants to create path-specific rules, add rules for file types or directories, or organize `.claude/rules/` | `AskUserQuestion`, `Edit`, `Glob`, `Read`, `Write` |
| `memory-tools:implementing-insights` | Auto — triggers when user asks to implement or act on a usage-insights report's findings | `Read`, `Grep`, `Glob`, `Bash`, `Edit`, `Write`, `WebFetch`, `Agent`, `AskUserQuestion`, `ToolSearch`, `ExitPlanMode` |

All skills are auto-activated — there is no manual slash command. Just describe your intent.

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

### implementing-insights

Takes a Claude Code usage-insights report and implements only its genuinely open recommendations across local repos.

**Example prompts:**

```
Implement the findings from this insights report: docs/insights-2026-08.md
Act on the usage-insights report at <artifact URL>
Which of these insights recommendations are already covered by my config?
```

**What the skill does:**

1. Parses the report (file path, artifact URL, or pasted content) into numbered recommendation items
2. Triages every item against existing config (`~/.claude/`, installed plugins, each target repo) into three buckets: already implemented (cited), conflicts with an existing rule (rejected, cited), or genuinely open
3. Places each open item at the right config layer — plugin (workflow-shaped; falls back to `~/.claude/` when the user has no plugin repo), `~/.claude/` (machine-wide), or the target repo (repo-specific), resolving repos discover-first from `~/.claude/projects/` and asking for a projects directory only when discovery fails
4. Confirms scope, then implements one item per change — one PR per repo change, worktree isolation when parallel agents share a repo
5. Cleans up worktrees and merged branches, then reports a verified outcome ledger

**Does not cover:** Generating the insights report itself; never merges a PR without explicit approval.

---

## Purpose

CLAUDE.md files are loaded as system instructions on every Claude Code session. A poorly structured file wastes context, conflicts with other instructions, or includes content irrelevant to most sessions — causing Claude to ignore parts of it silently. This plugin helps you measure and fix those problems before they cause frustration.

## Plugin Structure

```
kit/plugins/memory-tools/
├── .claude-plugin/
│   └── plugin.json
├── bin/
│   └── memory-verify-write
├── skills/
│   ├── agentic-memory-management/
│   │   ├── SKILL.md
│   │   ├── references/
│   │   │   └── audit-steps.md
│   │   └── scripts/
│   │       └── verify_write.py
│   ├── path-rules-advisor/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── rule-modes.md
│   │       ├── rule-file-format.md
│   │       └── write-verification.md
│   └── implementing-insights/
│       └── SKILL.md
├── CHANGELOG.md
└── README.md
```

This is a skills-only plugin — no commands or agents.

## Version History

Current version: **4.3.0**

### Breaking Changes

- **v4.0.0** — Primary skill renamed from `agentic-memory-doctor` to `agentic-memory-management`. Update any `@import` references:
  - Old: `@<plugin-dir>/skills/agentic-memory-doctor/SKILL.md`
  - New: `@<plugin-dir>/skills/agentic-memory-management/SKILL.md`
  - Find stale live references: `git grep -n 'skills/agentic-memory-doctor/SKILL.md' -- ':!kit/plugins/memory-tools/README.md' ':!**/CHANGELOG.md' ':!docs/'`
- **v3.0.0** — Primary skill renamed from `memory-doctor` to `agentic-memory-doctor`.
- **v2.0.0** — Plugin renamed from `claude-md-optimizer` to `memory-tools`. Reinstall required.

See [CHANGELOG.md](CHANGELOG.md) for the full version history.
