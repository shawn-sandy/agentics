# Make plan status flows Markdown-first

> Completing a plan required careful find-and-replace surgery on 84 KB of HTML. Now every status flip and checkbox tick is a one-line Markdown edit and the renderer redraws the page — cheaper, safer, and impossible to get half-right.

<!-- generated:start -->

**Status:** Shipped 2026-07-12 **Plan:** [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
**Type:** refactor

## What shipped

- Extended `scripts/lib/plan-spec.mjs`: parses `- [x]` criteria bullets, `[x]` step markers, and a `## Completion Report` section into a separate `progress` key, without disturbing the content sections object.
- Updated `scripts/lib/plan-shell.mjs` and `scripts/build-plan-html.mjs`: the renderer derives checked inputs, completed step cards, the initial progress bar, `cc1`–`cc3`, `all-complete`, and the report list from the spec's progress state; frozen-string constants demoted to internal.
- Synced byte-identical bundled copies under `kit/plugins/plan-agent/scripts/`.
- Rewrote `skills/finalize-plan/SKILL.md`: when a sibling spec exists, edits the Markdown spec (frontmatter status, checkbox flips, step markers, Completion Report section) and re-renders; legacy HTML fallback kept for plans without a spec.
- Updated `skills/implementation-plan/SKILL.md` Steps 6 and 8: gates flip state in the spec and re-render; HTML attribute-editing instructions removed.
- Updated `skills/implementation-plan/guidelines/section-catalog.md` and `reference/SKELETON.md`: checkbox syntax and Completion Report section documented; criteria start as unchecked checkbox bullets.
- Replaced frozen-string test assertions with behavioral progress assertions in `tests/plugins/test-build-plan-html.mjs`; updated `tests/plugins/test-finalize-all-flag.sh`.
- Bumped plan-agent to 2.20.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Progress key parsing | Modified |
| `scripts/lib/plan-shell.mjs` | Progress-aware rendering | Modified |
| `scripts/build-plan-html.mjs` | Wire progress through render | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Spec-mode edits + legacy fallback | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Spec-state gates | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Checkbox syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Unchecked criteria | Modified |
| `kit/plugins/plan-agent/README.md` | Md-first pipeline docs | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.20.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent → 2.20.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Behavioral progress assertions | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Spec-mode contract | Modified |

## How it works

Before this change, progress state lived only in the HTML: `finalize-plan` did literal find/replace on the `todo` step chip and the report-empty sentence. Re-rendering a spec reset all progress, and three frozen strings had to be kept byte-for-byte.

After this change, progress state lives in the spec's checkbox syntax (`- [x]`, `[x]`, `## Completion Report`). The renderer reads those markers and derives every completion representation — step chip state, progress bar percentage, criteria checklist, report list — mechanically. Re-rendering is now lossless: a re-render from a checked spec produces a fully completed page, every time.

`finalize-plan` detects a sibling spec by checking for a `.md` file alongside the `.html`. When one exists, it edits the Markdown and re-renders. When one is absent (legacy plans), it falls back to the previous HTML attribute surgery.

## How to use it

The improvement is transparent — `finalize-plan` and `implementation-plan` behave the same way from the user's perspective. Plans authored from this version forward are Markdown-first automatically.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-07-12 | refactor(plan-agent): Markdown-first status and checkbox flows — progress from spec, lossless re-render (2.20.0) |

<!-- generated:end -->

## References

- Plan: [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
