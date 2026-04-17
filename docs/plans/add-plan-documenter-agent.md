---
status: todo
type: standard
created: 2026-04-15
---

# Plan: Add `plan-documenter` Agent with Weekly Scheduled Task

## Context

The `plan-interview` plugin has a `documenting-plans` skill that converts a single completed plan into prose documentation at `docs/<slug>.md`. With 100+ plans in `docs/plans/`, manually invoking this skill per-plan is impractical. A batch agent automates the sweep, and a weekly schedule keeps documentation current as plans reach completion.

## Objective

1. Create a `plan-documenter` agent that batch-processes all completed plans lacking documentation
2. Set up a weekly scheduled task to run the agent automatically

## Steps

1. **Create `kit/plugins/plan-interview/agents/plan-documenter.md`**
   - First agent in this plugin; `agents/` directory does not yet exist
   - *Why:* Agents are auto-discovered from `agents/*.md` files; no `plugin.json` changes needed

2. **Agent frontmatter configuration**
   ```yaml
   name: plan-documenter
   description: >
     Batch documentation agent that scans docs/plans/ for completed plans
     without corresponding documentation in docs/, then invokes the
     documenting-plans skill for each one. Use when delegating bulk plan
     documentation, running a scheduled weekly documentation sweep, or
     generating docs for all completed plans at once.
   tools: Read, Glob, Grep, Bash, Write, Edit, TodoWrite, Skill, AskUserQuestion
   model: sonnet
   permissionMode: bypassPermissions
   maxTurns: 50
   ```
   - *Why:* `bypassPermissions` enables fully unattended batch operation — no prompts for file writes or skill confirmations. `maxTurns: 50` gives headroom for ~15-20 plans per run. `Skill` tool is required to invoke `plan-interview:documenting-plans` (verify availability at implementation time; fallback: use `Agent` tool to spawn sub-agents).

3. **Agent body — workflow instructions**
   - **Step 0:** Resolve plan directory — read `plansDirectory` from `.claude/settings.json`, fall back to `docs/plans/`
   - **Step 1:** Glob `<plansDirectory>/*.md` to collect all plan files
   - **Step 2:** Read first 10 lines of each to extract `status:` from YAML frontmatter; filter to `status: completed` only
   - **Step 3:** For each completed plan, derive slug (filename without `.md`), check if `docs/<slug>.md` exists via Glob; build "needs documentation" list
   - **Step 4:** Report scope — "Found N completed plans, M already documented, K need documentation"
   - **Step 5:** For each undocumented plan, invoke `Skill` with `skill: "plan-interview:documenting-plans"` and `args: "<plan-file-path>"`; accept default slug and overwrite when prompted
   - **Step 6:** Final summary table (total scanned, completed, already documented, newly documented, failures)
   - *Why:* Pre-filtering saves turns; processing sequentially prevents conflicts; summary gives visibility

4. **Update `kit/plugins/plan-interview/CHANGELOG.md`**
   - Add `[1.14.0] - 2026-04-15` entry documenting the new agent
   - *Why:* Convention requires changelog entries for new components

5. **Update `kit/plugins/plan-interview/README.md`**
   - Add `plan-documenter` row to Components table (Type: Agent, Invocation: via Agent tool)
   - Add "Batch Document All Plans (Agent)" section after "Document Completed Plans" (~line 139)
   - *Why:* README must document all components per plugin pattern conventions

6. **Bump version in `.claude-plugin/marketplace.json`**
   - Change `"version": "1.13.0"` to `"version": "1.14.0"` on line 57 (plan-interview entry)
   - *Why:* New agent = minor version bump per marketplace versioning rules

7. **Create weekly scheduled task**
   - Use the `schedule` skill to create a remote trigger
   - Schedule: `0 10 * * 0` (every Sunday at 6:00 AM ET / 10:00 AM UTC)
   - Prompt: invoke `plan-interview:plan-documenter` agent to sweep all undocumented completed plans
   - *Why:* Automates a weekly documentation sweep so docs stay current without manual intervention

## Files to Create

1. `kit/plugins/plan-interview/agents/plan-documenter.md`

## Files to Modify

1. `kit/plugins/plan-interview/CHANGELOG.md` — add 1.14.0 entry
2. `kit/plugins/plan-interview/README.md` — add Components row + usage section
3. `.claude-plugin/marketplace.json` — bump version from 1.13.0 to 1.14.0

## Key Design Decisions

- **`permissionMode: bypassPermissions`** — fully unattended batch operation; no prompts for file writes or skill confirmations
- **`maxTurns: 50`** — sufficient for ~15-20 plans per run; agent reports progress so partial sweeps are visible; subsequent runs pick up remaining plans
- **No `background: true`** — user wants to see progress in real time
- **No `memory: project`** — stateless batch job; no cross-session state needed
- **Sequential processing** — one plan at a time to avoid conflicts; acceptable for a weekly batch job

## Verification

1. Load the plugin: `claude --plugin-dir ./kit/plugins/plan-interview`
2. Invoke the agent directly: use Agent tool with `subagent_type: "plan-interview:plan-documenter"` and prompt "Document all completed plans that are missing docs"
3. Verify it scans `docs/plans/`, filters correctly, and invokes the skill for undocumented plans
4. Check that `docs/<slug>.md` files are created for each processed plan
5. Verify the scheduled task appears in `/schedule list`
6. Validate `marketplace.json` syntax (the settings hook does this automatically)

## Next Steps

- Consider `bypassPermissions` if `AskUserQuestion` prompts from the `documenting-plans` skill prove disruptive in batch mode
- Add a `--dry-run` flag variant that reports which plans would be documented without actually generating docs
- Consider parallel agent invocation for faster processing of large batches

## Interview Summary

### Key Decisions Confirmed

- **Permission mode:** `bypassPermissions` for fully unattended batch operation (replaces `acceptEdits` in original plan)
- **Turn budget strategy:** Process alphabetically, report partial progress; subsequent runs pick up remaining plans automatically
- **Schedule scope:** Repo-agnostic — read `plansDirectory` from settings, fall back to `docs/plans/`
- **Pre-filter strategy:** Strict — only process plans with explicit `status: completed` in frontmatter; skip all others to conserve turns

### Open Risks & Concerns

1. **`Skill` tool may not be available to agents** — The agent schema reference does not list `Skill` as a valid agent tool. If agents cannot invoke skills, the core mechanism breaks. Mitigation: Verify at implementation time; fallback is to use the `Agent` tool to spawn a sub-agent that invokes the skill, or inline the skill logic directly.
2. **`bypassPermissions` in unattended scheduled runs** — No human oversight means unexpected git operations or malformed doc writes go unchecked. No rollback strategy is defined. Mitigation: The skill only uses `Bash(git *)` for read-only git log commands, and writes go to `docs/` (non-critical path). Risk is low.
3. **Repo-agnostic scheduling needs plan directory resolution** — The agent body must read `plansDirectory` from `.claude/settings.json` first, falling back to `docs/plans/`. This needs to be added to the agent workflow instructions.

### Recommended Next Steps

- Before implementation: verify that the `Skill` tool is available inside agent definitions
- Update plan Step 2: change `permissionMode` from `acceptEdits` to `bypassPermissions`
- Update plan Step 3: add `plansDirectory` resolution from settings before defaulting to `docs/plans/`; add explicit skip-if-documented logic
- Update plan Step 7: schedule prompt should not hardcode `docs/plans/` but let the agent resolve the directory
