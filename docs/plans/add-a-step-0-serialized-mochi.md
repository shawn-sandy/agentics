# Add `Step 0: Exit Plan Mode` to remaining git-agent skills

## Context

The `git-agent` plugin currently has four skills — `branch-agent`,
`commit-agent`, `pr-agent`, and `ship`. Only `branch-agent` (v3.3.1) calls
`ExitPlanMode` as its Step 0 so it can self-bootstrap out of plan mode before
running git mutations. The other three skills still rely on the caller to
ensure plan mode is off.

The user has asked for the same Step 0 pattern to be extended to the remaining
three skills so every git-mutating skill in the plugin self-corrects plan-mode
state on entry, mirroring `branch-agent`.

### Pattern reference (branch-agent)

```markdown
## Step 0: Exit Plan Mode

Always call `ExitPlanMode` immediately when this skill is invoked, before any
other action. <brief rationale specific to the skill>.
```

And `ExitPlanMode` is added to `allowed-tools` so no mid-run permission
prompt fires.

### Note on auto-activation

`branch-agent` sets `disable-model-invocation: true` — it is explicit-invocation
only, so the Step 0 reasoning ("the user has already opted in") is airtight.
The other three skills **do not** set that flag; they auto-activate whenever
intent matches their `description`. Adding Step 0 there means plan mode can be
exited automatically on a matched skill. This is an intentional behavior change
consistent with v3.3.1's direction. No extra scope (e.g. adding
`disable-model-invocation`) — stay within the request.

## Objective

Extend the existing `branch-agent` Step 0 pattern to `commit-agent`,
`pr-agent`, and `ship` so every git-mutating skill in the plugin exits plan
mode on entry.

## Files to Modify

- `kit/plugins/git-agent/skills/commit-agent/SKILL.md`
- `kit/plugins/git-agent/skills/pr-agent/SKILL.md`
- `kit/plugins/git-agent/skills/ship/SKILL.md`
- `kit/plugins/git-agent/CHANGELOG.md`
- `.claude-plugin/marketplace.json` (version bump `3.3.2` → `3.3.3`)
- `~/.claude/rules/plan-mode.md` (global rule — remove stale guidance)

`kit/plugins/git-agent/skills/branch-agent/SKILL.md` is the reference; no
changes needed there.

## Steps

1. **`commit-agent/SKILL.md`**
   - Add `ExitPlanMode` to `allowed-tools`. Current value is
     `allowed-tools: Bash(git *)` — extend it to a list/comma-separated form
     that preserves `Bash(git *)` and adds `ExitPlanMode`.
   - Insert a new `## Step 0: Exit Plan Mode` section immediately after the
     opening paragraph and before `## Step 1: Guards`, with text matching the
     branch-agent pattern and a rationale tailored to commits (commits are
     git mutations and cannot proceed inside plan mode).
   - Update the opening paragraph's step-count language: "Follow these steps
     in strict order. **STOP immediately after step 4.**" — step numbering
     does not shift, so the final-step line stays at step 4.

2. **`pr-agent/SKILL.md`**
   - Add `ExitPlanMode` to `allowed-tools`. Current value is
     `Bash(git *), Bash(gh *), Bash(glab *), Read, Grep, Glob` — append
     `, ExitPlanMode`.
   - Insert `## Step 0: Exit Plan Mode` before `## Step 1: Guards` with
     rationale tailored to PR creation (pushing and creating a PR are remote
     mutations and cannot proceed inside plan mode).
   - Final-step line stays at step 5.

3. **`ship/SKILL.md`**
   - Add `ExitPlanMode` to `allowed-tools` (same treatment as pr-agent).
   - Insert `## Step 0: Exit Plan Mode` before `## Step 1: Pre-flight Guards`
     with rationale tailored to the combined commit+push+PR flow.
   - Final-step line stays at step 8.

4. **Version bump** — in `.claude-plugin/marketplace.json`, change the
   `git-agent` plugin's `version` from `3.3.2` to `3.3.3` (PATCH, consistent
   with v3.3.1's precedent for the same change to branch-agent).

5. **Changelog** — prepend a `## v3.3.3 — commit-agent, pr-agent, and ship now exit plan mode on entry`
   section to `kit/plugins/git-agent/CHANGELOG.md` describing the extension
   of the v3.3.1 pattern to the remaining three skills and the corresponding
   `allowed-tools` additions.

6. **Global rule update** — edit `~/.claude/rules/plan-mode.md` to remove the
   now-stale instruction:

   > "Before invoking any git-agent or filesystem-modifying skill (e.g.
   > branch-agent, commit-agent, pr-agent, graphify), confirm plan mode is
   > off and execute directly — do NOT insert an ExitPlanMode step into the
   > skill's execution flow."

   Replace it with guidance that reflects the new reality: git-agent skills
   self-bootstrap out of plan mode via Step 0, so callers no longer need to
   pre-check plan-mode state. Keep the rest of the file untouched.

## Exact Step 0 Text (template)

Use this template for each skill, swapping the second sentence for a
skill-specific rationale:

```markdown
## Step 0: Exit Plan Mode

Always call `ExitPlanMode` immediately when this skill is invoked, before any
other action. <SKILL-SPECIFIC RATIONALE> cannot proceed inside plan mode.
```

Suggested per-skill rationales:

- `commit-agent`: "Staging and committing are git mutations and cannot proceed inside plan mode."
- `pr-agent`: "Pushing and creating a pull request are remote mutations and cannot proceed inside plan mode."
- `ship`: "Staging, committing, pushing, and creating a pull/merge request are mutations and cannot proceed inside plan mode."

## Verification

1. **Lint the skill frontmatter** — run the repository's validator or load
   the plugin in a scratch Claude session:

   ```bash
   claude --plugin-dir ~/devbox/agentics/kit/plugins/git-agent
   ```

   Confirm all four skills load without frontmatter errors.

2. **Smoke-test each updated skill inside plan mode**:
   - Enter plan mode (`/plan`).
   - Trigger `commit-agent` explicitly with a trivial staged change and
     confirm it exits plan mode on entry and completes through Step 4.
   - Repeat for `pr-agent` on a feature branch with commits ahead of base.
   - Repeat for `ship` on a feature branch with uncommitted changes.
   - Expected: no permission prompt for `ExitPlanMode`; plan mode exits;
     skill runs to its documented STOP point.

3. **Diff the marketplace manifest** — `git diff .claude-plugin/marketplace.json`
   should show only the version change from `3.3.2` → `3.3.3`.

4. **Changelog** — confirm `kit/plugins/git-agent/CHANGELOG.md` has the new
   `v3.3.3` entry at the top and follows the project's changelog style.

## Out of Scope (Next Steps)

- Adding `disable-model-invocation: true` to `commit-agent`, `pr-agent`, or
  `ship` to match `branch-agent`'s explicit-invocation-only posture. Worth
  revisiting — auto-activating skills that self-exit plan mode give up one
  layer of user consent.

## Decisions Locked In

- **Scope:** only `commit-agent`, `pr-agent`, `ship`. `branch-agent` already
  has Step 0 (v3.3.1) and is left untouched.
- **Version bump:** PATCH (`3.3.2` → `3.3.3`), matching the v3.3.1 precedent.
- **Global rule:** update `~/.claude/rules/plan-mode.md` in the same change
  so guidance matches new skill behavior.
