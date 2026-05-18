---
description: Scan plan directories for randomly-named files and rename them to descriptive kebab-case names based on content headings
allowed-tools:
  - Glob
  - Read
  - Bash
  - AskUserQuestion
  - Skill
argument-hint: "[directory-path] (optional, uses plansDirectory setting by default)"
---

# Plan File Hygiene

Scan plan directories for files with random non-descriptive names and rename them to descriptive kebab-case names derived from their content headings.

## Directories to Scan

1. **Primary**: Read `plansDirectory` from `.claude/settings.json` (e.g., `docs/planning`)
2. **Additional**: Also scan `openspec/plans/` and `project-docs/06-implementation-plans/`
3. **Override**: If `$ARGUMENTS` is provided, scan only that directory instead

## Random Name Detection

A filename (without `.md`) is "random" if ALL are true:
- Has exactly 2-3 hyphens (3-4 words like `precious-knitting-tulip`)
- Does NOT start with a number
- None of the words are software terms: `fix`, `add`, `refactor`, `implement`, `update`, `create`, `remove`, `delete`, `migrate`, `test`, `review`, `configure`, `optimize`, `debug`, `setup`, `build`, `rename`, `extract`, `revert`, `enable`, `disable`, `pr`, `api`, `ui`, `css`, `auth`, `db`, `nav`, `form`, `crud`, `order`, `event`, `client`, `product`, `modal`, `dialog`, `table`, `page`, `route`, `schema`, `role`, `layout`, `style`, `config`, `hook`, `middleware`, `service`, `component`, `wrapper`, `list`, `view`, `edit`, `index`, `plan`, `spec`, `feature`, `bug`, `chore`, `docs`, `release`, `security`, `performance`, `plugin`, `agent`, `skill`, `command`, `workflow`, `deploy`, `npm`, `git`, `code`

If none found, report "All plan files have descriptive names." and stop.

## Name Generation

1. Read first 10 lines of each detected file
2. Extract first `# Plan: ...` or `# ...` heading
3. Convert to kebab-case: lowercase, spaces to hyphens, strip special chars,
   collapse hyphens, max 60 chars at word boundary, append `.md`. Then apply a
   **verb-led check**: if the first word of the result is not an imperative
   verb, extract the dominant action from the heading and prepend it. Examples:
   heading `Auth Module Refactor` → `refactor-auth-module.md`; heading
   `User Dashboard` → `add-user-dashboard.md`; heading `Plugin Settings Screen`
   → `add-plugin-settings-screen.md`. Common verbs: `add`, `fix`, `create`,
   `build`, `implement`, `update`, `refactor`, `migrate`, `configure`, `remove`,
   `enable`, `disable`, `move`, `rename`, `extract`, `deploy`, `document`,
   `integrate`.
4. If name exists, append `-v2` (increment as needed)
5. No heading found? Skip file, note in output

## Approval Flow

**IMPORTANT: ALWAYS ask the user for permission before performing any renames. Never rename files automatically.**

1. Present a markdown table of proposals:

```
| # | Directory | Current Name | Proposed Name |
|---|-----------|-------------|---------------|
| 1 | docs/planning/ | fancy-forging-flamingo.md | add-insights-guardrails-to-claude-md.md |
```

2. Use AskUserQuestion with options: "Rename all", "Select specific", "Cancel".
3. If the user selects "Cancel", stop immediately without making any changes.
4. If the user selects "Select specific", ask which files to rename before proceeding.
5. Do NOT proceed to execution without explicit user approval.

## Execution

Only after receiving explicit user approval:

1. `git mv [old] [new]` for each approved rename (fallback: `mv` + `git add`)
2. Commit: `chore: rename plan files to descriptive conventions`
3. Display summary table with status per file
4. If all fail, do NOT commit

## HTML Generation (after rename commit)

After the rename commit lands, generate an HTML view for every renamed file.
This is a separate commit so each concern has its own history entry.

**Step A — Migrate stale HTML artifacts**

For each renamed file, check whether `<old-basename>.html` exists in the same
directory. If so, rename it to match the new basename to avoid leaving orphaned
artifacts:

```bash
git mv <dir>/<old-basename>.html <dir>/<new-basename>.html
```

Fallback if `git mv` fails (file not tracked): `mv` + `git add` new path +
`git rm` old path.

**Step B — Choose theme once**

Ask the user once via `AskUserQuestion` which theme to apply to all regenerated
HTML files:

- **Default** — neutral grays and white, blue accent
- **Developer** — dark charcoal header, green accent (terminal-inspired)
- **Document** — warm off-white background, sepia/brown accent
- **Minimal** — pure white background, black text, no accent color

**Step C — Generate HTML per renamed file**

For each renamed file, invoke the `markdown-to-html` skill with the new path, the
chosen theme, and `--background` to suppress all prompts (theme, overwrite, browser open):

```
Skill(skill: "plan-interview:markdown-to-html", args: "<new-path> --theme=<chosen> --background --mode=plan")
```

**Step D — Commit regenerated HTML**

Stage the exact regenerated/migrated `.html` paths collected during Steps A/C
(across all processed directories), then commit:

```bash
git add <path1>.html <path2>.html ...
git commit -m "chore: regenerate plan HTML after rename"
```

If no `.html` files were written or migrated, skip this commit.

**Step E — Report**

Display a final table:

```markdown
## HTML Generated

| Plan File | HTML Output | Theme |
|-----------|-------------|-------|
| `add-insights-guardrails-to-claude-md.md` | `add-insights-guardrails-to-claude-md.html` | developer |
```

## Examples

```
/plan-hygiene                    # Scans plansDirectory + additional dirs
/plan-hygiene docs/planning      # Scans only docs/planning
/plan-hygiene openspec/plans     # Scans only openspec/plans
```
