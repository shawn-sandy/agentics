# Make a plan and its prototype aware of each other

> Adds bidirectional linking between a plan and its prototype, persists the derived data model in both files, and adds a PostToolUse hook that flags when the two copies have drifted apart.

<!-- generated:start -->

**Status:** Shipped 2026-07-26  **Plan:** [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
**Type:** feature

## What shipped

- Added `<script type="application/json" id="proto-model">` block to `PROTOTYPE-SKELETON.html` to durably persist the derived data model inside the prototype.
- Pinned the `{{SOURCE_PLAN}}` format in `skills/prototype/SKILL.md` as the repo-relative `.md` path; extended Step 5 to serialize the model as compact single-line JSON; added a write-back step that records `prototype:` and `proto-model:` in the source plan spec before writing the prototype HTML.
- Threaded `prototype` through the renderer: `build-plan-html.mjs` emits a `<meta name="plan-prototype">` tag and a visible `View prototype` header anchor with a `path.relative()`-computed href; both renderer files and their bundled copies updated to stay byte-identical.
- Added prototype chip to plans gallery cards in all three byte-identical copies of the index builder (`kit/plugins/plan-agent/hooks/build-index.sh`, `scripts/build-plans-index.sh`, `docs/plans/build-index.sh`).
- Added `hooks/check-prototype-drift.py` — compares the prototype's `#proto-model` against its rendered columns and against the plan's `proto-model:` frontmatter; exits 0 on every input including missing files or malformed JSON.
- Registered the drift check in `dispatch.py`'s `is_prototype` branch after the index rebuild.
- Added `tests/plugins/test-prototype-plan-link.mjs` and `tests/plugins/test-prototype-drift.sh`.
- Updated `kit/plugins/plan-agent/README.md` with the new hook and frontmatter keys.
- Bumped `plan-agent` to `4.4.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/skills/prototype/reference/PROTOTYPE-SKELETON.html` | Prototype skeleton | Modified |
| `kit/plugins/plan-agent/skills/prototype/SKILL.md` | Skill instructions | Modified |
| `scripts/lib/plan-shell.mjs` | Shell/UI layer (repo root) | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Shell/UI layer (bundled copy) | Modified |
| `scripts/build-plan-html.mjs` | HTML renderer (repo root) | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | HTML renderer (bundled copy) | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Plans index builder | Modified |
| `scripts/build-plans-index.sh` | Plans index builder (copy) | Modified |
| `docs/plans/build-index.sh` | Plans index builder (copy) | Modified |
| `kit/plugins/plan-agent/hooks/check-prototype-drift.py` | Drift detection hook | Created |
| `kit/plugins/plan-agent/hooks/dispatch.py` | Hook dispatcher | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `tests/plugins/test-prototype-plan-link.mjs` | Plan-link smoke test | Created |
| `tests/plugins/test-prototype-drift.sh` | Drift-hook test | Created |
| `tests/plugins/test-build-plan-html.mjs` | Back-compat test | Modified |

## How it works

The design distinguishes two sync directions. Plan to prototype is regeneration: re-running `/plan-agent:prototype` is deterministic (Step 3 always derives the same model from the same plan). Prototype to plan is detection: the drift hook compares the two JSON blobs and reports without writing anything.

When the `prototype` skill runs against a plan spec (`.md` sibling exists), it writes single-line `prototype:` and `proto-model:` keys into the spec frontmatter before generating the HTML. For legacy HTML plans with no sibling spec it still generates the prototype and prints a notice explaining how to get the back-link.

The drift hook (`check-prototype-drift.py`) runs two comparisons: the prototype's `#proto-model` field names against the rendered `<th>` headers and form field names in that same file (structural drift from hand-edits), and the prototype's `#proto-model` against the `proto-model:` frontmatter in the plan its `proto-source` names (plan drift). It exits 0 on every input, including missing files, malformed JSON, or out-of-tree paths — a drift report about an unrelated plan must never interrupt the user's current work.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
