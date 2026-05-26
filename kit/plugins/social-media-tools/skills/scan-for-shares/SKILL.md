---
name: scan-for-shares
description: "Scans recent git history or a codebase path for shareable code and drafts social media prompts for code-share. Use when the user asks to find commits or code worth sharing, create a code digest, or generate a post from the codebase."
allowed-tools: Bash, Read, Grep, Glob, AskUserQuestion, Write, Skill
---

# scan-for-shares

Discover shareable code, scrub for secrets, and draft `code-share` prompts. Writes a digest file the user reviews before posting.

## Two modes

| Arguments | Mode | Source |
|-----------|------|--------|
| *(default)* | **History** | `git log` on current branch |
| `--codebase <path>` | **Codebase** | `Read`/`Glob` on given path |

---

## Step 1 — Configure

Parse `$ARGUMENTS`:

- `--days=N` — how far back to scan (default: 7, history mode only)
- `--base=BRANCH` — base branch for diff (auto-detect `main` or `master` if omitted, history mode only)
- `--max=N` — max candidates before scoring (default: 20)
- `--codebase <path>` — activates codebase mode; value is the path to scan
- `--background` — skip interactive review gate (auto-include PASS, auto-exclude BLOCKED/WARN)

**Guard (history mode only):** run `git rev-parse --git-dir 2>/dev/null` — if it fails, output:
```
Not a git repository. Run from a git repo root or use --codebase <path> for codebase mode.
```
Then stop.

---

## Step 2 — Collect candidates

### History mode

```bash
# By time window
git log --oneline --after="N days ago" --format="%H %s" HEAD

# By branch delta (deduplicate with above)
git log --oneline [base]..HEAD --format="%H %s"
```

Deduplicate by hash. For each unique hash get stats:
```bash
git diff [hash]~1 [hash] --stat
```

Limit to `--max` candidates before scoring.

### Codebase mode

Use `Glob` to find source files under the given path (exclude: `node_modules`, `.git`, `dist`, `build`, `*.min.js`, `*.map`, lock files).

For each file use `Read` to load content. Collect `{file_path, excerpt}` as the candidate unit (excerpt = first 100 lines or the most interesting block).

---

## Step 3 — Score candidates

`Read` the `references/interesting-patterns.md` file adjacent to this SKILL.md to load the current scoring table.

- **History mode:** score each commit by message prefix and lines-changed heuristics from the table.
- **Codebase mode:** score each file by file/function pattern heuristics from the table.

Include candidates with score ≥ 2. If fewer than 3 qualify, fill up with score ≥ 1 candidates until you have 3 (or exhaust the list).

---

## Step 4 — Security scrub (mandatory — never skip)

For each candidate:

1. Get the content:
   - History: `git diff [hash]~1 [hash] -U3`
   - Codebase: the file excerpt from Step 2
2. Invoke the `security-scrub` skill on the content.
3. Check both fields of the result:
   - `SCRUB RESULT: BLOCKED` or `ALLOWLIST verdict: BLOCKED` → remove candidate, note reason
   - `SCRUB RESULT: WARN` → keep but flag as `⚠ WARN` in the digest

Candidates that were BLOCKED are excluded from the digest entirely. WARN candidates appear with a warning label.

---

## Step 5 — Build digest entries

For each surviving candidate, build a structured entry using the card-type decision tree and platform heuristics from `references/interesting-patterns.md`:

```markdown
### [N]. <subject>

- **Source:** `<commit hash>` or `<file path>`
- **Card type:** <feature-card | diff-card | quote-card>
- **Platform:** <LinkedIn | Twitter/X | Bluesky>
- **Summary:** <one sentence describing what makes this shareable>
- **Key change / highlight:** <the most interesting line or pattern>
- **Security:** PASS ✓ (or ⚠ WARN — <reason>)
- **code-share prompt:**
  ```
  /code-share:code-share <card-type> for <platform>: <description>
  ```
```

---

## Step 6 — Human review gate

### Interactive mode (default — `--background` absent)

Present all PASS and WARN candidates in a **single** `AskUserQuestion` call with `multiSelect: true`. Options list each candidate by number and subject. Include a note on any WARN entry.

Ask: "Which entries should go into the digest?" — options are the candidates, plus "None — discard all".

Use only the user-selected entries in the final digest.

### Background mode (`--background` present)

Auto-include all PASS entries. Auto-exclude all BLOCKED and WARN entries. Skip the `AskUserQuestion` call entirely.

---

## Step 7 — Output digest

```bash
mkdir -p .claude/digests
```

Write the digest to `.claude/digests/code-digest-YYYY-MM-DD.md` using today's date. The file contains the selected entries from Step 5 plus a header:

```markdown
# Code Digest — YYYY-MM-DD

Mode: <history (last N days) | codebase (path)>
Generated: <timestamp>
Entries: <count>

---

<entries>
```

Report the output path and entry count to the user.

**STOP. Do not invoke `code-share` automatically.** The user reviews the digest and picks which prompts to run.
