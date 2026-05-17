# Address PR #120 review comments

> Bundles fixes for PR #120 (product-plans v2.2.0): repairs non-functional background mode, corrects off-by-one documentation from the Security reviewer addition, fixes arg-parsing order sensitivity, and removes three stale plan files with a `directoryt` typo.

<!-- generated:start -->

**Status:** Shipped 2026-05-15  **Plan:** [address-pr-120-review-comments.md](plans/address-pr-120-review-comments.md)
**Type:** artifact

## What shipped

- Fixed `kit/plugins/product-plans/agents/agent-product-plans.md` tool list — expanded from `Skill, Read` to `Skill, Read, Write, Edit, Glob, Grep, Bash` so that subagent write operations in background mode succeed (tool grants are not transitive across `Skill` invocations).
- Added `ExitPlanMode` bootstrap (Step 0) to `kit/plugins/product-plans/commands/product-plans-bg.md` — mirrors the git-agent pattern (`ToolSearch select:ExitPlanMode` then silent `ExitPlanMode`) so the command can dispatch a write-performing agent even when launched from plan mode.
- Rewrote Step 1 arg parsing in the product-plans skill (`kit/plugins/product-plans/skills/plan-review-agents/SKILL.md`) to split `$ARGUMENTS` on whitespace, classify `--<word>` tokens as flags, and pick the first non-flag token as the path — eliminating the flag-order sensitivity that caused `--background <path>` to fail.
- Updated `kit/plugins/product-plans/README.md` to reflect v2.2.0 reality: "15-section" output, Security Requirements added as section 9 (renumbering 9-13 down to 10-14), plugin tree now includes `product-reviewer-security-expert.md`, auto-activation trigger lists `PM/Dev/UX/Frontend/Accessibility/Security`.
- Reverted a duplicate blank line in `kit/plugins/plan-interview/skills/plan-to-html/SKILL.md` (lines 163-165).
- Expanded `kit/plugins/plan-interview/CHANGELOG.md` v1.22.1 entry with bullets for the `--background` flag switch (`--no-open` → `--background`) and the `git add` reorganization.
- Deleted three stale plan files carrying the `directoryt` typo and non-descriptive auto-generated slugs (`rename-the-skill-directoryt-joyful-puffin.md`, `rename-the-skill-directoryt-joyful-puffin-revised.md`, `docs-plans-rename-the-skill-directoryt-j-immutable-anchor.md`); the descriptive replacement `add-background-mode-product-plans.md` was kept.
- Corrected `kit/plugins/product-plans/skills/plan-review-agents/references/output-template.md:5` — "Section 14 is omitted" → "Section 15 (Revised Product Plan) is omitted" (pre-step already applied before this plan was written; the skill directory had already been renamed from `product-plans` to `plan-review-agents` by this point).

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/product-plans/agents/agent-product-plans.md` | Agent definition | Modified |
| `kit/plugins/product-plans/commands/product-plans-bg.md` | Command wrapper | Modified |
| `kit/plugins/product-plans/skills/plan-review-agents/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/product-plans/README.md` | Plugin documentation | Modified |
| `kit/plugins/product-plans/CHANGELOG.md` | Changelog | Modified |
| `kit/plugins/plan-interview/skills/plan-to-html/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-interview/CHANGELOG.md` | Changelog | Modified |

## How it works

The root cause of the non-functional background mode was that `agent-product-plans.md` declared only `tools: Skill, Read`. When the agent invoked a skill that internally called `Write`, the write was silently dropped because Claude Code does not propagate tool grants through `Skill` invocations — the agent's declared tool list is the ceiling. The fix expands the tool list to include `Write, Edit, Glob, Grep, Bash`, giving the agent direct access to the tools its delegated skills require.

The background command (`/product-plans:product-plans-bg`) had a second structural problem: dispatching a write-performing agent from plan mode blocks execution because plan mode prevents writes. The fix adds a Step 0 that loads `ExitPlanMode` via `ToolSearch` and calls it silently before the dispatch step, following the same bootstrap pattern already established in the git-agent plugin. The `allowed-tools` frontmatter was updated to include `Agent, ToolSearch, ExitPlanMode`.

Arg parsing in the skill previously used a "everything before any `--` flag" rule that only worked when the plan path came first. If a user passed `--background docs/plans/foo.md`, the path extraction returned empty and the skill halted with an error. The new Step 1 tokenizes `$ARGUMENTS`, classifies any `--<word>` token as a flag, and takes the first non-flag token as the path, making all three orderings (`<path>`, `<path> --background`, `--background <path>`) equivalent.

The documentation inconsistency in `README.md` was a direct result of adding the Security reviewer in v2.2.0: section bodies were renumbered but surrounding metadata (section count claims, plugin tree, and trigger description) were not updated. The fix aligns all references with the actual 15-section output format.

The three deleted plan files were procedural artifacts created during the `rename-the-skill-directoryt` incident: two carried a typo in the slug and one was an immutable-anchor file generated solely to satisfy plan mode at execution time. With the descriptive `add-background-mode-product-plans.md` already in the repo, the duplicates were dead weight.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `44dc02f` | 2026-05-17 | docs(sweep): mark 18 completed plans as artifact and generate initial docs |
| `d0a8fa7` | 2026-05-15 | fix(kit/plugins/product-plans): address Codex/Copilot PR #120 review comments |

<!-- generated:end -->

## References

- Plan: [address-pr-120-review-comments.md](plans/address-pr-120-review-comments.md)
