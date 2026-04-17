---
description: Verify SKILL.md changes against Anthropic's effective-skills checklist
paths:
  - "kit/plugins/**/skills/**"
---

# Skill Authoring

Before saving changes to a `SKILL.md` (or any bundled file under `skills/`), verify the skill meets Anthropic's [checklist for effective Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#checklist-for-effective-skills).

## Checklist

### Core quality

- [ ] Description is specific and includes key terms
- [ ] Description includes both what the Skill does and when to use it
- [ ] SKILL.md body is under 500 lines
- [ ] Additional details are in separate files (if needed)
- [ ] No time-sensitive information (or in "old patterns" section)
- [ ] Consistent terminology throughout
- [ ] Examples are concrete, not abstract
- [ ] File references are one level deep
- [ ] Progressive disclosure used appropriately
- [ ] Workflows have clear steps

### Code and scripts

Apply only if the skill bundles executable scripts (typically under `scripts/`):

- [ ] Scripts solve problems rather than punt to Claude
- [ ] Error handling is explicit and helpful
- [ ] No "voodoo constants" (all values justified)
- [ ] Required packages listed in instructions and verified as available
- [ ] Scripts have clear documentation
- [ ] No Windows-style paths (all forward slashes)
- [ ] Validation/verification steps for critical operations
- [ ] Feedback loops included for quality-critical tasks

### Testing

- [ ] At least three evaluations created
- [ ] Tested with Haiku, Sonnet, and Opus
- [ ] Tested with real usage scenarios
- [ ] Team feedback incorporated (if applicable)

## Frontmatter constraints

Hard validation rules enforced by the skill runtime:

- `name`: lowercase kebab-case, ≤64 chars, no XML tags, no reserved words (`anthropic`, `claude`)
- `description`: non-empty, ≤1024 chars, third person, no XML tags

## When in doubt

Run `/skill-reviewer:reviewing-skills` on the skill for a scored audit against these criteria.
