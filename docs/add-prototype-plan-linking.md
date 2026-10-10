# Make a plan and its prototype aware of each other

> Established bidirectional linking between plan specs and their prototypes: a `prototype:` frontmatter key on the plan, a `plan-prototype` meta tag and header link in the rendered HTML, a durable `#proto-model` JSON block in the prototype, and a PostToolUse drift hook that flags when prototype structure diverges from its own model or from its plan's copy.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
**Type:** feature

## What shipped

- Added `<script type="application/json" id="proto-model">` to `PROTOTYPE-SKELETON.html` for the derived data model (keys: `entity`, `fields[]`, `action`, `successSignal`).
- Pinned the `{{SOURCE_PLAN}}` contract in `skills/prototype/SKILL.md` to the repo-relative spec path (`docs/plans/<slug>.md`).
- Extended Step 5 of the prototype skill to substitute `{{PROTO_MODEL}}` with the Step 3 model as compact single-line JSON.
- Added a write-back step to the prototype skill: before writing the prototype HTML, it resolves the plan's `.md` spec and writes single-line `prototype:` and `proto-model:` keys into its frontmatter. Skipped for idea/image/Figma inputs and for plans whose sibling `.md` does not exist (a one-line notice is printed instead).
- Threaded `prototype` through the renderer in both repo-root and plugin-bundle copies: `build-plan-html.mjs` reads `parsed.metadata.prototype`; `plan-shell.mjs` emits a conditional `<meta name="plan-prototype">` and a `View prototype` header anchor using `path.relative()` from the output directory (not a hard-coded `../prototypes/`).
- Added a prototype chip to the plans gallery card in all three byte-identical copies of the index builder (`kit/plugins/plan-agent/hooks/build-index.sh`, `scripts/build-plans-index.sh`, `docs/plans/build-index.sh`). The chip is a `<span>` not an `<a>`, to avoid a nested anchor inside the card's wrapping `<a>`.
- Wrote `kit/plugins/plan-agent/hooks/check-prototype-drift.py`, a PostToolUse hook that runs two comparisons on prototype writes: (A) the prototype's `#proto-model` field names against its rendered `<th>` headers and form field names, and (B) the `#proto-model` against the `proto-model:` frontmatter of the plan named in `proto-source`. Always exits 0; silent on missing files, absent blocks, out-of-tree paths, or malformed JSON.
- Registered the drift check in `hooks/dispatch.py` in the `is_prototype` branch after the existing `build-prototypes-index.sh` call.
- Added `tests/plugins/test-prototype-plan-link.mjs` and `tests/plugins/test-prototype-drift.sh`; extended `tests/plugins/test-build-plan-html.mjs` with back-compat and copy-parity cases.
- Bumped plan-agent from 4.3.1 to 4.4.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/prototype/reference/PROTOTYPE-SKELETON.html` | Added `#proto-model` JSON block | Modified |
| `kit/plugins/plan-agent/skills/prototype/SKILL.md` | Pinned `proto-source` format, model serialisation, write-back step | Modified |
| `scripts/lib/plan-shell.mjs` | `plan-prototype` meta tag and header link (repo-root source) | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical re-copy | Modified |
| `scripts/build-plan-html.mjs` | Thread `prototype` frontmatter key into `metaTags()` and `header()` | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Prototype chip on plans gallery card | Modified |
| `scripts/build-plans-index.sh` | Byte-identical re-copy | Modified |
| `docs/plans/build-index.sh` | Byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/hooks/check-prototype-drift.py` | PostToolUse drift comparison hook | Created |
| `kit/plugins/plan-agent/hooks/dispatch.py` | Fan out to drift check on prototype writes | Modified |
| `kit/plugins/plan-agent/README.md` | New hook and frontmatter keys documented | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 4.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 4.3.1 → 4.4.0 | Modified |
| `tests/plugins/test-prototype-plan-link.mjs` | Objective smoke test | Created |
| `tests/plugins/test-prototype-drift.sh` | Drift-hook cases | Created |
| `tests/plugins/test-build-plan-html.mjs` | Back-compat case for specs without `prototype:` | Modified |

## How it works

The design is intentionally asymmetric. A plan to prototype relationship is regeneration (re-run `/plan-agent:prototype`, which is deterministic); prototype to plan is detection (compare two JSON blobs and report). Full bidirectional sync was rejected because prototypes have no spec file — the HTML is the source — and an HTML-to-model parser over generated files is out of scope.

The `proto-model` JSON block lives in both files. In the prototype it sits in a `<script type="application/json" id="proto-model">` block alongside the existing `#seed` block. In the plan spec it is a single-line `proto-model:` frontmatter key. Both locations hold the same compact JSON: `{"entity":"…","fields":[{"name":"…","type":"…"},…],"action":"…","successSignal":"…"}`. The value must stay on one line because the frontmatter parser is a naive line scanner — a raw newline or bare `---` would silently truncate the block and corrupt `status` and `created` for all consumers.

The write-back step in the prototype skill resolves the plan's `.md` spec by swapping `.html` to `.md` (since the skill takes the plan HTML as input). If the sibling `.md` does not exist — as is the case for 69 of the 84 non-index legacy HTML plans — the prototype is still generated and a notice explains how to create the spec first with `node scripts/extract-plan-spec.mjs`. The write-back has no transaction semantics; concurrent sessions on the same spec are not guarded.

The renderer's `header()` function computes the `View prototype` link href using `path.relative()` from the rendered plan's output directory, not a hard-coded path. This handles both `docs/plans/` and any custom `plansDirectory` correctly. The gallery chip is a `<span>` matching the existing `status-chip`/`type-chip`/`effort-chip` pattern; a nested `<a>` would be invalid HTML.

The drift hook reads the `PostToolUse` JSON payload on stdin, skips immediately for non-prototype paths, and runs two comparisons on prototype writes: field names in `#proto-model` against `<th>` headers and form field `name`/`id` attributes in the same prototype file (catching hand-edits to the prototype's structure), and `#proto-model` against `proto-model:` in the plan named by `proto-source` (catching re-generation from an edited plan). It always exits 0 and is silent on missing data or parse failures, matching every other hook in the plugin.

## How to use it

After running `/plan-agent:prototype docs/plans/my-feature.md`, the plan spec at `docs/plans/my-feature.md` gains two frontmatter lines:

```yaml
prototype: docs/prototypes/my-feature.html
proto-model: {"entity":"Widget","fields":[{"name":"name","type":"string"}],"action":"Create","successSignal":"Widget saved"}
```

The rendered plan at `docs/plans/my-feature.html` shows a **View prototype** link in its header. The plans gallery card shows a prototype chip.

If you later hand-edit the prototype's column headers or form field names, the next tool call that touches the prototype file triggers `check-prototype-drift.py`, which prints a warning naming both files and the diverging field. To re-sync, re-run `/plan-agent:prototype docs/plans/my-feature.md` — regeneration is deterministic.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `88a686a` | 2026-08-28 | fix(plan-agent): make artifact-published plans first-class in review, design, and prototype (#609) |
| `daa72b9` | 2026-08-23 | build-feature: add product content, stories, metrics, rollout, and publishing (#593) |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
