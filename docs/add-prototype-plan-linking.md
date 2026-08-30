# Make a plan and its prototype aware of each other

> Give every plan a back-link to its prototype, persist the prototype's derived data model in both files, and add a `PostToolUse` hook that flags when a prototype has drifted from its plan's copy of the model.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [add-prototype-plan-linking](plans/add-prototype-plan-linking.md)
**Type:** feature

## What shipped

- Added a `#proto-model` JSON block to `PROTOTYPE-SKELETON.html` so every generated prototype carries a durable, machine-readable data model.
- Extended `skills/prototype/SKILL.md` to pin the `{{SOURCE_PLAN}}` contract format, serialize the derived model into `{{PROTO_MODEL}}`, and write `prototype:` and `proto-model:` back into the source plan's frontmatter.
- Threaded the `prototype` frontmatter key through both copies of `build-plan-html.mjs` and `plan-shell.mjs`, rendering a `plan-prototype` meta tag and a "View prototype" header anchor with correct relative `href`.
- Added a prototype chip (non-anchor, accessible text) to all three byte-identical copies of the plans gallery builder.
- Wrote `hooks/check-prototype-drift.py`, a `PostToolUse` hook that compares the prototype's `#proto-model` against its DOM and against the plan's frontmatter copy, reporting divergence by name.
- Registered the drift check in `hooks/dispatch.py` on the `is_prototype` fan-out branch.
- Bumped plan-agent from 4.3.1 to 4.4.0.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/prototype/reference/PROTOTYPE-SKELETON.html` | Added `#proto-model` JSON block | Modified |
| `kit/plugins/plan-agent/skills/prototype/SKILL.md` | Pinned `proto-source` format, model serialization, frontmatter write-back | Modified |
| `scripts/lib/plan-shell.mjs` | Optional `plan-prototype` meta tag and header link (repo-root source) | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical re-copy | Modified |
| `scripts/build-plan-html.mjs` | Thread `prototype` key into `metaTags()` and `header()` (repo-root source) | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Prototype chip on plans gallery card | Modified |
| `scripts/build-plans-index.sh` | Byte-identical re-copy | Modified |
| `docs/plans/build-index.sh` | Byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/hooks/check-prototype-drift.py` | Drift comparison hook | Created |
| `kit/plugins/plan-agent/hooks/dispatch.py` | Fan-out to drift check on prototype writes | Modified |
| `kit/plugins/plan-agent/README.md` | Documented new hook and `prototype:`/`plan-prototype` keys | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 4.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 4.3.1 → 4.4.0 | Modified |
| `tests/plugins/test-prototype-plan-link.mjs` | Objective smoke test for renderer and gallery changes | Created |
| `tests/plugins/test-prototype-drift.sh` | Drift-hook branch coverage | Created |
| `tests/plugins/test-build-plan-html.mjs` | Back-compat case for specs with no `prototype:` key | Modified |

## How it works

`/plan-agent:prototype` already stamped `<meta name="proto-source">` into every prototype it generated, and `build-prototypes-index.sh` rendered it as a gallery "from `<plan>`" chip. That link was one-directional: a plan had no knowledge of any prototype that pointed at it, and neither file held the data model they shared.

`PROTOTYPE-SKELETON.html` now carries a `<script type="application/json" id="proto-model">{{PROTO_MODEL}}</script>` block immediately after the existing `#seed` block at line 63. Step 3 of the prototype skill derives the model — entity, fields with inferred types, primary action, success signal — and Step 5 now substitutes `{{PROTO_MODEL}}` with compact single-line JSON using the same script-breakout escaping rule already documented for `{{SEED_JSON}}`.

Step 4 of the prototype skill was extended with a write-back phase that runs before the prototype HTML is written. It resolves the plan-path input's `.html` to its sibling `.md` spec by extension swap and writes `prototype: docs/prototypes/<slug>.html` plus `proto-model: <compact single-line JSON>` into that spec's frontmatter. The JSON is enforced to stay on one line because the frontmatter parser in `plan-spec.mjs` is a naive line scanner and an embedded newline would silently truncate `status` and `created`. When the sibling `.md` does not exist the write-back is skipped, the prototype is still written, and a one-line notice directs the user to `node scripts/extract-plan-spec.mjs`.

`build-plan-html.mjs` and `plan-shell.mjs` were extended to read `parsed.metadata.prototype`, emit `<meta name="plan-prototype">` conditionally, and render a `View prototype` anchor inside `.plan-header-actions` beside the effort badge. The `href` is computed with `path.relative()` from the rendered plan's output directory to the repo-relative `prototype:` target so that custom `plansDirectory` configurations resolve correctly. Every change was applied to the repo-root sources first, then re-copied byte-for-byte to the bundled plugin copies, because `tests/plugins/test-build-plan-html.mjs:557` asserts the copies are identical.

All three byte-identical gallery builders (`kit/plugins/plan-agent/hooks/build-index.sh`, `scripts/build-plans-index.sh`, `docs/plans/build-index.sh`) received a prototype chip on the plans gallery card. The chip is a `<span>` matching the existing `status-chip`/`type-chip`/`effort-chip` pattern — not an anchor, because the whole card is already wrapped in `<a class="gallery-card">` and a nested `<a>` is invalid HTML.

`hooks/check-prototype-drift.py` reads `PostToolUse` JSON from stdin and runs two comparisons: the prototype's `#proto-model` field names against the `<th>` headers and form field `name`/`id` attributes in the same file, and the prototype's `#proto-model` against the `proto-model:` frontmatter of the plan named in `proto-source`. It always exits 0, staying silent when either model is absent or fails to parse, and naming both files and the diverging field when reporting. It was registered in `dispatch.py` after the existing `build-prototypes-index.sh` call on the `is_prototype` branch so it shares the same 55-second deadline without requiring a `hooks.json` change.

## How to use it

The changes are automatic when using the plan-agent plugin. After generating a prototype with `/plan-agent:prototype docs/plans/<slug>.md`, the plan spec at `docs/plans/<slug>.md` will contain new frontmatter keys that the renderer and gallery pick up on the next build:

```yaml
prototype: docs/prototypes/<slug>.html
proto-model: {"entity":"...","fields":[...],"action":"...","successSignal":"..."}
```

The drift hook fires automatically on every prototype write via the `PostToolUse` dispatch. To run the tests:

```bash
node tests/plugins/test-prototype-plan-link.mjs
bash tests/plugins/test-prototype-drift.sh
node tests/plugins/test-build-plan-html.mjs
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `df49b6d` | 2026-08-12 | feat(settings-sync): restore onto a new machine via clone URL (1.1.0) (#548) |

<!-- generated:end -->

## References

- Plan: [add-prototype-plan-linking](plans/add-prototype-plan-linking.md)
