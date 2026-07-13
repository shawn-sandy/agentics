---
title: "Plugin Version Conflict Guard"
date: 2026-05-28
status: implemented
pr: 157
tags: [versioning, ci, plugins, version-guard]
summary: "Three-layer automation (Claude Code hook, pre-push hook, GitHub Actions) to prevent version conflicts on concurrent plugin PRs."
---

# Context

Plugin PRs frequently conflict on the `version` field inside `.claude-plugin/marketplace.json`. Because all 18 plugins share a single file, two PRs created off the same `main` can each bump the same plugin's version to the same number — or a PR can land on a stale version after another PR has already merged a bump. No automated gate currently blocks a bad merge; enforcement is entirely manual.

**Root cause:** Single shared `marketplace.json` + manual version management + no CI guard = race condition on every concurrent plugin PR.

---

## Current State (what exists)

| Mechanism | What it does | Gap |
|---|---|---|
| Post-tool hook (`.claude/settings.json`) | Validates `marketplace.json` JSON syntax after Write/Edit | Doesn't check version values |
| Plugin validator skill (`agentic-plugin-dev`) | M06 flags `version` in `plugin.json` — manual invoke only | Not triggered on PR |
| GitHub Actions (`claude.yml`, `claude-code-review.yml`) | Claude Code reviews on PRs | No version conflict logic |
| PR template / CONTRIBUTING.md | Manual checklist | **Outdated** — still references old "version in both files" rule |

---

## Options

### Option A — GitHub Actions PR Version Guard *(recommended)*

Add `.github/workflows/version-guard.yml` that runs on every PR targeting `main`.

**Logic:**
1. Identify which plugin directories changed (`git diff --name-only origin/main...HEAD`)
2. For each changed plugin, read the current `version` in `marketplace.json` on `main` and on the PR branch
3. **Fail** if: version on the PR branch equals version on `main` (no bump despite changes)
4. **Fail** if: version on the PR branch is lower than version on `main` (stale base, another PR already merged a bump for this plugin)

**Implementation:** ~50-line bash script + workflow YAML. Uses `jq` (already available in GitHub Actions ubuntu runners).

**Files to create/modify:**
- `.github/workflows/version-guard.yml` (new)

**Pros:** Blocks merge at GitHub level, works for all contributors, no local setup needed.  
**Cons:** Doesn't catch the conflict until the PR is already open; requires a re-push to fix.

---

### Option B — Pre-push Git Hook

Add a script at `scripts/check-version-bump.sh` and document it in `CONTRIBUTING.md`. Contributors install it via `cp scripts/check-version-bump.sh .git/hooks/pre-push && chmod +x .git/hooks/pre-push` (or via a `make setup` target).

**Logic:** Same as Option A but runs locally before `git push`, catching the problem before the PR is even created. Compares local branch version against `origin/main`.

**Files to create/modify:**
- `scripts/check-version-bump.sh` (new)
- `CONTRIBUTING.md` — add setup instruction

**Pros:** Catches conflicts before PR creation, gives immediate feedback.  
**Cons:** Optional — contributors can skip hooks (`--no-verify`) or forget to install them.

---

### Option C — Fix PR Template + CONTRIBUTING.md (Documentation Fix Only)

Update outdated documentation so contributors know the correct rule:
- `CONTRIBUTING.md` lines 24–26, 42–58: Remove "version must match `plugin.json`"; replace with "version is set **only** in `marketplace.json`; must be higher than current `main`"
- `.github/pull_request_template.md`: Remove the stale `plugin.json` version checklist item; add "version in `marketplace.json` is higher than the value on `main`"

**Files to modify:**
- `CONTRIBUTING.md`
- `.github/pull_request_template.md`

**Pros:** Zero-cost, immediately improves contributor experience.  
**Cons:** Relies entirely on human discipline — doesn't block bad merges.

---

### Option D — Claude Code Hook Enhancement

Extend the existing post-tool hook in `.claude/settings.json` to also check, after any Write/Edit to `marketplace.json`, whether the modified plugin version is greater than the version on `main`.

**Script addition:**
```bash
# After marketplace.json edit, compare changed plugin versions against origin/main
git fetch origin main --quiet 2>/dev/null
git show origin/main:.claude-plugin/marketplace.json | jq -r '.plugins[] | "\(.name) \(.version)"' > /tmp/main-versions.txt
# compare against local versions and warn if any are not bumped
```

**Files to modify:**
- `.claude/settings.json` — extend the `marketplace.json` write hook

**Pros:** Real-time warning as Claude edits the file, integrated into existing workflow.  
**Cons:** Only helps when Claude Code is doing the editing, not human contributors. Requires network access at edit time.

---

## Chosen Implementation: A + B + D

Three automated layers, each catching problems at a different stage:

| Layer | When | Files |
|---|---|---|
| D — Claude Code hook | At edit time (real-time) | `.claude/settings.json` |
| B — Pre-push git hook | Before PR is created | `scripts/check-version-bump.sh` |
| A — GitHub Actions | Before merge | `.github/workflows/version-guard.yml` |

Option C (docs fix) is included as part of every commit — CONTRIBUTING.md and PR template should be updated alongside the tooling.

### Portability — Using in Other Projects

The version-guard logic should be extracted into a **standalone, parameterized script** so it works in any project with a JSON registry file (not just `marketplace.json`):

```bash
# scripts/check-version-bump.sh <registry-file> <plugins-jq-path> <base-branch>
# Example for this repo:
#   ./scripts/check-version-bump.sh .claude-plugin/marketplace.json '.plugins[]' main
# Example for another project:
#   ./scripts/check-version-bump.sh package.json '.workspaces[]' main
```

Parameters:
- `REGISTRY_FILE` — path to the JSON file tracking versions (default: `.claude-plugin/marketplace.json`)
- `JQ_PATH` — `jq` expression to iterate plugin/package entries (default: `.plugins[]`)
- `BASE_BRANCH` — branch to compare against (default: `main` or `origin/main`)

The GitHub Actions workflow calls this same script, so there's one source of truth. Other repos copy `scripts/check-version-bump.sh` and set environment variables or `.version-guard.json` config to point at their registry file.

---

## Verification

After implementation:
1. Create a test branch that modifies a plugin without bumping its version → PR should fail the `version-guard` workflow
2. Create a test branch with a correct version bump → PR should pass
3. Create two PRs that both bump the same plugin to the same version → the second to merge should fail with "version already exists on main"
4. Check that `CONTRIBUTING.md` and PR template no longer reference `plugin.json` version fields
