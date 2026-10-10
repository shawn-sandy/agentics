# Make a plan and its prototype aware of each other

> Adds bidirectional linking between plans and their prototypes, persists the derived data model in both files, and introduces a drift hook that detects when a prototype's rendered structure has diverged from its model.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
**Type:** feature

## What shipped

- Added a `<script type="application/json" id="proto-model">` block to `PROTOTYPE-SKELETON.html` to give the derived data model a durable, machine-readable home alongside the existing `#seed` block.
- Pinned the `{{SOURCE_PLAN}}` format contract in `skills/prototype/SKILL.md` to the repo-relative path of the plan's markdown spec (`docs/plans/<slug>.md`), enabling the drift hook to resolve the owning plan reliably.
- Extended `skills/prototype/SKILL.md` Step 5 to substitute `{{PROTO_MODEL}}` with the Step 3 model serialized as compact single-line JSON (keys: `entity`, `fields`, `action`, `successSignal`), using the same script-breakout escaping rule already documented for `{{SEED_JSON}}`.
- Added a write-back step that runs before prototype HTML is written, resolving the plan's `.md` sibling by extension swap and writing single-line `prototype:` and `proto-model:` keys into that plan's frontmatter; the step is skipped for idea, image, and Figma inputs, and for plans with no sibling `.md` (with a printed notice explaining how to get the back-link via `extract-plan-spec.mjs`).
- Threaded `prototype` through the renderer: `build-plan-html.mjs` reads `parsed.metadata.prototype` and passes it to `shell.metaTags()` (emits `<meta name="plan-prototype">`) and `shell.header()` (renders a `View prototype` anchor in `.plan-header-actions` with computed `path.relative()` href — never a hard-coded `../prototypes/` that would break custom `plansDirectory` configurations).
- Added a prototype chip to all three byte-identical copies of the plans gallery builder — `kit/plugins/plan-agent/hooks/build-index.sh`, `scripts/build-plans-index.sh`, and `docs/plans/build-index.sh` — as a text-bearing `span` (not an `<a>`, since the card is already wrapped in `<a class="gallery-card">`).
- Wrote `hooks/check-prototype-drift.py` to compare a prototype's `#proto-model` field names against its own `<th>` headers and form field attributes, and against the `proto-model:` frontmatter of the plan named in its `proto-source`; the hook always exits 0 and stays silent when either file is absent, unparseable, or resolves outside the plans directory.
- Registered the drift check in `dispatch.py`'s `is_prototype` branch after the existing `build-prototypes-index.sh` call.
- Added `tests/plugins/test-prototype-plan-link.mjs` and `tests/plugins/test-prototype-drift.sh`, extended `tests/plugins/test-build-plan-html.mjs` with back-compat cases, and bumped plan-agent from 4.3.1 to 4.4.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/prototype/reference/PROTOTYPE-SKELETON.html` | `#proto-model` JSON block | Modified |
| `kit/plugins/plan-agent/skills/prototype/SKILL.md` | `proto-source` format contract, model serialization, write-back step | Modified |
| `scripts/lib/plan-shell.mjs` | Optional `plan-prototype` meta tag and header link (repo-root source) | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical re-copy | Modified |
| `scripts/build-plan-html.mjs` | Threads `prototype` frontmatter key into `metaTags()` and `header()` | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Prototype chip on plans gallery card | Modified |
| `scripts/build-plans-index.sh` | Byte-identical re-copy | Modified |
| `docs/plans/build-index.sh` | Byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/hooks/check-prototype-drift.py` | Drift comparison hook | Created |
| `kit/plugins/plan-agent/hooks/dispatch.py` | Fan-out to drift check on prototype writes | Modified |
| `kit/plugins/plan-agent/README.md` | Documents the drift hook and `prototype:` / `plan-prototype` keys | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 4.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 4.3.1 to 4.4.0 | Modified |
| `tests/plugins/test-prototype-plan-link.mjs` | Objective smoke test | Created |
| `tests/plugins/test-prototype-drift.sh` | Drift-hook case coverage | Created |
| `tests/plugins/test-build-plan-html.mjs` | Back-compat cases for specs with no `prototype:` key | Modified |

## How it works

The design is deliberately asymmetric. Plans are markdown-source plus rendered HTML; prototypes have no spec file, so the HTML is the source. Propagating a prototype edit back into plan prose would require an HTML-to-model parser over generated files, which the project rules forbid. The contract is: plan-to-prototype is regeneration (re-run `/plan-agent:prototype`, which Step 3 guarantees is deterministic); prototype-to-plan is detection (compare two JSON blobs and report).

The `#proto-model` JSON block in `PROTOTYPE-SKELETON.html` is the durable anchor. Step 5 of the prototype skill substitutes `{{PROTO_MODEL}}` with the data model derived in Step 3, serialized as compact single-line JSON. The single-line constraint is required by the frontmatter parser in `plan-spec.mjs`, which is a naive line scanner — an embedded newline or `---` would silently truncate the block and corrupt `status` and `created` for all three consumers that re-scan the frontmatter.

The write-back step resolves the plan's `.md` sibling by swapping the `.html` extension on the plan-path input. For the 69 of 84 non-index plans that are legacy HTML with no sibling `.md`, the step is skipped entirely — the prototype is still written, but no spec is created or modified, and a notice is printed explaining how to get the back-link via `node scripts/extract-plan-spec.mjs`.

The renderer threads `prototype` through two new call sites. `shell.metaTags()` emits `<meta name="plan-prototype" content="…">` when the key is present. `shell.header()` computes a `path.relative()` href from the rendered plan's output directory to the `prototype:` target, ensuring the link resolves correctly when plans live in a custom `plansDirectory` — a hard-coded `../prototypes/` would resolve to `custom/prototypes/` for a plan rendered under `custom/plans/`. Both files were re-copied byte-for-byte into `kit/plugins/plan-agent/scripts/` because `tests/plugins/test-build-plan-html.mjs:557` asserts parity.

The gallery chip is a `span` with non-empty text rather than an `<a>`, because the whole card is already wrapped in `<a class="gallery-card">` and a nested anchor is invalid HTML that browsers silently unnest, breaking the card's click target. The identical change lands in all three copies of the gallery builder — a regeneration through any un-updated copy would overwrite an index that already had the chip.

`check-prototype-drift.py` runs two comparisons: the prototype's `#proto-model` field names against the `<th>` headers and form field `name`/`id` attributes in that same file (catching hand-edits to the rendered columns), and the prototype's `#proto-model` against the `proto-model:` frontmatter of the plan its `proto-source` names (catching divergence between the two files' copies). The Python-side frontmatter read uses a single-line regex (`^proto-model:\s*(.*)$` then `json.loads`), following the pattern in `validate-plan-filename.py`'s `_is_completed`, rather than a general YAML parser that would silently diverge from the JS parser in `plan-spec.mjs` over time. The hook always exits 0 — never exit 2 — so a drift warning about an unrelated plan never interrupts whatever the user is actually doing.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `88a686a` | 2026-08-28 | fix(plan-agent): make artifact-published plans first-class in review, design, and prototype (#609) |
| `daa72b9` | 2026-08-23 | build-feature: add product content, stories, metrics, rollout, and publishing (#593) |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `e1e8840` | 2026-08-15 | feat(git-agent): add post-merge-cleanup skill (4.19.0) (#565) |

<!-- generated:end -->

## References

- Plan: [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
