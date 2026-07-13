# branch-agent: always exit plan mode on entry

## Context

The `branch-agent` skill (`kit/plugins/git-agent/skills/branch-agent/SKILL.md`) creates a git branch via `git checkout -b` — a mutation. When Claude is in plan mode, all non-readonly tools (including `Bash(git *)`) are blocked, so invoking branch-agent during planning either fails or stalls. The user's global guidance also states: *"ALWAYS execute git operations directly without entering plan mode (unless asked)."*

The fix: have the skill always call `ExitPlanMode` as its first action, so it can self-bootstrap out of plan mode and proceed with branch creation. Because the skill has `disable-model-invocation: true`, it only runs when the user explicitly asks for it — exiting plan mode on their behalf is a safe default.

## Objective

Update `kit/plugins/git-agent/skills/branch-agent/SKILL.md` so it always calls `ExitPlanMode` at the start of the workflow, before the existing guards.

## File to modify

- [kit/plugins/git-agent/skills/branch-agent/SKILL.md](kit/plugins/git-agent/skills/branch-agent/SKILL.md)

## Steps

1. **Add `ExitPlanMode` to `allowed-tools`** — append it to the existing list so the user is not prompted mid-run.

   ```yaml
   allowed-tools:
     - Bash(git *)
     - ToolSearch
     - AskUserQuestion
     - ExitPlanMode
   ```

   *Why:* without this, the harness will prompt for permission the first time the skill calls the tool, breaking the "no further questions" flow.

2. **Insert a new "Step 0: Exit Plan Mode" section** before the current `## Step 1: Guards`.

   Body:
   > Always call `ExitPlanMode` immediately when this skill is invoked, before any other action. Branch creation is a git mutation and cannot proceed inside plan mode. This skill is explicit-invocation only (`disable-model-invocation: true`), so the user has already opted in to taking action.

   *Why:* makes the skill self-sufficient — it works whether the user invoked it from plan mode or not.

3. **Update the opening paragraph** (currently "Follow these steps in strict order. **STOP immediately after step 6.**") to reference the new step count if needed. The existing step numbering (Steps 1–6) stays the same; only Step 0 is added in front, so the "STOP after step 6" wording remains accurate.

4. **Bump the plugin version** in `.claude-plugin/marketplace.json` for `git-agent` (PATCH bump — behavior change but no API/contract change to the skill's invocation surface). Add a one-line entry to `kit/plugins/git-agent/CHANGELOG.md`.

   *Why:* repo convention requires version + changelog updates for any plugin behavior change (`.claude/rules/marketplace.md`).

## Verification

1. Open a session in plan mode (`/plan` or shift-tab).
2. Invoke the skill: ask Claude to "create a branch called test/exit-plan-check".
3. Confirm the skill calls `ExitPlanMode` first, then proceeds through Steps 1–6 and creates the branch from `origin/<default>`.
4. Run `git branch --show-current` to confirm the branch was created.
5. Clean up: `git checkout main && git branch -D test/exit-plan-check`.

## Out of scope (Next Steps)

- Applying the same pattern to `commit-agent`, `pr-agent`, and `ship` — they have the identical issue but were not part of this request.
- Reviewing whether `ExitPlanMode` should also be added to other write-side skills in the repo.

## Unresolved Questions

- Should `ExitPlanMode` be called unconditionally, or only when plan mode is actually active? The skill cannot detect plan-mode state directly from a Bash check, and calling `ExitPlanMode` when not in plan mode is a no-op, so unconditional is simpler and safe. **Assumed: unconditional.**
