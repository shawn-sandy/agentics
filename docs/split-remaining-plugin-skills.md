# Split remaining oversized plugin skills into cores and references

> Splits six monolithic skills (1,200–3,153 words each) into lean cores under 600 words with detail in `references/` files, keeping security gates in cores and making word-count tests locale-independent.

<!-- generated:start -->

**Status:** Shipped 2026-07-27 **Plan:** [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
**Type:** refactor

## What shipped

- Split `skill-reviewer:optimizing-skill-frontmatter` (3,153w), `artifact-tools:prompt-artifact` (1,665w), `artifact-tools:diff-artifact` (1,549w), `memory-tools:path-rules-advisor` (1,546w), `social-media-tools:artifact-to-post` (1,430w), and `code-testing-agent:tdd-fix` (1,202w) into lean cores (566–583 words each) plus `references/` files.
- Security gates for `diff-artifact` and `prompt-artifact` remained in the cores (outward-facing, irreversible publish).
- Word-count test uses Python instead of `wc -w` to avoid locale-dependent em-dash and multibyte character counts.
- Bumped `skill-reviewer` to 2.4.0, `memory-tools` to 4.1.0, `code-testing-agent` to 3.5.0, `content-tools` to 1.1.0, `artifact-tools` to 1.9.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Skill core | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/` | References | Created |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Skill core | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/references/` | References | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Skill core | Modified |
| `kit/plugins/artifact-tools/skills/diff-artifact/references/` | References | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Skill core | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/` | References | Created |
| `kit/plugins/social-media-tools/skills/artifact-to-post/SKILL.md` | Skill core | Modified |
| `kit/plugins/social-media-tools/skills/artifact-to-post/references/` | References | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` | Skill core | Modified |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/` | References | Created |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

Skills exceeding 600 words pay a context cost on every invocation: the entire SKILL.md is loaded whether or not the full detail is needed. The progressive-disclosure pattern moves non-critical steps and elaboration into `references/*.md` files that the core links to when needed, keeping the core under 600 words for fast first-read.

The split discipline: everything the model needs before its first action stays in the core (activation conditions, the first step, security gates). Everything the model reads mid-execution can live in references — detailed how-to steps, checklists, examples, edge cases.

The two artifact-tools skills that publish externally (`diff-artifact`, `prompt-artifact`) kept their security-scrub gates in the core because those gates must fire before any action, and a reference step is only read after the model decides to proceed.

The Python word-count fix addresses a real testing portability issue: `wc -w` counts em dashes as word separators in `C` locale but not in `C.UTF-8`, causing ~20-word swings. Python's `len(text.split())` is consistent across locales.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
