---
status: completed
type: artifact
created: 2026-04-14
---

# Ship-Autonomous Skill

## Context

The user wants an end-to-end autonomous shipping workflow: uncommitted-work detection → feature branch → commit → PR → CI polling → automatic failure-fix loop → request review. The existing `git-agent` plugin already owns the branch/commit/PR primitives (each a single-purpose skill with strict STOP contracts), but no skill polls CI or attempts autofix. This plan adds that missing layer **without** mutating the existing single-shot skills — it composes them. Also adds a PostToolUse hook warning on uncommitted plan files, orthogonal to `plan-interview:plan-hygiene` (which handles random-named files, not commit status).

## Objective

Create `/Users/shawnsandy/devbox/agentics/.claude/skills/ship-autonomous/SKILL.md` that orchestrates the existing git-agent skills, adds a bounded CI-polling autofix loop, and pairs with a PostToolUse hook in `.claude/settings.json`. Stress-test on a throwaway branch.

## Design Decisions (confirmed)

1. **Orchestration, not reimplementation** — invoke `branch-agent`, `commit-agent`, `pr-agent` via the Skill tool. Reuses battle-tested base-detection, merged-PR handling (git-agent v3.3.2), and pre-commit STOP semantics.
2. **Strict autofix envelope** — max 3 fix-push cycles. Allow-listed fix classes only: `eslint --fix` auto-applicable rules, TS errors fixable without type loosening, peer-dep bumps matching existing lockfile patterns. Any other failure class → escalate to user.
3. **Location per request** — `.claude/skills/ship-autonomous/` (matches existing `.claude/skills/validate-plugin/` precedent). Not packaged as a plugin.
4. **Hook lives in `.claude/settings.json`** — extends the existing `PostToolUse` array rather than creating a plugin-level `hooks.json`.

## Files to Create / Modify

| Path | Action | Purpose |
|---|---|---|
| `.claude/skills/ship-autonomous/SKILL.md` | **create** | The orchestrating skill |
| `.claude/settings.json` | **modify** | Append plan-file warning to `PostToolUse` |
| `docs/plans/piped-wibbling-stroustrup.md` | **rename-on-commit** | Rename to descriptive name (e.g. `ship-autonomous-skill.md`) per `.claude/rules/plan-hygiene.md` |

## Steps

1. **Write `SKILL.md` frontmatter**
   - `name: ship-autonomous`
   - `description: Use when the user asks to autonomously ship, ship and watch CI, auto-fix CI failures, or ship it and fix what breaks.`
   - `allowed-tools: Bash(git *), Bash(gh *), Bash(npm *), Bash(pnpm *), Bash(yarn *), Bash(jq *), Skill, Read, Edit, Grep, Glob, TodoWrite`
   - *Why `Skill`:* enables delegation to `git-agent:branch-agent`, `git-agent:commit-agent`, `git-agent:pr-agent`.

2. **Body — Step 1: Pre-flight**
   - `git status --porcelain` → if clean, STOP with "Nothing to ship."
   - `git ls-files --others --modified --exclude-standard docs/plans/` → if any, output the list and ask user whether to include them (AskUserQuestion: include / stash / abort). Reuses pattern from `ship` step 1.
   - Verify `gh auth status` succeeds.

3. **Body — Step 2: Branch** (delegate)
   - If current branch is `main`/`master`/default: invoke the **`git-agent:branch-agent`** skill with no arguments — it auto-generates `<type>/<scope>-<desc>` from the working tree, branches from `origin/HEAD` with `--no-track`.
   - Else: stay on current branch (user already has one).

4. **Body — Step 3: Commit** (delegate)
   - Invoke **`git-agent:commit-agent`**. Honors its STOP-on-pre-commit-hook-failure contract.
   - *Why delegate:* avoids duplicating the conventional-commit scope-selection logic already in `commit-agent`.

5. **Body — Step 4: PR** (delegate)
   - Invoke **`git-agent:pr-agent`**. Handles merged-PR false-positive per v3.3.2, generates Summary/Changes body from `git log base..HEAD`, pushes if no upstream, opens PR.
   - Capture the PR URL from pr-agent's output (parse last line containing `https://github.com/.../pull/`).

6. **Body — Step 5: Poll CI**
   - Run `gh pr checks --watch --fail-fast=false <pr-url>` (blocks until all checks finalize).
   - Parse final `gh pr checks <pr-url> --json name,state,conclusion` JSON.

