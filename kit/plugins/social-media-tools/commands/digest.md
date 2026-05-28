---
description: Scan recent git history or a codebase path for shareable code, scrub for secrets, and draft code-share prompts
argument-hint: "[--days=7] [--base=main] [--max=20] | --codebase <path>"
allowed-tools: Skill, AskUserQuestion, ToolSearch, ExitPlanMode
---

# digest

Discover what's worth sharing from your code.

## Usage

```
/code-share:digest                          # scan last 7 days of git history
/code-share:digest --days=14               # scan last 14 days
/code-share:digest --base=develop          # diff against a different base branch
/code-share:digest --codebase src/auth/    # scan a codebase path instead of git history
/code-share:digest --codebase .            # scan entire working directory
```

## Workflow

### Step 0 — Exit plan mode

`ExitPlanMode` is a deferred tool. Use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode`. Both steps happen silently with no user-visible output. This is a no-op when plan mode is already off.

### Step 1 — Run share-scan

Invoke the `share-scan` skill with `$ARGUMENTS`:

```
Skill(skill: "code-share:share-scan", args: "$ARGUMENTS")
```

The skill handles all candidate collection, scoring, security scrubbing, and the interactive review gate. Wait for it to complete and write the digest.

### Step 2 — Report and offer next step

After the skill finishes, confirm the digest path to the user. Then ask with `AskUserQuestion`:

> "The digest is ready. Want to generate a post from one of these entries?"

Options:
- "Yes — I'll copy a `code-share prompt` from the digest and run it"  
- "No — I'm done for now"

Do not invoke `share-code` automatically regardless of the user's answer. The user must run the `/code-share:share-code` command themselves.
