# Add Code Complexity Rating to code-review Skill

> Extends the `code-review` skill with a qualitative complexity rating (Low/Medium/High/Very High) surfaced between the Summary and Critical Issues in every review output.

<!-- generated:start -->

**Status:** Shipped 2026-03-03   **Plan:** [add-complexity-rating-code-review-skill.md](plans/add-complexity-rating-code-review-skill.md)   **Type:** feature

## What shipped

- New **Section 5: Code Complexity** checklist added covering structural complexity, coupling & cohesion, and cognitive load dimensions.
- Rating guide table (Low / Medium / High / Very High) with concrete signals for each level.
- `### Complexity Rating` output block added to the Review Format, positioned after Summary and before Critical Issues.
- Multi-file guidance: per-file rating is mandatory; an aggregate rating is added only when reviewing more than 3 files.
- Small-file shortcut: files under ~30 lines with a single responsibility get `Low (trivially simple)` without the full breakdown.
- Scope clarification bullet added: complexity covers code-level coupling and nesting depth, not system architecture.
- Frontmatter `description` updated to include "assess code complexity" as an activation trigger.
- `code-review` plugin bumped from `1.1.0` → `1.2.0`.

> See [CHANGELOG §1.2.0](../kit/plugins/code-review/CHANGELOG.md#120---2026-03-03) for the authoritative feature list.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/code-review/skills/code-review-agent/SKILL.md` | Skill instructions — code-review-agent | Modified |
| `kit/plugins/code-review/CHANGELOG.md` | Plugin changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump 1.1.0 → 1.2.0 | Modified |

## How it works

Section 5 was inserted in `kit/plugins/code-review/skills/code-review-agent/SKILL.md` after the existing Best Practices section. It structures the complexity assessment around three dimensions: **Structural Complexity** (nesting depth, cyclomatic complexity, function length, number of responsibilities), **Coupling & Cohesion** (import count relative to purpose, module interdependence, data flow traceability), and **Cognitive Load** (ease of following logic, chained operations, global/shared mutable state).

The rating guide provides concrete signal thresholds: Low means flat structure with clear data flow; Very High means multiple complexity signals combined where refactoring is strongly advised. Because thresholds like "fewer than 5 dependencies" were too language-specific, the plan chose language-relative framing — "imports typical for the language/framework" — which gives Claude flexibility without false alarms on idiomatic Go or Python imports.

The complexity rating appears in review output right after the Summary section. For multi-file reviews each file gets its own rating; an overall aggregate appears only when more than three files are reviewed, keeping single-file reviews concise.

## How to use it

**Skill activation** — triggers automatically on "review this file", "check code quality", or "assess code complexity". The complexity rating appears automatically in every review:

```markdown
### Complexity Rating
**High** — Deep nesting in `parseConfig()` and `validateSchema()`, combined with
tightly coupled imports from 7 internal modules, drives the rating.
```

**Per-file format for multi-file reviews:**

```markdown
### Complexity Rating
- `src/parser.ts`: **High** — ...
- `src/utils.ts`: **Low** (trivially simple)
- Overall: **Medium**
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `9924d3f` | 2026-04-09 | refactor(kit/plugins): trim allowed-tools to only tools each skill actually uses |

<!-- generated:end -->

## References

- Plan: [add-complexity-rating-code-review-skill.md](plans/add-complexity-rating-code-review-skill.md)
- Changelog: [CHANGELOG §1.2.0](../kit/plugins/code-review/CHANGELOG.md#120---2026-03-03)
