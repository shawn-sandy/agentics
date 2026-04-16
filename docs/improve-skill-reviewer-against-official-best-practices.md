# Improve skill-reviewer Against Official Best Practices

> Aligns `reviewing-skills` skill, `best-practices.md`, and `audit-steps.md` with updated Anthropic official skill documentation — adds workflow patterns, script quality anti-patterns, and raises the line-count Ideal threshold from 400 to 500.

<!-- generated:start -->

**Status:** Shipped 2026-02-27   **Plan:** [improve-skill-reviewer-against-official-best-practices.md](plans/improve-skill-reviewer-against-official-best-practices.md)   **Type:** artifact

## What shipped

- `SKILL.md` Quick Reference Checklist: three new items in Body section (checklist workflow, no-options-without-default, assumed installs); one new item in Structure section (feedback loop); new Scripts section (MCP format, magic numbers, error handling, install instructions).
- `references/best-practices.md`: four new content pattern sections (checklist workflow, feedback loop, template pattern, conditional workflow); token budget consciousness section; script quality anti-patterns; MCP tool reference guidance; evaluation-driven development section; TOC updated with all new entries.
- `references/audit-steps.md`: Dimension 2 line-count threshold raised from `<400` to `<500` (Ideal), removing the intermediate 400–499 Warning tier; Dimension 3 feedback loop Suggestion added; Dimension 4 five new anti-pattern entries with severities; script detection rule defined; Step 4 report template URL updated from `code.claude.com` to `platform.claude.com`.
- `README.md` updated to reflect new anti-patterns and revised line-count threshold.
- `skill-reviewer` plugin bumped from `1.1.0` to `1.2.0`.

> See [CHANGELOG §1.2.0](../kit/plugins/skill-reviewer/CHANGELOG.md) for the authoritative change log entry.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/skill-reviewer/skills/reviewing-skills/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md` | Reference — patterns and guidance | Modified |
| `kit/plugins/skill-reviewer/skills/reviewing-skills/references/audit-steps.md` | Reference — scoring criteria | Modified |
| `kit/plugins/skill-reviewer/README.md` | Plugin documentation | Modified |
| `kit/plugins/skill-reviewer/.claude-plugin/plugin.json` | Plugin manifest | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry | Modified (version 1.2.0) |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Version history | Modified (1.2.0 entry) |

## How it works

The most impactful change is the scoring threshold shift in Dimension 2 (Body Quality): the Ideal band was raised from `<400 lines` to `<500 lines` to match the official Anthropic guidance ("under 500 lines for optimal performance"). Skills in the 400–499 range that previously scored 1/2 now score 2/2. The CHANGELOG entry explicitly flags this as a backward-incompatible scoring change.

Five new Dimension 4 anti-patterns extend the audit to cover script quality issues: assumed tool installations without install instructions, unqualified MCP tool references (missing `ServerName:` prefix), voodoo constants (unexplained magic numbers), scripts that punt errors to Claude instead of handling them, and verbose over-explanation of things Claude already knows. A script detection rule (check for a `scripts/` folder or bash/python code blocks with external tool invocations) gates the three script-specific checks so they don't generate noise for non-script skills.

The evaluation-driven development section in `best-practices.md` introduces the iterative refinement cycle: Claude A authors the skill, Claude B acts as the agent using it, observations feed back into SKILL.md. This provides a concrete methodology for authors to test skills before shipping them.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |

<!-- generated:end -->

## References

- Plan: [improve-skill-reviewer-against-official-best-practices.md](plans/improve-skill-reviewer-against-official-best-practices.md)
- Changelog: [kit/plugins/skill-reviewer/CHANGELOG.md §1.2.0](../kit/plugins/skill-reviewer/CHANGELOG.md)
