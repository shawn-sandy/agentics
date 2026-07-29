# Mode steps

Loaded once the mode is settled. Both modes confirm before writing any file to disk.

## Contents

- [Mode A — Argument provided](#mode-a--argument-provided)
- [Mode B — No argument (analysis mode)](#mode-b--no-argument-analysis-mode)

## Mode A — Argument provided

Use this mode when the user provides an argument in their message.

**Argument format:** `<glob-pattern> - <rule description>`

The ` - ` (space-hyphen-space) separates the glob pattern from the rule description.

**Example:** `src/api/**/*.ts - All endpoints must validate input and return typed responses`

### Steps

**Step 1 — Parse the argument**

Split the argument on the first ` - `. Left side = glob pattern. Right side = rule description.

If no ` - ` separator is found, stop and ask the user to re-enter in the format:
`<glob-pattern> - <rule description>`

Example: `src/api/**/*.ts - All endpoints must validate input`

**Step 2 — Infer the output filename**

Derive a filename from the glob pattern:

| Glob example | Filename |
|---|---|
| `src/api/**/*.ts` | `api-rules.md` |
| `tests/**/*.test.ts` | `test-rules.md` |
| `components/**/*.tsx` | `component-rules.md` |
| `src/lib/**` | `lib-rules.md` |

General rule: take the most specific directory segment from the glob and append `-rules.md`. Strip `src/`, `**`, `*`, and file extensions.

**Step 3 — Check for conflicts**

Check if `.claude/rules/<filename>` already exists. If it does, show the user the existing file path and ask:
"This file already exists. Overwrite it, or choose a different filename?"

Do not proceed until the user confirms or provides a new filename.

**Step 4 — Check for the `.claude/rules/` directory**

Check if `.claude/rules/` exists in the project root.

If it does not exist, tell the user and ask:
"The `.claude/rules/` directory does not exist. Should I create it?"

Do not write any files until the user confirms.

**Step 5 — Expand the description into rules**

Take the user's description and expand it into 3–5 well-formed, actionable rule bullets. Each bullet should:
- Start with an imperative verb (Always, Never, Prefer, Ensure, Use)
- Be concrete and specific — avoid vague language like "handle properly" or "be careful"
- Address a distinct concern related to the description

**Step 6 — Show the generated file**

Display the complete rule file in a code block, following `references/rule-file-format.md`.

**Step 7 — Confirm before writing**

Ask: "Should I write this to `.claude/rules/<filename>`?"

Wait for explicit confirmation. Do not write the file until confirmed. Apply the pre-write
verification gate in `references/write-verification.md` to any file being overwritten, then write,
then run that reference's post-write check on the new file and confirm the file path to the user.

---

## Mode B — No argument (analysis mode)

Use this mode when the user provides no argument.

**Step 1 — Resolve the CLAUDE.md target**

Use the same priority order as the `agentic-memory-management` skill:

1. `CLAUDE.md` in the current working directory
2. `.claude/CLAUDE.md` in the current working directory
3. `~/.claude/CLAUDE.md`

If both `CLAUDE.md` and `.claude/CLAUDE.md` exist, analyze `CLAUDE.md` (root takes priority) and note that `.claude/CLAUDE.md` was skipped.

Tell the user which file will be analyzed (CLAUDE.md, .claude/CLAUDE.md, or ~/.claude/CLAUDE.md). If none found, report that no CLAUDE.md was located and offer to proceed with project structure analysis only.

**Step 2 — Inventory `.claude/rules/`**

Check whether `.claude/rules/` exists. If it does not, note this prominently.

If it does exist, list every `.md` file found there along with their `paths:` frontmatter values (if any).

**Step 3 — Scan CLAUDE.md for path-scoped content**

Read CLAUDE.md and look for content that is specific to particular file types, directories, or frameworks:

- Mentions of file extensions: `*.ts`, `*.tsx`, `*.py`, `*.css`, `*.test.ts`
- Directory references: `src/`, `lib/`, `tests/`, `components/`, `api/`
- Framework-specific rules: React components, API endpoints, database models, migration files
- Section headings that imply scope: "Frontend Rules", "API Conventions", "Test Standards"

**Step 4 — Check project structure**

Glob for the presence of these directories in the project root:
- `src/`
- `lib/`
- `tests/` or `test/`
- `components/`
- `api/`
- `app/`

Note which ones exist — this informs starter template recommendations.

**Step 5 — Report findings**

**If no path-scoped content found in CLAUDE.md:**

Report that the CLAUDE.md looks clean from a path-scoping perspective.

List which directories were detected and offer starter templates based on them. For example:

> The following directories were detected: `src/`, `tests/`. Would you like starter rule files for any of these?
> - `src-rules.md` (paths: `src/**`) — general source file conventions
> - `test-rules.md` (paths: `tests/**`) — test authoring and assertion standards

**If path-scoped content was found:**

Report findings in a structured summary:

```
## Path-Rules Analysis

**CLAUDE.md analyzed:** [path]
**Existing .claude/rules/ files:** [list or "none"]

### Extractable sections found

| Section / content | Suggested rule file | Suggested paths |
|---|---|---|
| [description] | [filename] | [glob] |
```

Ask: "Which of these would you like me to create as rule files?"

**Step 6 — Create approved rule files**

For each rule file the user approves:

1. Check for conflicts (file already exists → ask before overwriting)
2. Create `.claude/rules/` directory if it does not exist (ask first)
3. Expand the extracted content into 3–5 well-formed rule bullets
4. Write `.claude/rules/<name>.md` with `paths:` frontmatter

Show each file in a code block before writing. Apply the pre-write verification gate in
`references/write-verification.md` to CLAUDE.md and to any rule file being overwritten, then after
each write run that reference's post-write check on that file and confirm.

**Step 7 — Offer to update CLAUDE.md**

After writing each rule file, ask once:

"Should I remove this content from CLAUDE.md and replace it with a reference to `.claude/rules/<name>.md`?"

If confirmed, replace the extracted section in CLAUDE.md with:

```markdown
# See .claude/rules/<name>.md
```

Then run the post-write check in `references/write-verification.md` on CLAUDE.md.

If the user declines, leave CLAUDE.md unchanged.
