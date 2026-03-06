# Plan: Optimize code-review-agent Trigger Description

## Context

The `code-review-agent` skill (v2.1.0) has a description field that determines when Claude activates it. The current description may undertrigger, especially since it competes with Claude's built-in code review capabilities. This plan uses the skill-creator's description optimization loop to systematically improve trigger accuracy using eval-driven testing.

**Current description:**
> Reviews code for best practices, bugs, security vulnerabilities, complexity, breaking changes, and potential regressions. Use when the user asks to review code, check a file for problems, review changed files, analyze code quality, assess code complexity, detect breaking changes, check if this change breaks anything, or assess whether a change could cause a regression. Does not cover architecture reviews or testing strategy. Use this skill -- not a built-in code review -- when loaded via plugin.

**Acceptance criteria:** Any measurable improvement over baseline trigger accuracy.

## Steps

### 1. Create workspace and back up original
- `mkdir -p plugins/code-review/skills/code-review-agent-workspace`
- Note git SHA before changes as rollback path
- Save current description to `code-review-agent-workspace/original-description.txt`

### 2. Generate 20 trigger eval queries
Write a JSON file with 10 should-trigger and 10 should-not-trigger queries.

**Should-trigger themes:** direct file review, git diff review, security-focused, bug hunting, breaking change detection, code quality, complexity assessment, casual phrasing, multi-file PR review, regression risk.

**Should-NOT-trigger themes (near-misses):** architecture review, testing strategy, accessibility/WCAG, fix/refactor code, code generation, review test files, performance profiling, documentation review, SKILL.md review, database/schema design.

All queries must be realistic with file paths, personal context, varied formality.

Save to: `code-review-agent-workspace/trigger-eval-queries.json`

### 3. Review queries with user (HTML template)
1. Read `assets/eval_review.html` from skill-creator
2. Replace placeholders: `__EVAL_DATA_PLACEHOLDER__`, `__SKILL_NAME_PLACEHOLDER__`, `__SKILL_DESCRIPTION_PLACEHOLDER__`
3. Write to `/tmp/eval_review_code-review-agent.html` and open
4. User edits, exports to `~/Downloads/eval_set.json`
5. Copy exported file into workspace

### 4. Run optimization loop (background, minimal config)
```bash
python -m scripts.run_loop \
  --eval-set <workspace>/eval_set.json \
  --skill-path <skill-path> \
  --model claude-opus-4-6 \
  --max-iterations 2 \
  --runs-per-query 1 \
  --verbose
```
- Splits 60% train / 40% held-out test
- 1 run per query (faster, ~40 API calls total)
- Up to 2 iterations with extended thinking
- Selects best description by test score (avoids overfitting)
- Optimizer is free to rephrase or drop "use this skill -- not built-in" language

### 5. Apply optimized description
- Show user before/after comparison with scores
- Update `description:` in SKILL.md frontmatter
- Use YAML block scalar (`>`) if description contains special characters
- Review marketplace.json description and README.md — update if significantly diverged

### 6. Version bump (PATCH: 2.1.0 -> 2.1.1)

| File | Change |
|------|--------|
| `plugins/code-review/.claude-plugin/plugin.json` | `"version": "2.1.1"` |
| `.claude-plugin/marketplace.json` | code-review entry `"version": "2.1.1"` |
| `plugins/code-review/CHANGELOG.md` | Add `[2.1.1]` entry |

### 7. Commit
```
fix(plugins/code-review): optimize skill description for trigger accuracy -- bump to v2.1.1
```
Include this plan file in the commit.

## Critical Files

- `plugins/code-review/skills/code-review-agent/SKILL.md` -- description field to update
- `plugins/code-review/.claude-plugin/plugin.json` -- version bump
- `.claude-plugin/marketplace.json` -- version sync (also review its `description` field)
- `plugins/code-review/CHANGELOG.md` -- changelog entry
- `plugins/code-review/README.md` -- review for consistency with new description
- Skill-creator scripts at: `/Users/shawnsandy/.claude/plugins/cache/anthropic-agent-skills/document-skills/7029232b9212/skills/skill-creator/`

## Verification

1. Re-run `run_eval.py` with final description to confirm scores hold
2. `grep -r '"version"' plugins/code-review/.claude-plugin/ .claude-plugin/marketplace.json` -- versions match
3. SKILL.md frontmatter parses correctly (both `name:` and `description:` present, `---` delimiters intact)
4. marketplace.json and README.md descriptions are consistent with updated SKILL.md

## Notes

- Workspace artifacts (`code-review-agent-workspace/`) are test artifacts, not committed
- Model matches current session (`claude-opus-4-6`) per skill-creator docs
- 40% holdout is the default; no changes needed
- Original description backed up for rollback if needed

## Interview Summary

### Key Decisions Confirmed
- **Acceptance threshold**: Any measurable improvement over baseline is sufficient to ship
- **Optimization scope**: Minimal -- 2 iterations, 1 run per query (~40 API calls vs ~300)
- **Fallback on script failure**: Debug and fix Python/CLI issues
- **Self-referential language**: Optimizer is free to keep, rephrase, or drop it

### Open Risks
- 1 run per query trades statistical reliability for speed
- 20 eval queries may not cover full distribution of real user prompts
- marketplace.json and README descriptions could drift (mitigated by step 5 review)

### Recommended Amendments (applied)
- Added backup of original description before changes
- Reduced to `--max-iterations 2 --runs-per-query 1`
- Added marketplace.json and README.md consistency review to step 5
- Added README.md to critical files list
