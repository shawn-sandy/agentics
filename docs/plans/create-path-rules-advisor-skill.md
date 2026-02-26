# Plan: Add `path-rules-advisor` Skill to claude-md-optimizer Plugin

## Context

The `claude-md-optimizer` plugin currently audits and optimizes CLAUDE.md files. Claude Code supports path-specific rules via `.claude/rules/*.md` files with `paths:` YAML frontmatter — these rules only activate when Claude works with files matching the specified patterns. There is no existing skill to detect when path-specific rules are needed or to generate them. This skill fills that gap.

## Outcome

A new skill `path-rules-advisor` in the `claude-md-optimizer` plugin that:
- Analyzes the project and CLAUDE.md to recommend and create path-specific rule files
- Accepts `$ARGUMENTS` (description or path pattern) to immediately create a targeted rule file

---

## Files to Create / Modify

| Action | File |
|--------|------|
| **Create** | `plugins/claude-md-optimizer/skills/path-rules-advisor/SKILL.md` |
| **Edit** | `plugins/claude-md-optimizer/.claude-plugin/plugin.json` — bump `1.1.0` → `1.2.0` |
| **Edit** | `.claude-plugin/marketplace.json` — bump `claude-md-optimizer` version to `1.2.0` |
| **Edit** | `plugins/claude-md-optimizer/CHANGELOG.md` — add `[1.2.0]` entry |

---

## Implementation Steps

### 1. Create `SKILL.md` at `plugins/claude-md-optimizer/skills/path-rules-advisor/SKILL.md`

**Frontmatter:**
```yaml
---
name: path-rules-advisor
description: Use when the user wants to create path-specific rules, add rules for specific file types or directories, organize Claude rules by file type, or check whether the current project needs path-specific rules in .claude/rules/.
---
```

**Skill logic (two modes based on `$ARGUMENTS`):**

**Mode A — Argument provided** (e.g., `src/api/**/*.ts - All endpoints must validate input`):

Argument format: `<glob-pattern> - <rule description>` using ` - ` as the separator.

1. Split `$ARGUMENTS` on the first ` - `. Left side = glob pattern, right side = description. If no ` - ` found, ask the user to re-enter in the correct format.
2. Infer a filename from the glob (e.g., `src/api/**/*.ts` → `api-rules.md`)
3. Check if `.claude/rules/<filename>` already exists — if so, ask before overwriting
4. Check if `.claude/rules/` directory exists — if not, offer to create it
5. Expand the description into 3–5 well-formed actionable rule bullets
6. Generate the rule file with `paths:` frontmatter + expanded rules; show in a code block
7. Ask for confirmation before writing

**Mode B — No argument** (analysis mode):
1. Resolve `.claude/rules/` and CLAUDE.md (same priority as claude-md-optimizer Step 1)
2. Check if `.claude/rules/` directory exists — note if absent
3. Read CLAUDE.md and inventory existing `.claude/rules/` files
4. Scan CLAUDE.md for path-scoped content (mentions of `*.ts`, `src/`, `tests/`, `API endpoints`, `React components`, specific framework names)
5. Check project structure (Glob for: `src/`, `lib/`, `tests/`, `components/`)
6. If no path-scoped content found: report clean + offer starter templates based on detected directories
7. If path-scoped content found: report findings (existing rules, extractable sections, recommended new files); ask which ones the user wants created
8. For each approved rule file: check for conflicts, create `.claude/rules/` if needed, write `.claude/rules/<name>.md` with `paths:` frontmatter
9. After writing each file: ask once "Remove this content from CLAUDE.md and replace with a reference?" — if confirmed, replace section with `# See .claude/rules/<name>.md`

**Rule file format** (per official docs):
```markdown
---
paths:
  - "src/api/**/*.ts"
---

# API Development Rules

- Rule content here
```

### 2. Bump version in `plugin.json`
- `"version": "1.1.0"` → `"version": "1.2.0"`

### 3. Bump version in `marketplace.json`
- `claude-md-optimizer` entry: `"version": "1.1.0"` → `"version": "1.2.0"`

### 4. Update `CHANGELOG.md`
Add entry:
```
## [1.2.0] - 2026-02-24

### Added
- New skill `path-rules-advisor`: analyzes project and CLAUDE.md to recommend and generate path-specific rule files in `.claude/rules/`
- Supports direct creation via `$ARGUMENTS` (path pattern + description) or analysis mode (no argument)
```

---

## Verification

1. Load the plugin locally:
   ```bash
   claude --plugin-dir ~/devbox/agentics/plugins/claude-md-optimizer
   ```
2. Test Mode B (no argument): ask Claude to "check if this project needs path-specific rules" — skill should auto-activate and analyze
3. Test Mode A (with argument): run the skill with an argument like `src/api/**/*.ts - all endpoints must validate input` — should generate a rule file and prompt before writing
4. Confirm both version fields match (`1.2.0`) with:
   ```bash
   grep '"version"' plugins/claude-md-optimizer/.claude-plugin/plugin.json .claude-plugin/marketplace.json
   ```

---

## Interview Summary

Stress-tested via plan-interview on 2026-02-24.

### Key Decisions Confirmed

1. Mode A uses ` - ` as the separator between glob pattern and description; prompts for clarification if absent
2. Mode B with no path-scoped findings → reports clean + offers directory-based starter templates
3. Mode B CLAUDE.md edit → single confirmation prompt; replaces extracted content with `# See .claude/rules/<name>.md`
4. Generated rule files contain 3–5 expanded, well-formed rule bullets — not verbatim user text

### Resolved Risks

1. `.claude/rules/` directory may not exist — both modes must check and offer to create it
2. Separator format (` - `) and fallback behavior now explicit in Mode A steps
3. Mode B CLAUDE.md modification flow added as Step 9
4. Conflict detection added to both modes — check before overwriting any existing rule file
