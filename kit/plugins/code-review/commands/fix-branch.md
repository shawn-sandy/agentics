---
description: Review all branch changes vs the default branch, then autonomously fix blocking, major, and minor issues until the branch is clean. Refuses on a dirty working tree. Leaves fixes uncommitted.
argument-hint: "[base-branch] (optional) — defaults to the remote default branch; falls back to main, then master"
allowed-tools: Bash(git *), Read, Edit, Write, Glob, Grep, Skill
---

# fix-branch

Review every file changed on the current branch vs the default branch. Classify findings by severity, apply fixes autonomously, and stop. Fixes are left uncommitted so you can review with `git diff` before committing.

## When not to use

Does not create commits or PRs — use `/git-agent:commit-agent` and `/git-agent:pr-agent` for those. Does not review code logic, security, or performance — use the `code-review-agent` skill for that. This command only reviews the *changes on the branch* against repo rules, conventions, and frontmatter constraints.

---

## Step 0 — Pre-flight

**Refuse on dirty working tree:**

```bash
git status --porcelain --untracked-files=all
```

If the output is non-empty (staged, unstaged, or untracked changes), stop immediately:

> ERROR: working tree has uncommitted changes. Commit or stash first so review fixes are isolated from your in-progress work.

**Resolve base branch:**

1. If `$ARGUMENTS` is non-empty, use it as the base.
2. Else run:
   ```bash
   git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's,^refs/remotes/origin/,,'
   ```
3. If that returns empty, try local `main`: `git rev-parse --verify main 2>/dev/null` → use `main`.
4. If that fails, try local `master`.
5. If that fails, try remote `origin/main` (`git rev-parse --verify origin/main 2>/dev/null`).
6. If that fails, try `origin/master`.
7. If all fail, stop: "Could not detect a default branch. Pass the base branch explicitly: `/code-review:fix-branch main`"

**Compute merge base:**

```bash
MERGE_BASE=$(git merge-base "$BASE" HEAD)
```

---

## Step 1 — Enumerate changes

```bash
git log $MERGE_BASE..HEAD --oneline
git diff $MERGE_BASE..HEAD --name-only
```

If the file list is empty, output:

> Branch is clean — nothing to review.

and stop.

Store the file list as `$CHANGED_FILES` for the remainder of the run.

---

## Step 2 — Review each changed file

For every file in `$CHANGED_FILES`, `Read` it, then apply all four criteria below. Build a findings list — each finding has: `file`, `line` (approximate), `tag` (see Step 3), and a one-sentence `description`.

### Criterion 1 — Repo rules

Read `.claude/rules/plugin-patterns.md`, `.claude/rules/skill-authoring.md`, `.claude/rules/marketplace.md`, and `.claude/rules/plan-hygiene.md` (use `Glob` to find all `.claude/rules/*.md` files). Apply each rule to the relevant changed files:

- Plugin pattern rules → command `.md`, skill `SKILL.md`, and `plugin.json` files.
- Skill authoring rules → `SKILL.md` files.
- Marketplace rules → `.claude-plugin/marketplace.json` and `plugin.json` files.
- Plan-hygiene rules → any `docs/plans/*.md` files in `$CHANGED_FILES`.

### Criterion 2 — Project conventions

`Read` `CLAUDE.md` and `CLAUDE.local.md` (if present). Apply conventions to all changed files. Common checks: no emojis in code/docs (unless explicitly requested), version only in `marketplace.json` not `plugin.json`, plan files committed alongside plugin changes.

### Criterion 3 — Frontmatter validation

For every `SKILL.md` in `$CHANGED_FILES`:

- `name`: lowercase kebab-case, ≤64 chars, no reserved words (`anthropic`, `claude`).
- `description`: non-empty, ≤1024 chars, third person, starts with "Use when".
- **160-char budget target**: descriptions over 160 chars are a **minor** finding (not blocking — platform limit is 1024).
- If `ExitPlanMode` or `EnterPlanMode` appears anywhere in the body, confirm `ToolSearch` is also listed in `allowed-tools`.

For every `plugin.json` in `$CHANGED_FILES`: confirm `name` field is present.

For every `marketplace.json` change:

```bash
jq empty .claude-plugin/marketplace.json 2>&1
```

Non-zero exit → **blocking** finding.

### Criterion 4 — Plan verification

For every `docs/plans/*.md` in `$CHANGED_FILES`, locate the verification section using a flexible parser:

- Match any heading whose text contains "verif" (case-insensitive): `## Verification`, `## End-to-end correctness checks`, etc.
- Also extract `<em>Verify:</em>` lines from within `<li>` blocks.

Execute only **read-only** shell commands found in those sections (e.g. `jq`, `grep`, `ls`, `find`, `wc`). Before running any command, confirm it contains no shell metacharacters (`|`, `>`, `>>`, `&`, `;`, backticks, `$()`, `||`, `&&`) and does not modify files. If a command does not meet these criteria, skip execution and surface it as an **unfixable** finding: "Plan verification command requires manual execution: `<command>`". Non-zero exit from an allowed command → **blocking** finding.

### Delegation for SKILL.md and agent files

- If `$CHANGED_FILES` contains any `**/SKILL.md`, invoke:
  ```
  Skill("skill-reviewer:reviewing-skills", <path>)
  ```
  Merge the skill's findings into the master list. Tag each delegated finding with its severity using the rubric in Step 3.
- If `$CHANGED_FILES` contains any `**/agents/*.md`, invoke `skill-reviewer:reviewing-skills` for each and merge findings.

---

## Step 3 — Classify findings

Tag each finding using this rubric:

| Tag | Definition | Examples |
|---|---|---|
| **blocking** | Breaks the file, fails validation, or contradicts plan verification | Invalid JSON, missing `name` field in `plugin.json`, failing `jq` check, broken cross-reference in CHANGELOG |
| **major** | Significant gap likely to cause user confusion or runtime failure | Behavior change without doc update, `ExitPlanMode` in body but `ToolSearch` missing from `allowed-tools`, README references a renamed skill |
| **minor** | Polish, consistency, or style | Typo, description over 160 chars (under 1024), table alignment, emoji in docs file |
| **unfixable** | Needs human judgment — do not auto-edit | Ambiguous renaming, missing description text that requires domain knowledge, logic error requiring design input |

---

## Step 4 — Apply fixes

For every finding tagged `blocking`, `major`, or `minor`:

- Apply the fix using `Edit` (preferred) or `Write`.
- Do not prompt before editing.
- Do not touch `unfixable` findings — accumulate them for the report.

After all edits in this round, re-run only the verification commands that previously failed (Criterion 4) to confirm they now pass.

---

## Step 5 — Retry once (cap = 2)

If new fixable findings (`blocking`, `major`, or `minor`) surfaced after Step 4 edits, repeat Steps 2–4 once more. After two total iterations, stop — do not loop further. Report whatever findings remain.

---

## Step 6 — Report

Output a markdown summary in this format:

```
### fix-branch results

| Iteration | Found | Fixed | Remaining |
|-----------|-------|-------|-----------|
| 1         | N     | N     | N         |
| 2 (retry) | N     | N     | N         |

**Unfixable findings** (need human review):
- `path/to/file` line ~N: [one-line description]

Fixed N issues across M files. K unfixable findings need human review.
Run `git diff` to review, then `/git-agent:commit-agent` to commit.
```

If there were no findings at all, output only:

> All changed files pass review. Nothing to fix.
