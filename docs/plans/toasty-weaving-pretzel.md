# Plan: Create git-agent Plugin with commit-agent and pr-agent Skills

## Context

Usage insights identified a recurring friction pattern: the plan→implement→commit→PR pipeline spans multiple sessions, and Claude sometimes over-broadens scope after completing a commit (e.g., autonomously starting test coverage analysis). Two new skills will encode the exact workflow the user wants with hard STOP boundaries.

## New Plugin: `plugins/git-agent/`

Single plugin containing two skills. New plugin keeps git automation isolated from dev-tools.

## Files to Create

### 1. `plugins/git-agent/.claude-plugin/plugin.json`
```json
{
  "name": "git-agent",
  "version": "1.0.0",
  "description": "Automated git commit and PR creation — stage, commit with conventional messages, and create PRs in one shot",
  "author": { "name": "Agentics Project" },
  "license": "MIT",
  "keywords": ["git", "commit", "pr", "pull-request", "conventional-commits", "automation"],
  "homepage": "https://github.com/shawn-sandy/agentics/tree/main/plugins/git-agent",
  "repository": "https://github.com/shawn-sandy/agentics"
}
```

### 2. `plugins/git-agent/skills/commit-agent/SKILL.md`

Frontmatter activates on: "commit my changes", "stage and commit", "commit all changes", "commit everything"

Steps (rigid order, hard STOP after step 4):
1. **Guard**: `git status` — if clean, stop. If detached HEAD (`git branch --show-current` returns empty), print guard and stop.
2. `git add -A` — stage all changes (trusts `.gitignore`; user is responsible for gitignore correctness)
3. `git diff --staged` — analyze diff, write conventional commit message (`<type>(<scope>): <description>`, ≤72 chars)
   - Scope tiebreaker: use the most-changed directory; omit scope entirely if changes span >2 top-level directories
4. `git commit -m "<message>"` — output hash + message; if a pre-commit hook fails, report the hook output and **STOP** (do not retry or use `--no-verify`)
5. Include 1-line undo note in output: "To undo: `git reset HEAD~1`"

**STOP immediately after step 4. Do not run tests, analyze coverage, or take any further action.**

### 3. `plugins/git-agent/skills/pr-agent/SKILL.md`

Frontmatter activates on: "create a PR", "open a pull request", "make a PR", "push and create PR"
Frontmatter explicitly states: Does NOT enter plan mode.

Steps (rigid order, hard STOP after step 4):
1. **Guards**:
   - Detached HEAD: `git branch --show-current` returns empty → print guard and stop
   - On main/master: print guard and stop
   - `gh` CLI: run `gh auth status` → if not installed or not authenticated, print instructions and stop
2. **Detect base branch**: `git symbolic-ref refs/remotes/origin/HEAD` → strip `refs/remotes/origin/` prefix. Fall back to `main`, then `master`. Run `git log <base>..HEAD --oneline` + `git diff <base>...HEAD --stat`.
3. **Check for existing PR**: run `gh pr view --json url` — if PR exists, output the URL and **STOP** (do not create a duplicate)
4. **Push if needed**: check `git status` for tracking ref; if absent, run `git push -u origin <branch>`
5. `gh pr create --title "<title>" --body "..."` — output PR URL, **STOP**

**STOP immediately after step 5. Do not analyze code, run tests, or take any further action.**

### 4. `plugins/git-agent/CHANGELOG.md`
Initial entry: `v1.0.0 — Initial release with commit-agent and pr-agent skills`

### 5. `plugins/git-agent/README.md`
Overview, features, installation, usage examples, directory tree.

## Files to Modify

### 6. `.claude-plugin/marketplace.json`
Add entry after `code-test-suggestion`:
```json
{
  "name": "git-agent",
  "source": "./plugins/git-agent",
  "version": "1.0.0",
  "description": "Automated git commit and PR creation — stage, commit with conventional messages, and create PRs in one shot",
  "category": "development",
  "tags": ["git", "commit", "pr", "pull-request", "conventional-commits", "automation"]
}
```

## Implementation Order

1. Create directory structure
2. Write `plugin.json`
3. Write `commit-agent/SKILL.md`
4. Write `pr-agent/SKILL.md`
5. Write `CHANGELOG.md` and `README.md`
6. Update `marketplace.json`
7. Verify version sync: both `plugin.json` and `marketplace.json` must show `1.0.0`
8. Commit with: `feat(plugins/git-agent): add commit-agent and pr-agent skills — v1.0.0`

## Verification

- `grep -r '"version"' plugins/git-agent/.claude-plugin/ .claude-plugin/marketplace.json` — confirm both show `1.0.0`
- Load locally: `claude --plugin-dir ~/devbox/agentics/plugins/git-agent`
- Trigger commit-agent by saying "commit my changes" in a session with staged changes
- Trigger pr-agent by saying "create a PR" on a feature branch

## Open Questions

None — all risks from the plan interview have been resolved above.

## Interview Summary

### Open Risks Resolved

| Risk | Resolution |
|------|------------|
| Detached HEAD state | Guard added to step 1 of both skills |
| `gh` CLI not available | Upfront `gh auth status` check in pr-agent step 1 |
| PR already exists | `gh pr view` check in pr-agent step 3 |
| Base branch assumption (`main`) | Auto-detect via `git symbolic-ref` with fallback chain |
| Multi-file diff → ambiguous scope | Tiebreaker rule added: largest directory; omit if >2 dirs |
| No undo path | 1-line `git reset HEAD~1` note added to commit-agent output |
| Pre-commit hook failure | Report error and stop; no `--no-verify` bypass |
