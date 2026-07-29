---
description: Scan recent git history or a codebase path for shareable code, scrub for secrets, and draft code-share prompts
argument-hint: "[--days=7] [--base=main] [--max=20] | --codebase <path>"
allowed-tools: Skill, AskUserQuestion
---

# digest

Discover what's worth sharing from your code.

## Usage

```
/social-media-tools:digest                          # scan last 7 days of git history
/social-media-tools:digest --days=14               # scan last 14 days
/social-media-tools:digest --base=develop          # diff against a different base branch
/social-media-tools:digest --codebase src/auth/    # scan a codebase path instead of git history
/social-media-tools:digest --codebase .            # scan entire working directory
```

## Workflow

### Step 1 — Run share-scan

Invoke the `share-scan` skill with `$ARGUMENTS`:

```
Skill(skill: "social-media-tools:share-scan", args: "$ARGUMENTS")
```

The skill handles all candidate collection, scoring, security scrubbing, and the interactive review gate. Wait for it to complete and write the digest.

### Step 2 — Report and offer next step

After the skill finishes, confirm the digest path to the user. Then ask with `AskUserQuestion`:

> "The digest is ready. Want to generate a post from one of these entries?"

Options:
- "Yes — I'll copy a `code-share prompt` from the digest and run it"  
- "No — I'm done for now"

Do not invoke `share-code` automatically regardless of the user's answer. The user must trigger the `share-code` skill themselves by pasting a `code-share prompt` from the digest into the chat.
