---
status: in-progress
created: 2026-03-12
---

# Plan: Make ship skill GitLab-compatible

## Context

The ship skill currently hardcodes GitHub CLI (`gh`) commands. Users with GitLab
remotes need equivalent support via `glab` CLI. Three steps reference `gh` directly;
the rest are pure git and already platform-agnostic.

## Changes

**File:** `plugins/git-agent/skills/ship/SKILL.md`

### 1. Add platform detection to Step 1 (Pre-flight Guards)

Replace the "GitHub CLI" guard with a two-phase check:

- Run `git remote get-url origin` to detect platform:
  - Contains `github.com` → GitHub, use `gh`
  - Contains `gitlab.com` or `gitlab` → GitLab, use `glab`
  - If unclear, try `gh --version` then `glab --version` — use whichever is installed
- Then run the appropriate auth check (`gh auth status` or `glab auth status`)
- Include install URLs for both CLIs in failure messages

### 2. Update Step 6 (Check for Existing PR/MR)

Add GitLab variant:
- GitHub: `gh pr view --json url`
- GitLab: `glab mr view --output json`
- Adjust output message: "Pushed to existing PR/MR: <url>"

### 3. Update Step 8 (Create Pull/Merge Request)

Add GitLab variant:
- GitHub: `gh pr create --title "..." --body "..."`
- GitLab: `glab mr create --title "..." --description "..."`
- Note: GitLab uses `--description` not `--body`

### 4. Update frontmatter description

Add "merge request" and "MR" as trigger terms alongside "PR" and "pull request".

### 5. Update summary line (line 9)

Change "pull request" to "pull/merge request".

## Files Modified

- `plugins/git-agent/skills/ship/SKILL.md` — only file changed

## Verification

1. Read the updated SKILL.md and confirm both `gh` and `glab` commands appear
2. Confirm steps 2-5 and 7 remain unchanged (pure git, platform-agnostic)
3. Load plugin: `claude --plugin-dir ./plugins/git-agent`

## Next Steps (Out of Scope)

- Add GitLab support to `pr-agent` skill as well
- Support Bitbucket via its CLI
- Add platform preference to a config file to skip auto-detection
