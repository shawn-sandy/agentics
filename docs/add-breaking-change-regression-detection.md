# Add Breaking Changes & Regression Detection to code-review-agent

> Adds a dedicated "Breaking Changes & Regressions" checklist section and output section to the `code-review-agent` skill, making API breakage and regression risk first-class review concerns.

<!-- generated:start -->

**Status:** Shipped 2026-03-05   **Plan:** [add-breaking-change-regression-detection.md](plans/add-breaking-change-regression-detection.md)   **Type:** feature

## What shipped

- A new **Section 6: Breaking Changes & Regressions** checklist added to `code-review-agent/SKILL.md` covering four sub-categories: public API surface, shared/internal contracts, data & config contracts, and regression risk (with call site blast-radius guidance).
- A matching `### Breaking Changes & Regressions` output section added to the Review Format, placed between Complexity Rating and Critical Issues.
- No-duplicate rule added: breaking changes listed in the new section are omitted from Critical Issues to avoid double-reporting.
- No-git-context fallback included: when git history is unavailable, API surface is assessed visually from the reviewed code.
- DB schema checks marked conditional — apply only when reviewing migration files or schema definitions.
- `code-review` plugin bumped from `2.0.0` → `2.1.0`.

> See [CHANGELOG v2.1.0](../kit/plugins/code-review/CHANGELOG.md#210---2026-03-05) for the authoritative feature list.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/code-review/skills/code-review-agent/SKILL.md` | Skill instructions — code-review-agent | Modified |
| `kit/plugins/code-review/CHANGELOG.md` | Plugin changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump 2.0.0 → 2.1.0 | Modified |

## How it works

The plan added a sixth checklist section to the `code-review-agent` skill. Section 6 is structured around four risk dimensions. **Public API Surface** checks whether exported functions, classes, or types were renamed or removed, whether signatures changed (added/removed/reordered params), whether return types shifted, and whether error-throwing behavior changed in ways callers won't handle. **Shared/Internal Contracts** covers widely-used utilities, base classes, interfaces, and default argument values. **Data & Config Contracts** targets environment variable renames, serialized format changes, and database schema changes. **Regression Risk** surfaces code that previously had bugs fixed, shared mutable state modifications, and broken invariants.

The output section mirrors the checklist structure. For each detected issue it reports: what changed (the specific symbol, config key, or schema field), who is affected (call sites and dependents), severity (Breaking vs. Risky), and the migration path for callers. If nothing is detected the section prints `No breaking changes or regression risks identified.`

A key design decision from the plan interview was to suppress duplication: a breaking change that would otherwise appear in both this section and Critical Issues is kept only in Section 6. This keeps the review output clean and avoids the same finding being counted twice.

The `description` frontmatter was updated to add "breaking changes" and "regressions" as activation triggers, phrased around intent (`"check if this change breaks anything"`) rather than raw keywords to reduce false-positive activations.

## How to use it

**Skill activation** — triggers automatically when you ask to "review my changed files", "check for breaking changes", or "could this cause a regression". Direct invocation:

```
/code-review:code-review-agent
```

**Output section format:**

```markdown
### Breaking Changes & Regressions

- **What changed**: `getUserById` removed from `lib/users.ts`
- **Who is affected**: 4 call sites across `api/handlers/` and `tests/`
- **Severity**: Breaking — callers will fail at runtime
- **Migration path**: Replace with `findUser({ id })` from `lib/users-v2.ts`
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |

<!-- generated:end -->

## References

- Plan: [add-breaking-change-regression-detection.md](plans/add-breaking-change-regression-detection.md)
- Changelog: [CHANGELOG v2.1.0](../kit/plugins/code-review/CHANGELOG.md#210---2026-03-05)
