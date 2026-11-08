# Make a plan and its prototype aware of each other

> Gives every plan a back-link to its prototype, persists the prototype's derived data model in both files, and adds a `PostToolUse` hook that flags when a prototype has drifted from its own model or from its plan's copy of it.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
**Type:** feature

## What shipped

- Added `<script type="application/json" id="proto-model">{{PROTO_MODEL}}</script>` to `PROTOTYPE-SKELETON.html` for a durable machine-readable model block in every generated prototype.
- Updated `skills/prototype/SKILL.md` to: pin the `{{SOURCE_PLAN}}` format contract (repo-relative path of the plan's `.md` spec), serialize the Step 3 derived model as compact single-line JSON into `{{PROTO_MODEL}}`, and write `prototype:` and `proto-model:` keys back into the source plan's frontmatter before the prototype HTML is written (skipped for idea/image/Figma inputs or when no sibling `.md` exists).
- Threaded `prototype:` through the renderer in `scripts/build-plan-html.mjs` and `scripts/lib/plan-shell.mjs`: emits `<meta name="plan-prototype">` and a `View prototype` header anchor with `aria-label`; re-copied both sources byte-for-byte to `kit/plugins/plan-agent/scripts/`.
- Added a prototype chip to plans gallery cards in all three byte-identical copies of the index builder (`kit/plugins/plan-agent/hooks/build-index.sh`, `scripts/build-plans-index.sh`, `docs/plans/build-index.sh`) — a text-bearing span, not an anchor, since the whole card is already wrapped in `<a class="gallery-card">`.
- Created `kit/plugins/plan-agent/hooks/check-prototype-drift.py`: reads the `PostToolUse` JSON payload on stdin, compares (A) the prototype's `#proto-model` field names against its `<th>` headers and form field names, and (B) the `#proto-model` against the `proto-model:` frontmatter of the plan its `proto-source` names; always exits 0.
- Registered the drift check in `hooks/dispatch.py` inside the `is_prototype` branch after the existing `build-prototypes-index.sh` call.
- Added `tests/plugins/test-prototype-plan-link.mjs` and `tests/plugins/test-prototype-drift.sh`; extended `tests/plugins/test-build-plan-html.mjs` with a back-compat case for specs with no `prototype:` key.
- Bumped plan-agent to 4.4.0 in `.claude-plugin/marketplace.json`; added 4.4.0 CHANGELOG entry; updated plugin README.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/prototype/reference/PROTOTYPE-SKELETON.html` | Added `#proto-model` JSON block | Modified |
| `kit/plugins/plan-agent/skills/prototype/SKILL.md` | Pinned `proto-source` format; serialize model; write-back | Modified |
| `scripts/lib/plan-shell.mjs` | `plan-prototype` meta tag and header link (repo-root source) | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical re-copy | Modified |
| `scripts/build-plan-html.mjs` | Thread `prototype` frontmatter key (repo-root source) | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Prototype chip on plans gallery card | Modified |
| `scripts/build-plans-index.sh` | Byte-identical re-copy | Modified |
| `docs/plans/build-index.sh` | Byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/hooks/check-prototype-drift.py` | Drift comparison hook | Created |
| `kit/plugins/plan-agent/hooks/dispatch.py` | Fan out to drift check on prototype writes | Modified |
| `kit/plugins/plan-agent/README.md` | Documents new hook and keys | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 4.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 4.4.0 | Modified |
| `tests/plugins/test-prototype-plan-link.mjs` | Objective test | Created |
| `tests/plugins/test-prototype-drift.sh` | Drift-hook cases | Created |
| `tests/plugins/test-build-plan-html.mjs` | Back-compat case | Modified |

## How it works

Before this change, `/plan-agent:prototype` already stamped `<meta name="proto-source">` into generated prototypes, and the gallery card read it as "from `<plan>`". The link was one-directional. The design is deliberately narrower than full bidirectional sync: **plan to prototype is regeneration** (re-run `/plan-agent:prototype`); **prototype to plan is detection** (compare two JSON blobs and report). Full sync would need an HTML-to-model parser over generated files, which CLAUDE.md forbids.

The `{{PROTO_MODEL}}` block stores the data model derived in Step 3 of the prototype skill (entity, fields with inferred types, action, successSignal) as compact single-line JSON. The single-line requirement is non-negotiable: the frontmatter parser in `plan-spec.mjs` is a naive line scanner, so an embedded newline or bare `---` would silently truncate the block and corrupt `status` and `created` for all three consumers that re-scan it.

The write-back step (new in `skills/prototype/SKILL.md`) runs before the prototype HTML is written. It resolves the plan-path input's `.html` to its sibling `.md` spec and writes `prototype:` and `proto-model:` as single-line frontmatter keys. When no sibling `.md` exists (69 of 84 non-index plans under `docs/plans/` are legacy HTML), the step is skipped, the prototype is still generated, and a one-line notice explains how to get the back-link.

The renderer in `plan-shell.mjs` and `build-plan-html.mjs` checks `parsed.metadata.prototype` and conditionally emits `<meta name="plan-prototype">` plus a `View prototype` anchor inside `.plan-header-actions`. The href is computed with `path.relative()` from the rendered plan's output directory to the prototype target, never hard-coded as `../prototypes/`.

The gallery chip follows the existing `status-chip`/`type-chip` pattern: a text-bearing `<span>` with a `title` attribute. It is not an anchor because the whole card is already wrapped in `<a class="gallery-card">`, and a nested anchor is invalid HTML. The same change lands in all three byte-identical copies of the index builder.

`check-prototype-drift.py` runs two comparisons on every prototype write: (A) the prototype's `#proto-model` field names against the `<th>` headers and form `name`/`id` attributes in that same file (catches human edits to the prototype structure), and (B) the `#proto-model` against the `proto-model:` frontmatter of the plan named in `proto-source` (catches re-generation from a changed plan). The script always exits 0 — a drift warning must not interrupt unrelated work.

The two renderers and three index builders each exist at multiple paths that must stay byte-identical (asserted by `test-build-plan-html.mjs:837` and the equivalent index-builder test). Every change landed in the repo-root sources first, then was re-copied.

## How to use it

The write-back and drift detection run automatically as part of `/plan-agent:prototype`. No separate invocation is needed.

The plan header link appears automatically when a plan spec carries a `prototype:` frontmatter key. The gallery chip appears on any plan card where the index builder finds that key.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `88a686a` | 2026-08-28 | fix(plan-agent): make artifact-published plans first-class in review, design, and prototype (#609) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — v4.4.0 entry
