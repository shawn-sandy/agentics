# Rule file format

All generated rule files follow this structure:

```markdown
---
paths:
  - "<glob-pattern>"
---

# <Descriptive Title>

- Rule bullet 1
- Rule bullet 2
- Rule bullet 3
- Rule bullet 4 (if applicable)
- Rule bullet 5 (if applicable)
```

**Brace expansion** (from official docs: <https://code.claude.com/docs/en/memory>):

```md
---
paths:
  - "src/**/*.{ts,tsx}"
  - "{src,lib}/**/*.ts"
---
```

This expands to match multiple extensions or directories in a single rule.

- The `paths:` frontmatter causes Claude Code to activate this rule file only when working with matching files
- Use double quotes around glob patterns in the YAML frontmatter
- Title should be human-readable and describe the scope (e.g., "API Endpoint Rules", "Test File Standards")
- Rules must be concrete and actionable — not summaries or vague guidance

## Notes

- Path-specific rules reduce noise: Claude only sees them when relevant, keeping context lean
- A project with a clean CLAUDE.md and well-scoped `.claude/rules/` files is better than one with everything in CLAUDE.md
- Multiple `paths:` entries are valid in a single rule file when the same rules apply to several patterns
- Both modes must confirm before writing any file to disk
