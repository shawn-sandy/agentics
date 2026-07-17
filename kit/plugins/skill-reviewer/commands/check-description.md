---
description: Measure description-frontmatter length for one or more SKILL.md files and warn if any exceed the 200-char budget.
allowed-tools: Bash, Glob, AskUserQuestion
---

# Check SKILL.md description length

Measure the `description:` frontmatter length for one or more SKILL.md files by running the shared `measure-description.sh` script. Reports `OK:`, `WARNING:` (over the 200-char budget), `WARNING:` (multi-line), or `ERROR:` (missing) for each file.

## Resolve target files

1. If `$ARGUMENTS` is a path to an existing file ending in `SKILL.md`: use that file directly.
2. If `$ARGUMENTS` looks like a glob pattern: use `Glob` with that pattern from `$PWD`.
3. If `$ARGUMENTS` is empty: use `Glob` for `**/SKILL.md` from `$PWD`.
4. Otherwise: ask the user to clarify with `AskUserQuestion`.

## Measure each file

For each resolved file path, run:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/measure-description.sh" "$file"
```

This emits one line per file. Print each line as-is.

## Report

After measuring all files, summarize:

- Total files checked
- Count of `OK` vs `WARNING` vs `ERROR`
- For any over-budget file: suggest running `/skill-reviewer:optimizing-skill-frontmatter` to trim it (the WARNING message already includes this pointer — do not duplicate it)
