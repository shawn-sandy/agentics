# Fix plan-documenter agent permissionMode documentation

## Context

The `plan-documenter` agent (`kit/plugins/plan-interview/agents/plan-documenter.md`) declares `permissionMode: bypassPermissions` in its frontmatter to enable unattended batch operation. However, per the official plugins reference (code.claude.com/docs/en/plugins-reference), **plugin agents do not support `permissionMode` — the field is silently ignored**.

**Crucially, the agent still runs.** The ignored field does not cause an error or prevent execution. Here's what actually happens:

| Invocation method | Behavior | Unattended? |
|---|---|---|
| **Interactive** (Agent tool) | Agent runs. Write/Edit/Skill calls surface permission prompts. User approves each one. | No |
| **Remote trigger** (scheduled) | Trigger clones the repo and runs a prompt directly — bypasses the plugin system entirely. Has its own permission model. | Yes — but NOT because of `permissionMode` |

The bug is a **documentation/expectations gap**: the README and CHANGELOG promise "fully unattended batch operation" based on `permissionMode`, but scheduled triggers work for an entirely different reason (they bypass the plugin system). Developers reading the docs would incorrectly believe the `permissionMode` field is what enables automation.

## Objective

Remove the non-functional `permissionMode` field, add clear developer-facing documentation explaining how plugin agent permissions actually work, and correct the README/CHANGELOG so developers understand the real execution model.

## Steps

1. **Remove `permissionMode: bypassPermissions` from agent frontmatter**
   - File: `kit/plugins/plan-interview/agents/plan-documenter.md` line 22
   - Delete the line entirely — leaving a non-functional field is misleading
   - *Why:* The field is silently ignored; keeping it implies unattended operation works

2. **Remove `AskUserQuestion` from agent tools list**
   - File: `kit/plugins/plan-interview/agents/plan-documenter.md` line 20
   - *Why:* Agents are subprocesses — they cannot prompt the user interactively. The tool was listed to "accept defaults" from skill prompts, but that mechanism doesn't work without permission bypass.

3. **Update agent workflow Step 5 to avoid interactive skill prompts**
   - File: `kit/plugins/plan-interview/agents/plan-documenter.md` lines 74-86
   - Instead of invoking the `documenting-plans` skill (which uses `AskUserQuestion` for slug confirmation and overwrite/refresh choice), the agent should:
     - Derive the slug itself (filename without `.md`, per Step 3 logic already in the agent)
     - Write the doc directly using Write/Edit, OR
     - Pass explicit arguments to the skill that signal batch mode (slug + overwrite preference)
   - Recommended approach: Add a note in Step 5 that the agent passes the plan path AND the slug as arguments, and instructs the skill to skip confirmation prompts when both are provided
   - *Why:* The `documenting-plans` skill's `AskUserQuestion` calls at Steps 4 and 7 will block when invoked from an agent context

4. **Add a "Limitations" section to the agent file**
   - File: `kit/plugins/plan-interview/agents/plan-documenter.md`, after the "Scope Boundaries" section
   - Content:
     ```
     ## Limitations

     Plugin agents do not support `permissionMode` — permission prompts for
     Write, Edit, and Bash tools will surface during execution. This agent
     works best when invoked interactively (user approves prompts as they
     appear) or via remote triggers (which have their own permission model).
     ```
   - *Why:* Future maintainers need to know this constraint exists

5. **Update README with a "Permission model" subsection and rewrite "Weekly scheduled run"**
   - File: `kit/plugins/plan-interview/README.md` lines 142-235
   - Add a new subsection under "Batch Document All Plans (Agent)" explaining the permission model:
     - Plugin agents do not support `permissionMode` — the field is ignored per official docs
     - Interactive invocation: agent runs, user approves Write/Edit/Skill prompts as they appear
     - Scheduled triggers: work unattended because they clone the repo and execute a prompt directly, bypassing the plugin agent system entirely
     - This distinction matters for developers setting up automation — the agent itself is not what enables unattended operation
   - Rewrite "Weekly scheduled run" section to explain that the trigger runs a prompt (not the plugin agent) and has its own permission model
   - *Why:* Developers need to understand why scheduled runs work and interactive runs require approval — the current docs obscure this critical distinction

6. **Update CHANGELOG v1.14.0 entry**
   - File: `kit/plugins/plan-interview/CHANGELOG.md` line 16
   - Remove: "Uses `permissionMode: bypassPermissions` for fully unattended batch operation"
   - Replace with: "Interactive batch operation — user approves permission prompts as they appear; for unattended runs, use remote triggers with an inline prompt"
   - *Why:* The changelog documents a capability that doesn't exist

7. **Bump version to 1.14.1 in marketplace.json**
   - File: `.claude-plugin/marketplace.json` (plan-interview entry)
   - Bump patch version: `1.14.0` -> `1.14.1`
   - *Why:* This is a bug fix (non-functional feature removal + doc correction)

8. **Add CHANGELOG entry for 1.14.1**
   - File: `kit/plugins/plan-interview/CHANGELOG.md`
   - New entry at top:
     ```
     ## [1.14.1] - 2026-04-15

     ### Fixed

     - Removed non-functional `permissionMode: bypassPermissions` from plan-documenter
       agent — plugin agents do not support this field per official docs
     - Removed `AskUserQuestion` from agent tools (agents cannot prompt users)
     - Updated README and CHANGELOG to accurately describe permission behavior
     - Agent now works interactively (user approves prompts) or via remote triggers
     ```

## Files to modify

| File | Change |
|------|--------|
| `kit/plugins/plan-interview/agents/plan-documenter.md` | Remove `permissionMode`, remove `AskUserQuestion`, add Limitations section, update Step 5 |
| `kit/plugins/plan-interview/README.md` | Rewrite "Weekly scheduled run" section with accurate permission info |
| `kit/plugins/plan-interview/CHANGELOG.md` | Fix v1.14.0 entry, add v1.14.1 entry |
| `.claude-plugin/marketplace.json` | Bump plan-interview version to 1.14.1 |

## Verification

1. Read the updated agent file and confirm `permissionMode` is gone
2. Read the updated agent file and confirm `AskUserQuestion` is not in the tools list
3. Grep the plugin directory for `permissionMode` — should return zero matches
4. Grep the plugin directory for `bypassPermissions` — should return zero matches
5. Read the CHANGELOG and confirm v1.14.0 no longer claims unattended operation
6. Read the README and confirm the scheduled run section has accurate caveats
7. Validate `marketplace.json` is valid JSON (the settings hook does this automatically)
