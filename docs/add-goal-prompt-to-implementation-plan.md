# Add outcome-driven goal prompt to implementation plans

> Adds a third copy-paste prompt — "Pursue as goal: optimize for the outcome" — to every generated HTML plan, wired through the same meta tag, rendered row, and Step 2 computation as the implement and workflow prompts.

<!-- generated:start -->

**Status:** Shipped 2026-06-18 **Plan:** [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- Added an always-present **outcome-driven goal prompt** to every generated HTML plan as a third sibling alongside the implement and workflow prompts. The prompt frames the work as a goal ("Achieve this goal: … — use the plan as reference, but optimize for the outcome"), giving implementers latitude to deviate when a better path to the same result exists.
- Wired the goal prompt through three coordinated surfaces: an always-emitted `<meta name="plan-goal">` head tag, a `.plan-goal` `<div>` row rendered in the HTML body between the implement and workflow rows using purple `--purple*` CSS design tokens, and a `copyGoal()` clipboard helper mirroring `copyWorkflow()` (why: all three prompts follow the same copy-paste contract so they behave identically for the implementer).
- Updated the `implementation-plan` SKILL.md contract so Step 2 always computes `{goal-prompt}` and Step 3 always emits the `plan-goal` meta tag — no flag, no complexity heuristic (why: the skeleton change is inert unless the model is explicitly told to compute and fill the placeholder).
- Added `tests/plugins/test-goal-prompt.sh` (6 assertions) to pin the feature to the skeleton and SKILL.md contract so the three prompt rows cannot silently diverge.
- Bumped `plan-agent` from `2.5.1` → `2.6.0` in `marketplace.json` and added a CHANGELOG and README entry.

> See [CHANGELOG v2.6.0](../kit/plugins/plan-agent/CHANGELOG.md#260--outcome-driven-goal-prompt-on-every-html-plan-2026-06-18) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | HTML template skeleton — receives `.plan-goal` markup block, CSS, `copyGoal()` function, and `<meta name="plan-goal">` | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions — Step 2 and Step 3 updated to compute and emit goal prompt unconditionally | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test — 6 assertions pin meta tag, markup, JS wiring, CSS rules, DOM order, and SKILL.md contract | Created |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bumped 2.5.1 → 2.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog — 2.6.0 entry added | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin README — "Goal prompt" bullet added to feature list | Modified |

## How it works

**SKELETON.html changes (2.6.0).** The skeleton at `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` is the single source every plan is filled from; the feature had to live there to appear in all future plans. Three additions were made: a `<meta name="plan-goal" content="{goal-prompt}">` tag in `<head>`, a `.plan-goal` `<div>` row in the body positioned between the existing `.plan-implement` and `.plan-workflow` rows, and a `copyGoal()` JavaScript function. The CSS for `.plan-goal` reuses the `--purple*` design tokens already in the skeleton, so no new colour variables were needed.

**Post-2.18.0 structural change.** In v2.18.0 (PR #387, 2026-07-12) the rendering model changed from placeholder fill to a Markdown-spec renderer (`build-plan-html.mjs`). Alongside that, `.plan-goal` was moved inside a `<details class="plan-more-ways">` collapsed drawer ("More ways to run this plan") that also contains `.plan-workflow`. The `.plan-implement` row remains a standalone sibling outside the drawer. The `{goal-prompt}` placeholder is now computed by `build-plan-html.mjs` from the spec's objective rather than filled by the model. Developers working on the current rendering flow should refer to `build-plan-html.mjs` and the `plan-more-ways` drawer, not the standalone-row layout described above.

**Prompt row markup (2.6.0).** The `.plan-goal` div contains a `<code id="goal-cmd">` element holding the `{goal-prompt}` placeholder, and a button with `onclick="copyGoal(this)"` and `aria-label="Copy goal prompt to clipboard"`. This mirrors the markup contract for the implement and workflow rows, making the three prompts copy-paste interchangeable.

**Hiding on completion and in print.** The CSS includes `[data-status="completed"] .plan-goal { display: none; }` (the same rule that hides implement and workflow prompts when a plan is marked done) and `@media print { .plan-goal { display: none !important; } }`. Both rules are checked for presence by assertion 4 of `test-goal-prompt.sh` (via `grep -q` substring matches) so they cannot be silently removed.

**SKILL.md contract update.** The `implementation-plan` SKILL.md at `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` was updated so Step 2 always derives `{goal-prompt}` — computed from the condensed objective, the plan path, and the digest-extraction one-liner already used for the implement prompt — and Step 3 unconditionally emits the `plan-goal` meta tag and the `.plan-goal` HTML block. HTML Output Requirements were extended to list `plan-goal` among the always-present meta tags. This is the critical coupling: the skeleton change alone is inert unless the skill body instructs the model to fill the placeholder.

**Digest-extraction clause.** Like the implement and workflow prompts, the goal prompt carries the same digest-extraction clause (`$(awk …)` one-liner that reads the plan's machine-readable spec digest). This means the pursuing agent reads only the condensed spec, not the full ~21k styled HTML, keeping the prompt self-contained for large plans.

**Smoke test.** `tests/plugins/test-goal-prompt.sh` runs 6 ordered assertions: (1) meta tag present in SKELETON.html head, (2) `.plan-goal` class, `#goal-cmd` id, `copyGoal(this)` onclick, and "Pursue as goal" summary text all present, (3) `copyGoal()` defined and reads `#goal-cmd`, (4) CSS block + completed-hide + print-hide rules present, (5) DOM order is `implement → goal → workflow` (verified via a Python inline script), (6) SKILL.md documents the goal prompt format, `plan-goal` meta, and `copyGoal(this)` wiring. The test does not require a running plan generation — it inspects the static skeleton and skill files directly.

## How to use it

Every HTML plan generated by `/plan-agent:implementation-plan` automatically includes the goal prompt. No flag or option is needed.

The goal prompt appears in the rendered plan inside the "More ways to run this plan" collapsed drawer (`<details class="plan-more-ways">`), alongside the workflow prompt. Open the drawer to reveal the "Pursue as goal — optimize for the outcome" row (purple accent). Clicking "Copy" copies the outcome-framed prompt to the clipboard for pasting into a new session.

The `<meta name="plan-goal">` tag in the plan's `<head>` carries the same prompt text in machine-readable form, accessible via:

```js
document.querySelector('meta[name="plan-goal"]').content
```

The goal prompt is suppressed when `data-status="completed"` is set on the plan root (plans marked done no longer need execution prompts) and is hidden in print.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `5de9c6a` | 2026-07-12 | feat(plan-agent): guidelines library + markdown-first SKILL.md rewrite (2.19.0) |
| `58f9092` | 2026-07-02 | fix(plan-agent): trim finalize-plan skill description to 200-char budget (2.13.1) |

_Original shipping commits from 2026-06-18 predate the repository's current visible git history. The table above shows subsequent commits that touched the same files. Run `git log` against `kit/plugins/plan-agent/CHANGELOG.md` for the full authoring record._

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
- Changelog: [CHANGELOG v2.6.0](../kit/plugins/plan-agent/CHANGELOG.md#260--outcome-driven-goal-prompt-on-every-html-plan-2026-06-18)
- Related docs: [guides/document-implementation-plan-skill.md](plans/guides/document-implementation-plan-skill.md)
