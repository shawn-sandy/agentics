# Make plan status and checkbox flows Markdown-first

> Points `finalize-plan` and the implementation-plan status/checkbox gates at the Markdown spec — checkbox flips plus frontmatter edits plus a re-render — retiring the byte-for-byte frozen-string contracts that HTML surgery depended on.

<!-- generated:start -->

**Status:** Shipped 2026-07-12 **Plan:** [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
**Type:** refactor

## What shipped

- Extended `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` to read `- [x]` criteria bullets, `[x]` step markers, and a `## Completion Report` section into a `progress` key.
- Updated `plan-shell.mjs` and `build-plan-html.mjs` to render progress state — checked inputs, completed step cards, progress bar, derived completion checklist, and report list — from the spec.
- Synced byte-identical bundled renderer copies under `kit/plugins/plan-agent/scripts/`.
- Rewrote `finalize-plan/SKILL.md` around spec mode (frontmatter status, checkbox flips, step markers, Completion Report, explicit re-render) with a legacy HTML fallback.
- Updated `implementation-plan/SKILL.md` Steps 6 and 8 to flip state in the spec and re-render.
- Replaced byte-for-byte frozen-string tests with behavioral progress assertions.
- Bumped `plan-agent` to `2.20.0`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Spec parser | Modified |
| `scripts/lib/plan-shell.mjs` | HTML renderer | Modified |
| `scripts/build-plan-html.mjs` | Build script | Modified |
| `kit/plugins/plan-agent/scripts/` (3 files) | Bundled copies | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Section syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Spec template | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Test suite | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Test suite | Modified |

## How it works

Before this change, plan completion state lived only in the rendered HTML: `finalize-plan` did literal find-and-replace on frozen strings like the `todo` step chip, and re-rendering a spec reset all progress. This kept three strings pinned byte-for-byte and made every status edit an attribute-surgery exercise.

After this change, `- [x]` checkbox syntax in the Markdown spec carries the state. `parseSpecMarkdown` extracts it into a `progress` key returned alongside `sections`. The renderer reads `progress` and derives all representations — checked `<input>` elements, completed step cards, the `cc1–cc3` criteria completion state, the progress bar, and the Completion Report — mechanically. Re-rendering a spec is now lossless: the HTML matches the spec every time.

`finalize-plan` now edits the Markdown spec and re-renders when a sibling spec exists. For legacy plans without a spec, the old HTML editing path remains as a fallback.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
- Changelog: [plan-agent CHANGELOG v2.20.0](../kit/plugins/plan-agent/CHANGELOG.md)
