# Resolve Skill vs Agent Activation Conflict in code-review Plugin

> Differentiates the `code-review-agent` skill and `agent-code-reviewer` agent descriptions to eliminate competing activations for the same user intents.

<!-- generated:start -->

**Status:** Shipped 2026-03-09   **Plan:** [code-review-fix-skill-agent-conflict.md](plans/code-review-fix-skill-agent-conflict.md)   **Type:** standard

## What shipped

- Skill description in `SKILL.md` rewritten to qualify on "direct, interactive user requests" — keeps all user-facing trigger phrases.
- Agent description in `agent-code-reviewer.md` rewritten to target only delegation, automated workflows, and proactive sweeps — all user-facing trigger phrases removed.
- Agent explicitly marked as internal/delegation-only in both the description and the `README.md`.
- `code-review` plugin bumped from `3.0.0` → `3.0.1` (PATCH — metadata clarification).

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/code-review/skills/code-review-agent/SKILL.md` | Skill instructions — description rewrite | Modified |
| `kit/plugins/code-review/agents/agent-code-reviewer.md` | Agent definition — description rewrite | Modified |
| `kit/plugins/code-review/README.md` | Plugin documentation — internal agent designation | Modified |
| `kit/plugins/code-review/CHANGELOG.md` | Plugin changelog — v3.0.1 entry | Modified |
| `kit/plugins/code-review/.claude-plugin/plugin.json` | Plugin manifest — version bump | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump to 3.0.1 | Modified |

## How it works

Both the skill and agent originally used "review code", "find bugs", "check files", and "take a look at this" as activation triggers. Claude Code picks the component whose description best matches the user's intent — with identical trigger phrases, the choice was unpredictable.

The fix applies the **execution model** principle: the skill owns the user-facing surface (a human directly asked for a review), while the agent owns the programmatic surface (another agent or automated workflow needs review results in the background).

Adding "interactive" and "when the user directly asks" to the skill description was validated to not weaken activation — the user-facing trigger phrases remain intact, and the qualifier simply prevents the agent from competing for the same signals.

The `background: true` flag on the agent (already set) supported the internal designation: it was never designed for direct user invocation.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |

<!-- generated:end -->

## References

- Plan: [code-review-fix-skill-agent-conflict.md](plans/code-review-fix-skill-agent-conflict.md)
