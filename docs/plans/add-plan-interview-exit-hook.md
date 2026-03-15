# Plan: Add PostToolUse Hook to Trigger Plan Interview After Exiting Plan Mode

## Context

After completing a plan in plan mode, users must manually invoke the plan-interview
skill to stress-test it. This creates a gap where plans go unreviewed. Adding a
`PostToolUse` hook on `ExitPlanMode` closes this gap by prompting the user to run the
plan-interview skill immediately after plan mode exits — making plan review a natural
part of the workflow rather than an afterthought.

## Approach

Add a `hooks.json` file to the existing `plan-interview` plugin that fires a
`PostToolUse` hook when the `ExitPlanMode` tool is used. The hook echoes a prompt
suggesting the user run the plan-interview skill. It does **not** auto-start — the user
must confirm.

## Steps

### 1. Create `plugins/plan-interview/hooks.json`

New file at the plugin root:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "ExitPlanMode",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Plan mode exited. You may want to stress-test this plan before implementing it. Would you like me to run the plan-interview skill to surface gaps, risks, and trade-offs?'"
          }
        ]
      }
    ]
  }
}
```

Validation: H01 (valid JSON), H02 (valid event `PostToolUse`), H03 (matcher
`ExitPlanMode` present).

### 2. Update `plugins/plan-interview/README.md`

- Add hook row to Components table:
  `| ExitPlanMode | Hook | Auto-fires after exiting plan mode |`
- Add new section after "Skill (automatic activation)" explaining the hook behavior

### 3. Update `plugins/plan-interview/CHANGELOG.md`

Add entry at top:

```markdown
## [1.5.0] - 2026-03-14

### Added

- PostToolUse hook on `ExitPlanMode` — prompts user to run plan-interview after exiting plan mode
```

### 4. Bump version in `.claude-plugin/marketplace.json`

Change `plan-interview` version from `"1.4.0"` to `"1.5.0"` (minor bump — new
backward-compatible component).

## Files to Modify

| File | Action |
|------|--------|
| `plugins/plan-interview/hooks.json` | CREATE |
| `plugins/plan-interview/README.md` | EDIT |
| `plugins/plan-interview/CHANGELOG.md` | EDIT |
| `.claude-plugin/marketplace.json` | EDIT |

## Key References

- Hook template: `plugins/agentic-plugin-dev/skills/plugin-creator/references/component-templates.md` (lines 97-128)
- Hook validation rules: `plugins/agentic-plugin-dev/skills/plugin-validator/references/validation-rules.md` (lines 61-67)
- Existing plugin.json (no version field — correct): `plugins/plan-interview/.claude-plugin/plugin.json`

## Verification

1. Validate JSON: `python3 -c "import json; json.load(open('plugins/plan-interview/hooks.json'))"`
2. Confirm no version in plugin.json: `grep '"version"' plugins/plan-interview/.claude-plugin/plugin.json`
3. Confirm marketplace version: `grep -A1 '"plan-interview"' .claude-plugin/marketplace.json | grep version`
4. Load plugin locally: `claude --plugin-dir ./plugins/plan-interview`
5. Functional test: enter plan mode, write a plan, exit plan mode, verify hook message appears

## Next Steps (out of scope)

- Add a `PreToolUse` hook on `ExitPlanMode` to warn if the plan file appears empty
- Consider a `Stop` hook that checks if plan files were modified during the session
- Apply similar post-tool hooks to other plugins (e.g., code-review after large commits)
