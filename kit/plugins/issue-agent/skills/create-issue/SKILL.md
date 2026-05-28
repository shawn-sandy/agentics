---
name: create-issue
description: "Drafts and opens a GitHub or GitLab issue from any context source. Detects host from git remote and confirms before creating. Use when the user asks to file, open, or create an issue or ticket."
allowed-tools: Bash(gh *), Bash(glab *), Bash(git *), Bash(node *), Bash(npm *), AskUserQuestion, Read, Grep, Glob
disable-model-invocation: true
argument-hint: "[bug|feature|selection|session] [title or description]"
---

# Create Issue

Open a GitHub or GitLab issue from any context. Always confirms before creating — no issue is ever created without your approval.

## Overview

Ingests context from four sources (selection, session, bug, feature), detects the git host, drafts a structured issue body, shows a confirmation gate, then calls `gh` or `glab` to create the issue.

## Workflow

### Phase 1 — Detect host

Run:
```bash
git remote get-url origin
```

- URL contains `github.com` → host is **GitHub**, CLI is `gh`
- URL contains `gitlab.com` or any non-GitHub host after ruling out GitHub → host is **GitLab**, CLI is `glab`
- If the remote is absent or unrecognizable, use `AskUserQuestion` to ask: "Which host should I create the issue on? (GitHub / GitLab)"

### Phase 2 — Pre-flight checks

For GitHub:
```bash
gh auth status
gh repo view
```

For GitLab:
```bash
glab auth status
glab repo view
```

If the CLI is missing or unauthenticated, **stop** with a helpful message:
- "Run `! gh auth login` to authenticate with GitHub, then retry `/issue-agent:create-issue`."
- "Run `! glab auth login` to authenticate with GitLab, then retry `/issue-agent:create-issue`."

Do not proceed past pre-flight if either check fails.

### Phase 3 — Resolve source and type

Parse `$ARGUMENTS` for:
- An explicit source keyword: `bug`, `feature`, `selection`, `session`
- A title/description (everything after the keyword)

If both are missing or ambiguous, ask via `AskUserQuestion` (batch both questions):
1. "What is the source? (bug / feature / selection / session)"
2. "What is the issue title or brief description?"

**Per-source behaviour:**

**`bug`** — also collect:
```bash
node --version
npm --version
git log --oneline -5
```
Read `package.json` for relevant deps. Gather reproduction steps, expected vs actual, environment, and any related files via `Grep` and `Glob`.

**`feature`** — user-story shape. Ask for: goal, acceptance criteria. Grep for related existing components.

**`selection`** — treat `$ARGUMENTS` (everything after the keyword) or the pasted/provided text block as the issue seed. Summarize and structure it.

**`session`** — synthesize from the current conversation context: the bug surfaced, the feature discussed, or the TODO identified. State clearly what was synthesized.

### Phase 4 — Gather repo context

```bash
# Check for duplicates first
gh issue list --search "<title keywords>" --limit 10   # GitHub
glab issue list --search "<title keywords>"             # GitLab
```

Read `CLAUDE.md` (if present) for project conventions. Use `Grep` + `Glob` to identify related source files to reference in the issue body.

Report any near-duplicate issues found and ask the user to confirm they still want to proceed.

### Phase 5 — Draft the issue

Select the matching template from `references/`:
- `bug` → `bug-report.md`
- `feature` → `feature-request.md`
- `selection` or `session` → `general-issue.md`

Populate the template:
- Title prefix: `[BUG]` for bugs, `[FEATURE]` for features, none for general
- Fill in all sections from gathered context
- Suggest labels based on content (see host-specific flags in `references/host-commands.md`)

### Phase 6 — Confirmation gate

Display the full drafted issue (title, labels, body) and ask via `AskUserQuestion`:

> "Ready to create this issue on [GitHub/GitLab]?
> - **Create** — create the issue now
> - **Edit** — I'll revise before creating (describe what to change)
> - **Cancel** — do not create"

**NEVER call `gh issue create` or `glab issue create` before the user chooses "Create".** If the user chooses "Edit", revise and show the gate again. If "Cancel", stop and confirm no issue was created.

### Phase 7 — Create the issue

Refer to `references/host-commands.md` for the exact flags per CLI (note: `--body` for GitHub, `--description` for GitLab).

**GitHub:**
```bash
gh issue create \
  --title "<title>" \
  --body "<body>" \
  --label "<label1>,<label2>"
```

**GitLab:**
```bash
glab issue create \
  --title "<title>" \
  --description "<body>" \
  --label "<label1>,<label2>"
```

On failure (auth, missing label, etc.), fall back to the web opener:
```bash
gh issue create --web    # GitHub
glab issue create --web  # GitLab
```

### Phase 8 — Report

Print the issue URL and number. Confirm whether `--web` was used.

## Reference Files

- `references/bug-report.md` — bug issue body skeleton
- `references/feature-request.md` — feature request body skeleton
- `references/general-issue.md` — general/selection/session body skeleton
- `references/host-commands.md` — `gh` vs `glab` command and flag equivalence table
