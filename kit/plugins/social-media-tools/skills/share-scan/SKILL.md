---
name: share-scan
description: "Scans git history or a codebase path for shareable code. Drafts social media prompts for share-code or digest generation. Use when the user asks to find commits worth sharing or create a digest."
allowed-tools: Bash, Read, Grep, Glob, AskUserQuestion, Write, Skill, ToolSearch, ExitPlanMode
---

# share-scan

Discover shareable code, scrub for secrets, and draft `share-code` prompts. Writes a digest file the user reviews before posting.

## Two modes

| Arguments | Mode | Source |
|-----------|------|--------|
| *(default)* | **History** | `git log` on current branch |
| `--codebase <path>` | **Codebase** | `Read`/`Glob` on given path |

---

## Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** — skip this step entirely when not in plan mode. When calling: use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

---

## Step 0b — Load Project Sharing Config

Check for `SOCIAL.md` at the project root:

```bash
SOCIAL_CONFIG=""
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -f "$PWD/SOCIAL.md" ]; then
  SOCIAL_CONFIG="$PWD/SOCIAL.md"
elif [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/SOCIAL.md" ]; then
  SOCIAL_CONFIG="$GIT_ROOT/SOCIAL.md"
fi
```

If found, `Read` it silently. Extract:
- `FOCUS_AREAS` — bullet list from `## Focus`; boost candidate scores in Step 3
- `AVOID_PATTERNS` — bullet list from `## Avoid`; filter candidates in Step 2

---

## Step 1 — Configure

Parse `$ARGUMENTS`:

- `--days=N` — how far back to scan (default: 7, history mode only)
- `--base=BRANCH` — base branch for diff (auto-detect `main` or `master` if omitted, history mode only)
- `--max=N` — max candidates before scoring (default: 20)
- `--codebase <path>` — activates codebase mode; value is the path to scan

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
git show --stat --format="" [hash]
```
(`git show` handles root commits safely; `git diff [hash]~1` fails when there is no parent.)

Limit to `--max` candidates before scoring.

### Codebase mode

Use `Glob` to find source files under the given path (exclude: `node_modules`, `.git`, `dist`, `build`, `*.min.js`, `*.map`, lock files).

For each file use `Read` to load content. Collect `{file_path, excerpt}` as the candidate unit (excerpt = first 100 lines or the most interesting block).

---

## Step 2b — Apply Avoid Filters

If `AVOID_PATTERNS` was loaded from SOCIAL.md, remove candidates whose commit
subject, changed file path, or file path matches any avoid pattern (case-insensitive
substring or glob match). Log filtered count silently.

---

## Step 3 — Score candidates

`Read` the `references/interesting-patterns.md` file adjacent to this SKILL.md to load the current scoring table.

- **History mode:** score each commit by message prefix and lines-changed heuristics from the table.
- **Codebase mode:** score each file by file/function pattern heuristics from the table.

**Focus boost:** If `FOCUS_AREAS` was loaded from SOCIAL.md, add +1 to the score
of any candidate whose subject or path matches a focus keyword (case-insensitive).

Include candidates with score ≥ 2. If fewer than 3 qualify, fill up with score ≥ 1 candidates until you have 3 (or exhaust the list).

---

## Step 4 — Security scrub (mandatory — never skip)

For each candidate:

1. Get the content:
   - History: `git show --format="" -U3 [hash]`
   - Codebase: the file excerpt from Step 2
2. Invoke the `security-scrub` skill on the content.
3. Check both fields of the result:
   - `SCRUB RESULT: BLOCKED` or `ALLOWLIST verdict: BLOCKED` → remove candidate, note reason
   - `SCRUB RESULT: WARN` → keep but flag as `⚠ WARN` in the digest

Candidates that were BLOCKED are excluded from the digest entirely. WARN candidates appear with a warning label.

---

## Step 4b — Cross-reference Media Library

Before building digest entries, check `docs/media/social/` for already-saved posts that match each candidate. This prevents surfacing content that has already been shared.

```bash
MEDIA_DIR="${PWD}/docs/media/social"
```

For each candidate:
- **History mode**: slugify the commit subject (`tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g'`) and check if any file in `$MEDIA_DIR` contains those tokens: `ls "$MEDIA_DIR" 2>/dev/null | grep -i "<slug-tokens>"`
- **Codebase mode**: slugify the filename and do the same check

If a match is found, mark the candidate with `SAVED=true` and the matching file path `SAVED_PATH`.

Include SAVED candidates but tag them with `[SAVED]` in the review gate options and in the digest output.

---

## Step 5 — Build digest entries

For each surviving candidate, build a structured entry using the card-type decision tree and platform heuristics from `references/interesting-patterns.md`:

```markdown
### [N]. <subject>

- **Source:** `<commit hash>` or `<file path>`
- **Card type:** <feature-card | diff-card | quote-card>
- **Platform:** <one of the platforms from `$PLUGIN_DIR/references/platforms.md`>
- **Summary:** <one sentence describing what makes this shareable>
- **Key change / highlight:** <the most interesting line or pattern>
- **Security:** PASS ✓ (or ⚠ WARN — <reason>)
- **Already saved:** [SAVED: `docs/media/social/{filename}`] (omit this line if not saved)
- **share-code prompt:**
  ```
  /social-media-tools:share-code <card-type> for <platform>: <description>
  ```
```

---

## Step 6 — Human review gate

Present all PASS and WARN candidates in a **single** `AskUserQuestion` call with `multiSelect: true`. Options list each candidate by number and subject. Include a note on any WARN entry.

Ask: "Which entries should go into the digest?" — options are the candidates, plus "None — discard all".

Use only the user-selected entries in the final digest.

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

**STOP. Do not invoke `share-code` automatically.** The user reviews the digest and picks which prompts to run.
