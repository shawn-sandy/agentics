---
description: Verify SKILL.md changes against Anthropic's effective-skills checklist
paths:
  - "kit/plugins/**/skills/**"
---

# Skill Authoring

Before saving a `SKILL.md` or any bundled file under `skills/`, check it
against Anthropic's [checklist for effective Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#checklist-for-effective-skills).
Read the checklist there rather than from a copy — it moves.

For a scored audit, run `/skill-reviewer:reviewing-skills` on the skill.

## Hard constraints

Enforced by the skill runtime, so violations fail at load:

- `name` — lowercase kebab-case, ≤64 chars, no XML tags, and not `anthropic`
  or `claude`
- `description` — non-empty, ≤1024 chars, third person, no XML tags

Repo conventions on top of that (three-part description format, `allowed-tools`,
deferred tools, the plan-mode guard) live in `plugin-patterns.md`.

## Where the tokens go

Body under 500 lines, deeper material in sibling files one level deep. A skill
should encode the opinions and hard-won specifics of this repo — not restate
mechanics the model already has.
