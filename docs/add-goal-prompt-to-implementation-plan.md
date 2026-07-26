# Add outcome-driven goal prompt to implementation plans

> Adds an outcome-driven goal prompt to every generated HTML plan, giving implementers latitude to optimize for the result rather than mechanically follow each step.

<!-- generated:start -->

**Status:** Shipped 2026-06-18 **Plan:** [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- **Goal prompt** — every newly generated HTML plan carries a third copy-paste prompt alongside the existing implement and workflow prompts. It frames the work as an outcome to achieve ("Achieve this goal: … — use the plan as reference, but optimize for the outcome"), giving the implementing agent latitude to deviate from the prescribed steps when a better path to the same result exists.
- **Always present** — unlike the workflow prompt (which is conditional), the goal prompt has no flag or complexity heuristic; every plan gets one. (Why: making it opt-in would cause teams to overlook it on the plans where a freer approach would serve best.)
- **`<meta name="plan-goal">` head tag** — mirrors the visible prompt row as a machine-readable tag so tooling that reads plan metadata can surface the goal without rendering the full HTML.
- **Purple `.plan-goal` drawer** — rendered as a collapsible `<details>` block between the implement (green) and workflow (blue) rows, using the existing `--purple*` design tokens. Hidden in completed plans and suppressed in print, exactly like the other prompt rows.
- **`copyGoal()` clipboard helper** — mirrors the `copyWorkflow()` function; clicking "Copy" writes the goal prompt to the clipboard and briefly changes the button to a green "Copied" state.
- **Smoke test** — `tests/plugins/test-goal-prompt.sh` pins all six assertions: meta tag presence, markup structure, `copyGoal()` wiring, CSS rules (including completed/print hiding), DOM order (`implement → goal → workflow`), and the SKILL.md contract — so the feature cannot silently regress.
- **Version bump and documentation** — `plan-agent` advanced from `2.5.1` to `2.6.0` in `marketplace.json`; a matching CHANGELOG entry and README bullet were added.

> See [CHANGELOG v2.6.0](../kit/plugins/plan-agent/CHANGELOG.md#260--outcome-driven-goal-prompt-on-every-html-plan-2026-06-18) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | HTML plan skeleton — added `.plan-goal` markup, `--purple*` CSS, `copyGoal()` helper, `<meta name="plan-goal">` | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill contract — Step 2 computes `{goal-prompt}`; Step 3 emits `plan-goal` meta; HTML Output Requirements updated | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test pinning the goal prompt to skeleton and SKILL.md | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — `plan-agent` version bumped `2.5.1 → 2.6.0` | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes — 2.6.0 entry added | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — "Goal prompt" capability bullet added | Modified |

## How it works

The `plan-agent:implementation-plan` skill generates a styled HTML plan from a Markdown spec. Before this change, every plan offered two copy-paste prompts: an **implement prompt** (strict, step-by-step) and a conditional **workflow prompt** (parallel subagent orchestration). The goal prompt is a third sibling wired through the same three coordinated surfaces: a `<meta>` head tag, a visible/collapsible body row, and a Step 2 placeholder computed at generation time.

**Step 2 computation in SKILL.md** — `{goal-prompt}` is computed from the plan's condensed objective, plan path, and the standard digest-extraction one-liner (so the pursuing agent reads the spec digest, not the full ~21 KB styled HTML). The computation is unconditional — no flag, no heuristic gates it.

**SKELETON.html changes** — the `<head>` gains `<meta name="plan-goal" content="{goal-prompt}">`. In `<body>`, a new `.plan-goal` `<details>` block is inserted between the `.plan-implement` and `.plan-workflow` rows. It uses `--purple` / `--purple-bg` / `--purple-border` CSS custom properties that were already in the design token set, so no new color infrastructure was required. The block's `<summary>` reads "Pursue as goal — optimize for the outcome"; the inner `<code id="goal-cmd">` holds the filled prompt; a `<button onclick="copyGoal(this)">` provides one-click copy. Two CSS rules suppress the row when `data-status="completed"` is set on the plan root and in `@media print`.

**`copyGoal()` function** — a direct mirror of the existing `copyWorkflow()`: reads `#goal-cmd`, writes to `navigator.clipboard.writeText`, and briefly applies a `.copied` CSS class to the button for visual feedback.

**Test contract in `test-goal-prompt.sh`** — six assertions covering: the `<meta name="plan-goal">` head tag, the `.plan-goal` / `#goal-cmd` / `copyGoal(this)` / aria-label / `{goal-prompt}` markup bundle, the `copyGoal()` function reading `#goal-cmd`, the `.plan-goal` CSS block plus both hiding rules, DOM order (`implement` index < `goal` index < `workflow` index, verified with a short Python snippet), and the SKILL.md contract (`Achieve this goal:`, `plan-goal`, `copyGoal(this)` all present). All six passed at acceptance time.

**Versioning** — `plan-agent` advanced from `2.5.1` (a metadata-only patch that backfilled the description-optimization version) to `2.6.0` (minor bump, new user-visible surface), consistent with the project's semver convention.

## How to use it

The goal prompt is automatic — every plan generated by `plan-agent:implementation-plan` after this change ships with it.

**In the rendered HTML plan:**
1. Open the "More ways to run this plan" `<details>` drawer (below the green Implement row).
2. The purple "Pursue as goal" section appears; click **Copy** to copy the prompt.
3. Paste into a new conversation or a `/run` invocation — the agent receives latitude to reach the objective by a different route if it finds a better one.

**The generated prompt shape:**
```
Achieve this goal: <objective>. Use the plan at <plan-path> as reference,
but optimize for the outcome — you are not required to follow the steps literally.
Read the spec digest first: …
```

The digest-extraction clause keeps the prompt token-efficient: the implementing agent reads the compact spec rather than the full styled HTML.

**Via meta tag (programmatic use):**
```bash
# Extract the goal prompt from a generated plan (portable)
python3 -c "import re,sys; m=re.search(r'<meta name=\"plan-goal\" content=\"([^\"]+)\"',open(sys.argv[1]).read()); print(m.group(1) if m else '')" my-plan.html
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `9cacc21` | 2026-07-13 | feat(git-agent,plan-agent): plan source for create-issue + end-of-plan issue option (#391) |
| `bfa5098` | 2026-07-13 | feat(plan-agent,git-agent): per-skill model pinning + shorter plan-agent description (#395) |
| `05daec9` | 2026-07-16 | feat(plan-agent): require objective verification in plan prompts (3.1.0) (#417) |
| `a738845` | 2026-07-18 | feat(plan-agent): guarantee every plan has a runnable completion check (#428) |
| `59943f5` | 2026-07-20 | feat(plan-agent): add build skill for implementing existing plans (#435) |

_Note: the initial shipping commit (2026-06-18) predates this clone's history depth; the rows above are subsequent changes to the same files._

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
- Changelog: [CHANGELOG v2.6.0](../kit/plugins/plan-agent/CHANGELOG.md#260--outcome-driven-goal-prompt-on-every-html-plan-2026-06-18)
- Related docs: [plugin-auto-load-setup.md](plugin-auto-load-setup.md)
