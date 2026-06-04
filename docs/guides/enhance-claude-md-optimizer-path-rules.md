# Enhance claude-md-optimizer Plugin with Memory Docs Guidance

> Enhances the `claude-md-optimizer` skill's Step 5 to offer `.claude/rules/` file generation for extracted content, adds `@import` callout, and documents brace expansion for path patterns.

<!-- generated:start -->

**Status:** Shipped 2026-02-24   **Plan:** [enhance-claude-md-optimizer-path-rules.md](plans/enhance-claude-md-optimizer-path-rules.md)   **Type:** artifact

## What shipped

- Step 5 now offers to generate `.claude/rules/` files for each section extracted during optimization, with per-file write confirmation and `.claude/rules/` directory creation if needed.
- `@import` callout added to Step 5 output (after the CLAUDE.md code block, not inside it) showing how to reference the optimizer SKILL.md from a project.
- Dimension 4 examples updated with `paths:` frontmatter glob patterns and brace expansion (`src/**/*.{ts,tsx}`, `{src,lib}/**/*.ts`) from the official memory docs.
- Step 4 Top 3 Recommendations: standing recommendation added when Dimension 4 scores ≤ 1 ("Use Step 5's rule-file generation to break path-specific content into `.claude/rules/` files").
- `path-rules-advisor` SKILL.md: brace expansion examples added to the Rule file format section.
- `## Suggested Move to Separate Files` block removed from Step 5 — replaced by the new rule-file offer flow.
- Notes section updated with official memory docs URL and self-referencing `@import` usage tip.
- `claude-md-optimizer` plugin bumped from `1.2.0` → `1.3.0`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md` | Skill instructions — Dimension 4, Step 4, Step 5, Notes | Modified |
| `kit/plugins/claude-md-optimizer/skills/path-rules-advisor/SKILL.md` | Skill instructions — brace expansion | Modified |
| `kit/plugins/claude-md-optimizer/.claude-plugin/plugin.json` | Plugin manifest — version bump 1.2.0 → 1.3.0 | Modified |
| `kit/plugins/claude-md-optimizer/CHANGELOG.md` | Plugin changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump to 1.3.0 | Modified |

## How it works

The key change is in Step 5: instead of a static `## Suggested Move to Separate Files` block (which listed candidates without acting on them), the skill now iterates over extracted sections and offers to generate a corresponding `.claude/rules/<name>.md` file for each. The generated file includes `paths:` frontmatter derived from the section's scope, followed by the extracted rules as bullets. The skill checks whether `.claude/rules/` exists and prompts to create it if not. Per-file confirmation is required before any write.

The `@import` callout is positioned after the generated CLAUDE.md code block to avoid confusion — it's a separate "once you're done" instruction showing users how to keep the optimizer self-referencing in their project via `@<plugin-dir>/skills/claude-md-optimizer/SKILL.md`.

The Step 4 → Step 5 connection was a gap: the old behavior flagged "Progressive Disclosure" as a problem in Dimension 4 but the Step 5 output didn't explicitly connect the two. The new standing recommendation bridges this.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |

<!-- generated:end -->

## References

- Plan: [enhance-claude-md-optimizer-path-rules.md](plans/enhance-claude-md-optimizer-path-rules.md)
