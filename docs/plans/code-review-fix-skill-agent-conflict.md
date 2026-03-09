# Plan: Resolve Skill vs Agent Activation Conflict in code-review Plugin

## Context

The `plugins/code-review/` plugin has a **skill** (`code-review-agent`) and an **agent** (`agent-code-reviewer`) with nearly identical `description` fields. Since Claude Code uses the description to decide which component activates, both compete for the same user intents (e.g. "review this code", "find bugs", "take a look at this"). This causes redundant or unpredictable activation.

## Strategy

Differentiate by **execution model**: the skill owns direct, interactive user requests; the agent owns delegated, background, and proactive reviews. Rewrite each description to capture only its own use case with zero overlapping trigger phrases.

## Steps

1. **Rewrite skill description** in `plugins/code-review/skills/code-review-agent/SKILL.md`
   - Add "interactive" and "when the user directly asks" as qualifying language
   - Keep all user-facing trigger phrases (these belong to the skill)
   - No changes to the skill body

2. **Rewrite agent description and mark as internal** in `plugins/code-review/agents/agent-code-reviewer.md`
   - Remove all user-facing trigger phrases ("review code", "check files", "find bugs", "take a look at this")
   - Focus on: delegation from other agents, automated workflows, proactive sweeps
   - Add explicit exclusion: "Not for direct user review requests"
   - Mark as internal/delegation-only in the description
   - No changes to agent body or tool/model config

3. **Update README** in `plugins/code-review/README.md`
   - Clarify when each component activates
   - Mark the agent section as "Internal Agent" — for delegation from other agents only, not user-facing

4. **Add CHANGELOG entry** in `plugins/code-review/CHANGELOG.md`
   - New `[3.0.1]` section documenting the fix
   - Note that the agent is retained for future delegation workflows

5. **Bump version to 3.0.1** (PATCH — metadata clarification, no behavioral change)
   - `plugins/code-review/.claude-plugin/plugin.json` — `3.0.0` to `3.0.1`
   - `.claude-plugin/marketplace.json` — code-review entry `3.0.0` to `3.0.1`

## Files to Modify

| File | Change |
|------|--------|
| `plugins/code-review/skills/code-review-agent/SKILL.md` | Rewrite frontmatter `description` |
| `plugins/code-review/agents/agent-code-reviewer.md` | Rewrite frontmatter `description` |
| `plugins/code-review/README.md` | Update component descriptions |
| `plugins/code-review/CHANGELOG.md` | Add `[3.0.1]` entry |
| `plugins/code-review/.claude-plugin/plugin.json` | Bump version |
| `.claude-plugin/marketplace.json` | Bump code-review version |

## Verification

1. Load plugin: `claude --plugin-dir ./plugins/code-review`
2. Test skill activation: say "review this code" — should trigger the skill (inline)
3. Test agent non-activation: confirm the agent doesn't compete with the skill for direct requests
4. Verify version sync: `grep -r '"version"' plugins/code-review/.claude-plugin/ .claude-plugin/marketplace.json`

## Interview Summary

### Key Decisions Confirmed

- **Qualifier words are acceptable** — Adding "interactive" / "directly asks" to the skill description won't weaken activation since the trigger phrases remain intact
- **Agent should be marked as internal** — Beyond the description rewrite, the agent should be documented as internal/delegation-only in the README
- **No current agent consumers** — Nothing currently delegates to `agent-code-reviewer`; it's being retained for future use
- **PATCH version (3.0.1) is correct** — The agent was never intended for direct user invocation (`background: true`), so this is a metadata clarification

### Open Risks & Concerns

- **Agent may be premature** — With no current consumers, the agent exists purely for a future delegation use case. If that use case doesn't materialize, the agent adds maintenance overhead without value
- **README update lacks detail** — Step 3 needs to explicitly include marking the agent as "internal-only" per the user's decision

### Recommended Amendments

1. **Update Step 2** to add: mark the agent as internal in the agent description or frontmatter
2. **Update Step 3** to explicitly specify adding "Internal Agent" designation in the README
3. **Add a brief rationale** in the CHANGELOG entry explaining why the agent is retained (future delegation workflows)
