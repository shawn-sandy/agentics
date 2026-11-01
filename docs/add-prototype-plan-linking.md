# Make a plan and its prototype aware of each other

> Gives every plan a back-link to its prototype, persists the prototype's derived data model in both files, and adds a PostToolUse hook that flags when a prototype has drifted from its own model or from its plan's copy.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
**Type:** feature

## What shipped

- Added `<script type="application/json" id="proto-model">{{PROTO_MODEL}}</script>` to `PROTOTYPE-SKELETON.html` for a durable machine-readable model block in every generated prototype.
- Extended `skills/prototype/SKILL.md` to pin the `{{SOURCE_PLAN}}` format (repo-relative path, not free text) and substitute `{{PROTO_MODEL}}` with the Step 3 model serialized as compact single-line JSON.
- Added a write-back step to the prototype skill: before the prototype HTML is written in Step 6, writes `prototype:` and `proto-model:` as single-line frontmatter keys into the plan's `.md` spec. Skips gracefully when the sibling `.md` does not exist and prints a notice.
- Threaded `prototype:` through the renderer: `build-plan-html.mjs` emits a `<meta name="plan-prototype">` tag and a `View prototype` anchor in `.plan-header-actions` with a relative `path.relative()`-computed href. Re-copied both renderer files to `kit/plugins/plan-agent/scripts/`.
- Added a prototype chip to the plans gallery card (`kit/plugins/plan-agent/hooks/build-index.sh`, `scripts/build-plans-index.sh`, `docs/plans/build-index.sh`); chip uses `<span>`, not `<a>`, since the card is already an anchor.
- Created `kit/plugins/plan-agent/hooks/check-prototype-drift.py`: reads the `PostToolUse` JSON payload, compares the prototype's `#proto-model` against (A) its own DOM columns and form fields, and (B) the plan's `proto-model:` frontmatter. Reports divergences; always exits 0.
- Registered the drift check in `kit/plugins/plan-agent/hooks/dispatch.py` inside the `is_prototype` branch.
- Added `tests/plugins/test-prototype-plan-link.mjs`, `tests/plugins/test-prototype-drift.sh`; extended `tests/plugins/test-build-plan-html.mjs`.
- Bumped plan-agent to **4.4.0** in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/prototype/reference/PROTOTYPE-SKELETON.html` | Skeleton — `#proto-model` JSON block | Modified |
| `kit/plugins/plan-agent/skills/prototype/SKILL.md` | Skill — `proto-source` format, model serialization, write-back step | Modified |
| `scripts/lib/plan-shell.mjs` | Renderer shell — `plan-prototype` meta tag, header link | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy (byte-identical) | Modified |
| `scripts/build-plan-html.mjs` | Renderer — thread `prototype` frontmatter key | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy (byte-identical) | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Gallery builder — prototype chip | Modified |
| `scripts/build-plans-index.sh` | Gallery builder (byte-identical copy) | Modified |
| `docs/plans/build-index.sh` | Gallery builder (byte-identical copy) | Modified |
| `kit/plugins/plan-agent/hooks/check-prototype-drift.py` | Hook — drift detection | Created |
| `kit/plugins/plan-agent/hooks/dispatch.py` | Dispatcher — fan out to drift check | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history — 4.4.0 | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — 4.3.1 → 4.4.0 | Modified |
| `tests/plugins/test-prototype-plan-link.mjs` | Test — renderer back-link and gallery chip | Created |
| `tests/plugins/test-prototype-drift.sh` | Test — drift-hook comparison branches | Created |
| `tests/plugins/test-build-plan-html.mjs` | Test — back-compat case for specs without `prototype:` | Modified |

## How it works

Before this change, `/plan-agent:prototype` stamped `<meta name="proto-source">` into the generated HTML but left the plan itself unaware a prototype existed. The two artifacts had no shared, machine-readable overlap.

The design draws a clear asymmetry: plan → prototype is regeneration (re-run `/plan-agent:prototype`, which is deterministic); prototype → plan is detection (compare two JSON blobs and report). Full bidirectional sync was rejected because prototypes have no spec file — the HTML *is* the source — and propagating a prototype edit back into plan prose would need an HTML-to-model parser over generated files.

The prototype skill now serializes the Step 3 data model (entity, fields with types, primary action, success signal) as compact single-line JSON into a `<script id="proto-model">` block in the prototype HTML and writes `prototype:` and `proto-model:` back into the plan's `.md` frontmatter. The JSON must be single-line — the frontmatter parser is a naive line scanner and an embedded newline or `---` would silently truncate the block.

The renderer threads the `prototype:` frontmatter key through `metaTags()` and `header()`, computing the href with `path.relative()` from the rendered plan's output directory. A hard-coded `../prototypes/` was rejected because `plansDirectory` is configurable and nested plan directories break relative paths that assume a fixed depth.

The gallery chip in `build-index.sh` uses `<span>` with non-empty text rather than `<a>` because the whole card is already wrapped in an anchor, and a nested anchor is invalid HTML that browsers silently unnest. All three byte-identical copies of the builder were updated together.

`check-prototype-drift.py` runs as a `PostToolUse` hook on prototype writes. It performs two comparisons: (A) the prototype's `#proto-model` field names against the `<th>` headers and form field `name`/`id` attributes in the same file, and (B) the prototype's `#proto-model` against the `proto-model:` frontmatter of the plan its `proto-source` names. It always exits 0 and stays silent when either side is absent or unparseable.

## How to use it

**Generate a prototype and get a back-link automatically:**
```
/plan-agent:prototype docs/plans/my-feature.md
```
This writes `prototype:` and `proto-model:` into `docs/plans/my-feature.md` and opens `docs/prototypes/my-feature.html` with a "View prototype" header link on the rendered plan page.

The drift check runs automatically via the `PostToolUse` hook whenever a prototype file is written. A message like "Field `userId` in prototype does not match `proto-model:` in plan" signals that the prototype has been hand-edited and needs reconciliation.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18eec` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `88a686a9` | 2026-08-28 | fix(plan-agent): make artifact-published plans first-class in review, design, and prototype (#609) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
