---
title: Update plan-interview README for v1.6.0 and v1.7.0
branch: upgrade/plan-inteview
file: plugins/plan-interview/README.md
---

# Update plan-interview README for v1.6.0 and v1.7.0

## Context

The `upgrade/plan-inteview` branch added two features to the `plan-interview` plugin that are not yet reflected in `plugins/plan-interview/README.md`:

- **v1.6.0**: Optional Deep Grill step (Step 4.5) — user-initiated relentless questioning through all decision branches with AI-recommended answers and codebase exploration
- **v1.7.0**: Skill Review Mode — auto-detects `SKILL.md` files as interview targets, adds Step 2.5 tool analysis, outputs `allowed-tools` recommendations, and optionally applies them to paired command files

## File to Modify

- `plugins/plan-interview/README.md`

## Steps

1. **Purpose section** — append one sentence mentioning skill review mode:
   > Also stress-tests `SKILL.md` files by auditing tool usage and generating `allowed-tools` recommendations.

2. **Usage > Skill (automatic activation)** — add skill-review mode trigger examples below the existing list:
   ```
   Review this SKILL.md for tool coverage
   Audit the allowed-tools in my skill
   Check what tools this skill uses
   ```

3. **Interview rounds table** — add a note below the table:
   > During any interview, you can request a **Deep Grill** session at Step 4.5. Claude will walk through every decision branch with relentless follow-up questions, suggest answers, and explore the codebase with `Glob`/`Grep`/`Read`. Findings are collected in the summary.

4. **After the interview section** — add `Allowed Tools Recommendation` to the summary bullet list:
   - Plan naming issues (if the filename or heading is non-descriptive)
   - Key decisions confirmed
   - Open risks and concerns
   - Recommended next steps
   - Simplification opportunities (if any)
   - **Allowed Tools Recommendation** (skill-review mode only — suggested `allowed-tools` line for paired command file)

## Verification

1. Read the updated `plugins/plan-interview/README.md` and confirm all four sections are present.
2. Load the plugin locally: `claude --plugin-dir ./plugins/plan-interview`
3. Run `/plan-interview:plan-interview` against a `SKILL.md` file — confirm skill-review mode activates and Step 2.5 runs.
4. Confirm Deep Grill is offered during a standard plan interview.

## Next Steps (out of scope)

- Add a `SKILL.md` example invocation to the README's command usage table
- Document `plan-hygiene` and `review-rename-plans` commands in their own sections with examples
- Add a CHANGELOG link or version history section to the README
