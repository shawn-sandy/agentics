# Add PostToolUse Hook to Trigger Plan Interview After Exiting Plan Mode

> Adds a `PostToolUse` hook on `ExitPlanMode` to the `plan-interview` plugin, prompting users to stress-test their plan immediately after plan mode exits.

<!-- generated:start -->

**Status:** Shipped 2026-03-14   **Plan:** [add-plan-interview-exit-hook.md](plans/add-plan-interview-exit-hook.md)   **Type:** feature

## What shipped

- New `kit/plugins/plan-interview/hooks.json` with a `PostToolUse` hook on the `ExitPlanMode` matcher — echoes a prompt suggesting the user run the plan-interview skill.
- Hook is advisory: it does not auto-start the skill; the user must confirm.
- `plan-interview` plugin bumped to `1.5.0`.
- README updated with a Hook row in the Components table and a new section explaining hook behavior.

> See [CHANGELOG v1.5.0](../kit/plugins/plan-interview/CHANGELOG.md#150---2026-03-14) for the authoritative feature list.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-interview/hooks.json` | PostToolUse hook definition | Created |
| `kit/plugins/plan-interview/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-interview/CHANGELOG.md` | Plugin changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump to 1.5.0 | Modified |

## How it works

The `hooks.json` file registers a `PostToolUse` hook that matches on the `ExitPlanMode` tool. When plan mode exits, the hook fires an `echo` command that prints:

```
Plan mode exited. You may want to stress-test this plan before implementing it.
Would you like me to run the plan-interview skill to surface gaps, risks, and trade-offs?
```

The hook uses `type: command` with a shell `echo` — the message appears in the terminal after plan mode closes. The user must respond affirmatively to trigger the skill; the hook does not invoke it automatically.

This design closes a workflow gap: previously, users had to remember to invoke `plan-interview` after writing a plan. The hook makes the review step visible at exactly the right moment — when plan mode has just exited and implementation is about to begin.

## How to use it

The hook fires automatically whenever plan mode exits. No explicit invocation is needed. To use the plugin:

```bash
claude --plugin-dir ./kit/plugins/plan-interview
```

Or after installing from the marketplace:

```
/plugin install plan-interview@agentics-kit
```

Write a plan in plan mode, exit, and the prompt will appear.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |

<!-- generated:end -->

## References

- Plan: [add-plan-interview-exit-hook.md](plans/add-plan-interview-exit-hook.md)
- Changelog: [CHANGELOG v1.5.0](../kit/plugins/plan-interview/CHANGELOG.md#150---2026-03-14)
