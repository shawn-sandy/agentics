# Replace build's grep drift check with a deterministic render check

> Added `--check` mode to `plan-agent-render` that byte-compares rendered HTML and asserts completed-spec consistency, replacing the DOM-selector grep that produced false drift signals.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
**Type:** feature

## What shipped

- Added `--check` mode to `scripts/build-plan-html.mjs` (canonical) and its byte-identical copy `kit/plugins/plan-agent/scripts/build-plan-html.mjs`: renders the spec to memory, compares against the on-disk HTML byte-for-byte (at the same output path), and reports the first differing line with context on each side.
- Extended `--check` with spec-consistency assertions evaluated on the Markdown: for `status: completed` plans, every numbered step must carry `[x]` and every `## Acceptance Criteria` bullet must be `- [x]`. Skipped entirely when status is anything other than `completed`.
- Outputs a fixed PASS/FAIL table (`html`, `steps`, `criteria`) with a summary line; exits 0 only when all rows pass.
- Rewrote `skills/build/references/completion-gates.md` Step 5.3 to a single `plan-agent-render "<stem>.md" -o "<stem>.html" --check` invocation, deleting the five-CSS-selector paragraph that caused false drift signals.
- Applied the same replacement to `skills/finalize-plan/references/write-completions.md`.
- Extended `tests/plugins/test-build-plan-html.mjs` with determinism, stale-HTML, missing-HTML, completed-with-unchecked-criterion, and in-progress-skip cases.
- Bumped plan-agent to 9.4.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | Renderer — `--check` mode added | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Renderer — byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Skill reference — Step 5.3 rewritten | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Skill reference — same gate replaced | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Test — determinism and check-mode cases added | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin README — `--check` documented | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog — 9.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — plan-agent 9.4.0 | Modified |

## How it works

The old Step 5.3 told the model to confirm five CSS selectors in the rendered HTML. A model with no DOM evaluator reaches for `Grep`, which matches CSS source rather than rendered output — so a selector defined in the stylesheet counted as a match even when the plan's HTML was stale. Both false-positive and false-negative outcomes were observed in practice.

`--check` separates the two properties that Step 5.3 conflated. Freshness is a byte comparison: if the on-disk HTML was produced from this spec by the deterministic renderer, it is byte-identical to a fresh in-memory render. The comparison is done at the same output path, not across two paths — `plan-file` and `plan-path` are derived from the output path and are intentionally different across paths, so cross-path normalization would let `--check` pass a file copied in from elsewhere. Determinism at a fixed path was verified by rendering the same spec twice and diffing; byte-identical was confirmed.

Spec consistency is a Markdown question, not an HTML question. For `status: completed`, the check evaluates whether every step checkbox is `[x]` and every acceptance criterion is `- [x]`. This requires no HTML at all and cannot be answered by grepping rendered markup.

The renderer has two homes: `scripts/build-plan-html.mjs` (canonical, what tests import) and `kit/plugins/plan-agent/scripts/build-plan-html.mjs` (bundled copy). The test suite already asserts byte-identical parity; this plan edits the canonical copy and re-copies.

## How to use it

```bash
# Check a plan's HTML is current and spec is consistent
plan-agent-render docs/plans/my-plan.md -o docs/plans/my-plan.html --check

# Output format (passing):
# html    PASS
# steps   PASS
# criteria  PASS
# All checks passed.

# Output format (failing stale HTML):
# html    FAIL  line 42: expected "..." got "..."
# steps   PASS
# criteria  PASS
# 1 check failed.
```

The `--check` flag is invoked automatically by `build` Step 5.3 and `finalize-plan`'s write-completions step.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `1c315692` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83f` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `d9fdb0ba` | 2026-10-10 | feat(git-agent-launcher): add the kit's first mod (0.1.0) (#648) |
| `19a9ae83` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |
| `77aa33e8` | 2026-09-12 | fix(plan-agent): lead the goal prompt with "Goal:" (9.17.2) (#631) |
| `f3be0249` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract (9.14.0–9.17.0) (#628) |
| `22e22800` | 2026-08-30 | fix(plan-agent): unbreak the build completion gate for artifact-only plans (9.10.1) (#610) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