7. **Body — Step 6: Autofix loop (max 3 iterations)**
   - Track iteration counter via TodoWrite. For each failing check:
     - **Classify failure** by fetching logs: `gh run view <run-id> --log-failed`.
     - **Allow-listed classes only:**
       - `lint` → run project's `lint --fix` command (detect from `package.json` scripts); if no such script, escalate.
       - `typecheck` → read reported TS errors, apply minimal fixes (add missing imports, narrow types *without* `any`/`as unknown`); never loosen existing types.
       - `peer-deps` → run package manager's resolution command (`npm install` / `pnpm install`) and commit lockfile only if diff is lockfile-only.
     - **Disallowed:** test logic failures, build logic errors, runtime errors, anything else → escalate to user with the failing check name + log excerpt and STOP.
   - After each fix: stage → `git-agent:commit-agent` (new commit, not amend) → `git push` → re-poll checks.
   - Hard cap: **3 iterations**. On cap-hit: comment on PR summarizing attempts, stop, escalate.

8. **Body — Step 7: Request review**
   - When all checks green: `gh pr ready` (if draft) + `gh pr edit --add-reviewer @me` replaced by `gh pr comment --body "CI green, ready for review"`. Output PR URL and STOP.
   - *Why just a comment:* avoid guessing reviewers; repo may not have CODEOWNERS. Let user decide.

9. **Body — Terminal STOP clause** — copy the `ship` skill's pattern: "STOP here. Do not analyze code, suggest follow-ups, or mutate further."

10. **Add PostToolUse hook to `.claude/settings.json`**
    - Append a second entry to the existing `PostToolUse` array, matcher `Write|Edit`:
      ```json
      {
        "type": "command",
        "command": "test -z \"$(git status --porcelain docs/plans/ 2>/dev/null)\" || echo 'WARNING: Uncommitted plan files in docs/plans/ — commit alongside related changes (see .claude/rules/plan-hygiene.md)'"
      }
      ```
    - *Why separate entry:* keeps marketplace-validator hook's exit semantics independent.

11. **Rename plan file before commit**
    - Per `.claude/rules/plan-hygiene.md`, `piped-wibbling-stroustrup.md` is a random-named plan. Rename with `git mv` to `ship-autonomous-skill.md` before committing.

## Critical Files Referenced (for orchestration)

- `kit/plugins/git-agent/skills/branch-agent/SKILL.md` — delegated for Step 2
- `kit/plugins/git-agent/skills/commit-agent/SKILL.md` — delegated for Step 3 + autofix commits
- `kit/plugins/git-agent/skills/pr-agent/SKILL.md` — delegated for Step 4
- `kit/plugins/git-agent/skills/ship/SKILL.md` — pattern reference for pre-flight guards & STOP clause
- `kit/plugins/plan-interview/hooks.json` — PostToolUse hook shape reference
- `.claude/settings.json` — existing hook array to extend
- `.claude/rules/plan-hygiene.md` — naming rule this plan must satisfy before commit

## Verification (stress test on throwaway branch)

After approval + implementation, run this end-to-end:

1. `git checkout main && git pull` — establish clean baseline.
2. Create trivial change: `echo "" >> README.md` (no-op trailing newline).
3. Invoke the skill: tell Claude "ship this autonomously."
4. **Expected flow:**
   - branch-agent creates `chore/readme-trailing-newline` from `origin/HEAD`.
   - commit-agent writes `chore: add trailing newline to README`.
   - pr-agent opens PR, returns URL.
   - `gh pr checks --watch` runs to completion.
   - Since no CI failure is expected on a whitespace change, autofix loop should NOT fire; final output is "CI green, ready for review."
5. **Failure-path probe:** on the same branch, introduce a deliberate lint violation (e.g. an unused var in any `.md` lint-checked file, or a JSON syntax error the marketplace-validator hook will flag). Re-push. Confirm autofix loop detects → fixes → commits → re-polls → reaches green within 3 iterations.
6. **Cleanup:** `gh pr close --delete-branch <url>` and `git checkout main && git branch -D chore/readme-trailing-newline` if still local.
7. **Hook verification:** create `docs/plans/test-uncommitted.md`, then run any `Write`/`Edit` elsewhere. Confirm the warning message appears in the hook output. Delete the test plan.

## Unresolved Questions

- Should the autofix loop push to the PR as separate commits or squash-amend? **Current plan: separate commits** (matches commit-agent's "never amend" stance and preserves audit trail). Confirm during implementation if user prefers amend-squash at merge time.
