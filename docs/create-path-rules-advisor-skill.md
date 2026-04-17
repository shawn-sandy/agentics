# Add `path-rules-advisor` Skill to claude-md-optimizer Plugin

> Adds a new `path-rules-advisor` skill that analyzes a project for path-specific rule candidates and generates `.claude/rules/*.md` files with `paths:` frontmatter — or creates them directly from a provided glob pattern and description.

<!-- generated:start -->

**Status:** Shipped 2026-02-24   **Plan:** [create-path-rules-advisor-skill.md](plans/create-path-rules-advisor-skill.md)   **Type:** artifact

## What shipped

- New `kit/plugins/claude-md-optimizer/skills/path-rules-advisor/SKILL.md` — two-mode skill: Mode A (argument provided: direct rule file creation) and Mode B (no argument: analysis mode).
- `claude-md-optimizer` plugin bumped from `1.1.0` → `1.2.0`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/claude-md-optimizer/skills/path-rules-advisor/SKILL.md` | Skill instructions — path-rules-advisor | Created |
| `kit/plugins/claude-md-optimizer/.claude-plugin/plugin.json` | Plugin manifest — version bump 1.1.0 → 1.2.0 | Modified |
| `kit/plugins/claude-md-optimizer/CHANGELOG.md` | Plugin changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump to 1.2.0 | Modified |

## How it works

**Mode A** (argument provided) parses `$ARGUMENTS` on the first ` - ` separator: everything before is the glob pattern, everything after is the rule description. If no ` - ` is found, the user is prompted to re-enter. The skill infers a filename from the glob (e.g., `src/api/**/*.ts` → `api-rules.md`), checks for existing files at that path, ensures `.claude/rules/` exists (offering to create it if not), expands the description into 3–5 rule bullets, shows the generated file in a code block, and asks for confirmation before writing.

**Mode B** (no argument) runs analysis: inventories `.claude/rules/` and scans CLAUDE.md for path-scoped content (mentions of `*.ts`, `src/`, `tests/`, specific framework names). It also runs Glob checks for common project directories. If no path-scoped content is found, it reports clean and offers directory-based starter templates. If path-scoped content is found, it presents findings and asks which rule files the user wants created. After writing each file, it optionally removes the extracted content from CLAUDE.md and replaces it with a reference comment.

Generated rule files use the official format with `paths:` frontmatter:
```markdown
---
paths:
  - "src/api/**/*.ts"
---

# API Development Rules

- Rule bullet 1
```

## How to use it

**Skill activation** — triggers on "create path-specific rules", "add rules for specific file types", "check if this project needs path rules":

```
# Direct creation:
/claude-md-optimizer:path-rules-advisor src/api/**/*.ts - all endpoints must validate input

# Analysis mode:
/claude-md-optimizer:path-rules-advisor
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |
| `9924d3f` | 2026-04-09 | refactor(kit/plugins): trim allowed-tools to only tools each skill actually uses |

<!-- generated:end -->

## References

- Plan: [create-path-rules-advisor-skill.md](plans/create-path-rules-advisor-skill.md)
