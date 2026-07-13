---
name: create-issue
description: "Drafts and opens a GitHub or GitLab issue from any context source. Detects host from git remote and confirms before creating. Use when the user asks to file, open, or create an issue or ticket."
allowed-tools: Bash(gh *), Bash(glab *), Bash(git *), Bash(node *), Bash(npm *), AskUserQuestion, Read, Grep, Glob, ToolSearch, ExitPlanMode
model: sonnet
argument-hint: "[bug|feature|selection|session|plan] [title, description, or plan path]"
---

# Create Issue

Open a GitHub or GitLab issue from any context. Always confirms before creating — no issue is ever created without your approval.

## Overview

Ingests context from five sources (selection, session, bug, feature, plan), detects the git host, drafts a structured issue body, shows a confirmation gate, then calls `gh` or `glab` to create the issue.

## Workflow

### Phase 0 — Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** — skip this step entirely when not in plan mode. When calling: use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

### Phase 1 — Detect host

Run:
```bash
git remote get-url origin
```

- URL contains `github.com` → host is **GitHub**, CLI is `gh`
- URL contains `gitlab.com` or `gitlab.` (self-hosted pattern) → host is **GitLab**, CLI is `glab`
- URL is absent, unrecognizable, or any other host (Bitbucket, Azure DevOps, Gitea, etc.) → use `AskUserQuestion` to ask: "Your remote appears to be on an unrecognized host (`<url>`). Which issue tracker should I use? (GitHub / GitLab / Other — I'll stop if Other)"

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
- "Run `! gh auth login` to authenticate with GitHub, then retry `/git-agent:create-issue`."
- "Run `! glab auth login` to authenticate with GitLab, then retry `/git-agent:create-issue`."

Do not proceed past pre-flight if either check fails.

### Phase 3 — Resolve source and type

Two activation paths:

- **Command:** `/git-agent:create-issue [source] [title or description]` — `$ARGUMENTS` holds the source and title.
- **Model (ambient):** activates when the user asks to file, open, or create an issue or ticket. `$ARGUMENTS` is empty; derive the equivalent argument text from the triggering message and recent conversation — the source keyword implied by intent (a reported defect → `bug`, a requested capability → `feature`, pasted code → `selection`, "this session" → `session`, a named plan file → `plan`) and the title/description the user supplied (e.g. "file a bug: login crashes on submit" yields `bug login crashes on submit`). Then apply the same parsing rules below to the derived text. Only fall back to `AskUserQuestion` if the triggering message gives neither a usable source nor title.

Before any other parsing, strip `--no-open` from `$ARGUMENTS` (or the derived text) to avoid it appearing in the issue title or description:
```bash
ARGS="${ARGUMENTS/--no-open/}"
ARGS="${ARGS//  / }"  # collapse any double spaces left behind
ARGS="${ARGS## }"     # trim leading space
ARGS="${ARGS%% }"     # trim trailing space
```
Use `$ARGS` (not `$ARGUMENTS`) for all subsequent argument parsing in this phase.

Parse `$ARGS` for:
- An explicit source keyword: `bug`, `feature`, `selection`, `session`, `plan`
- A title/description (everything after the keyword)
- A token ending in `.md` or `.html` implies the `plan` source even without the keyword

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

**`plan`** — the remaining argument is a plan file path (a markdown plan spec, or a rendered plan HTML whose sibling `.md` spec is the real source — always prefer the `.md`). Resolve it as given, then by basename under the configured `plansDirectory` or `docs/plans/`. Read the plan and map:
- Plan title (`# Plan: …` heading or frontmatter) → issue title
- Objective → Summary
- Steps → a `- [ ]` task checklist (action text only — drop the *Why*/*Verify* detail)
- Acceptance Criteria → carried over as checklist items
- Frontmatter `type:` → label hint (`fix` → `bug`, `feature` → `enhancement`, `docs` → `documentation`, else `chore`)
- The plan file's repo-relative path → cited in the issue body so the issue links back to the plan

If the path cannot be read anywhere, report where you looked and stop — never invent plan content.

### Phase 4 — Gather repo context

```bash
# Check for duplicates first
gh issue list --search "<title keywords>" --limit 10        # GitHub
glab issue list --search "<title keywords>" --per-page 10   # GitLab
```

Read `CLAUDE.md` (if present) for project conventions. Use `Grep` + `Glob` to identify related source files to reference in the issue body.

Report any near-duplicate issues found and ask the user to confirm they still want to proceed.

### Phase 5 — Draft the issue

Select the matching template from `references/`:
- `bug` → `bug-report.md`
- `feature` → `feature-request.md`
- `selection` or `session` → `general-issue.md`
- `plan` → `plan-issue.md`

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

When the `--web` fallback is used, skip the post-creation browser open below — the user is already in the browser.

**After successful CLI creation, open the issue in the browser:**

1. Parse the issue number/ID from the CLI output. For GitHub, `gh issue create` returns the issue URL (e.g. `https://github.com/owner/repo/issues/42`); extract the trailing integer. For GitLab, `glab issue create` returns a similar URL.

2. Check whether `--no-open` appears in `$ARGUMENTS`:
   ```bash
   echo "$ARGUMENTS" | grep -q -- '--no-open'
   ```
   If `--no-open` is present, skip the browser open and proceed directly to Phase 8.

3. If `--no-open` is absent, open the issue in the browser. Wrap the call in error handling — a failure to open the browser is a non-fatal warning; it must not mask the fact that the issue was created:
   ```bash
   # GitHub
   gh issue view <number> --web 2>/dev/null \
     || echo "Warning: could not open browser — open the issue manually at the URL above."

   # GitLab
   glab issue view <id> --web 2>/dev/null \
     || echo "Warning: could not open browser — open the issue manually at the URL above."
   ```

### Phase 8 — Report

Print the issue URL and number. Then indicate what happened with the browser:

- **Browser opened:** "Opened issue #\<number\> in your browser."
- **`--no-open` was passed:** "Browser open suppressed (`--no-open`). Issue URL: \<url\>"
- **Browser open failed:** "Issue created at \<url\> — browser could not be opened (see warning above)."

## Reference Files

- `references/bug-report.md` — bug issue body skeleton
- `references/feature-request.md` — feature request body skeleton
- `references/general-issue.md` — general/selection/session body skeleton
- `references/plan-issue.md` — plan-to-issue body skeleton (objective, step checklist, acceptance criteria)
- `references/host-commands.md` — `gh` vs `glab` command and flag equivalence table
