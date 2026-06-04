# Progressive Disclosure: Extract Review Checklist and Example

> Extracts the Review Checklist and Example Review sections from `code-review-agent/SKILL.md` into `references/` files, improving progressive disclosure and reducing body weight.

<!-- generated:start -->

**Status:** Shipped 2026-04-01   **Plan:** [code-review-progressive-disclosure.md](plans/code-review-progressive-disclosure.md)   **Type:** standard

## What shipped

- New `kit/plugins/code-review/skills/code-review-agent/references/review-checklist.md` — the full six-dimension Review Checklist (previously lines 63–254 of SKILL.md).
- New `kit/plugins/code-review/skills/code-review-agent/references/example-review.md` — complete sample review output (previously lines 299–379).
- `SKILL.md` body reduced to focused workflow instructions with brief directives pointing to the reference files.
- TOC updated to reflect the new structure.
- `code-review` plugin bumped from `3.0.2` → `3.1.0`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/code-review/skills/code-review-agent/SKILL.md` | Skill instructions — reduced body | Modified |
| `kit/plugins/code-review/skills/code-review-agent/references/review-checklist.md` | Six-dimension review checklist | Created |
| `kit/plugins/code-review/skills/code-review-agent/references/example-review.md` | Sample review output | Created |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump to 3.1.0 | Modified |

## How it works

The `code-review-agent` SKILL.md was 396 lines / ~1,844 body words — within the 500-line / 5,000-word limits but front-heavy. The Review Checklist (192 lines covering all six dimensions: quality, bugs, security, best practices, complexity, and breaking changes) and the Example Review (81 lines) together made up ~70% of the body.

Progressive disclosure moves detail to `references/` files that Claude loads on demand. The SKILL.md now contains brief directive blocks:

```markdown
## Review Checklist

Read [references/review-checklist.md](references/review-checklist.md) for the
full six-dimension checklist. Apply each dimension to every file under review.
```

The `review-checklist.md` reference file includes a TOC at the top (required for files ≥100 lines). The extraction brings the SKILL.md body well under 200 lines while keeping the full checklist and example accessible.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `1ada4c7` | 2026-04-01 | feat(plugins/code-review): refactor skill to 10/10 with progressive disclosure v3.1.0 |
| `810b69f` | 2026-04-01 | chore(docs/plans): mark code-review-progressive-disclosure as completed |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |

<!-- generated:end -->

## References

- Plan: [code-review-progressive-disclosure.md](plans/code-review-progressive-disclosure.md)
