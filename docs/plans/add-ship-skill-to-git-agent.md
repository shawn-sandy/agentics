# Plan: Add `/ship` Skill to git-agent Plugin

## Context

The user's most common workflow (66+ of 242 sessions) is commit, push, create PR.
Currently this requires triggering `commit-agent` and `pr-agent` separately, often
with friction from missing pre-flight checks (empty commits, wrong branch, no gh
auth). The `/ship` skill consolidates this into a single flow with unified guards.

## Changes

| # | Action | File | Description |
|---|--------|------|-------------|
| 1 | CREATE | `plugins/git-agent/skills/ship/SKILL.md` | New skill: chains commit + push + PR |
| 2 | MODIFY | `plugins/git-agent/README.md` | Add ship to features, usage, and directory tree |
| 3 | MODIFY | `plugins/git-agent/CHANGELOG.md` | Add v1.1.0 entry |
| 4 | MODIFY | `.claude-plugin/marketplace.json` | Bump git-agent 1.0.0 to 1.1.0 |

## Step 1: Create `plugins/git-agent/skills/ship/SKILL.md`

Frontmatter:
- `name: ship`
- `description:` triggers on "ship it", "commit and create a PR", "ship my changes",
  "send it", "land my work". Cross-references commit-agent and pr-agent as alternatives.

Body (8 steps, strict order):

1. **Pre-flight guards** (all checks before any mutation)
   - `git status` -- clean tree? STOP
   - `git branch --show-current` -- detached HEAD? STOP
   - Branch is `main`/`master`? STOP
   - `gh auth status` -- not installed/authed? STOP
2. **Stage changes** -- `git add -A` (trusts `.gitignore`)
3. **Analyze diff and write commit message** -- `git diff --staged`, conventional
   commit format (same rules as commit-agent: 72 chars, imperative, type(scope))
4. **Commit** -- `git commit -m "<message>"`. Hook failure = report verbatim + STOP.
   No `--no-verify`.
5. **Push** -- check upstream with `git rev-parse --abbrev-ref @{u}`. No upstream:
   `git push -u origin <branch>`. Has upstream: `git push`.
6. **Check for existing PR** -- `gh pr view --json url`. If exists, output
   "Pushed to existing PR: <url>" and STOP.
7. **Detect base branch** -- `git symbolic-ref refs/remotes/origin/HEAD`, strip prefix.
   Fall back to `main` then `master`.
8. **Create PR** -- gather content with `git log <base>..HEAD --oneline` and
   `git diff <base>...HEAD --stat`. Run `gh pr create --title "..." --body "..."`.
   Output PR URL and STOP.

Hard STOP footer matching existing skills.

Key design decision: push happens BEFORE the existing-PR check (step 5 before step 6).
This ensures the new commit always reaches the remote, whether or not a PR exists.

## Step 2: Update `plugins/git-agent/README.md`

- Add `ship` to the Features list
- Add `### ship` usage section with trigger phrases and numbered steps
- Add `ship/` directory to the Plugin Structure tree

## Step 3: Update `plugins/git-agent/CHANGELOG.md`

Add above v1.0.0:
```
## v1.1.0 -- Add ship skill

- New skill: `ship` -- chains commit + push + PR into a single flow
- Unified pre-flight checks before any mutations
- Pushes to existing PR if one already exists on the branch
```

## Step 4: Bump version in `.claude-plugin/marketplace.json`

Change git-agent version from `"1.0.0"` to `"1.1.0"` (MINOR: new skill, backward
compatible). Add `"ship"` to the tags array.

## Verification

1. Load the plugin: `claude --plugin-dir ./plugins/git-agent`
2. Confirm `ship` appears in the skills list
3. Test on a feature branch with uncommitted changes -- should commit, push, and
   create a PR in one go
4. Test on a clean tree -- should output "Nothing to ship" and stop
5. Test on a branch with an existing PR -- should commit, push, then report the
   existing PR URL

## Next Steps (Out of Scope)

- Draft PR support via trigger phrase ("ship as draft")
- `--dry-run` mode showing what would happen without mutating
- Hook to auto-run formatting/lint before the commit step
