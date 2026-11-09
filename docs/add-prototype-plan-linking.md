# Make a Plan and Its Prototype Aware of Each Other

> A prototype already knows which plan it came from, but the plan has no idea a prototype exists, and neither file records the data model they supposedly share. This puts a link on both ends and a durable model block in both files, so a hook can say "these two have drifted apart" instead of everyone finding out at implementation time.

<!-- generated:start -->

**Status:** Shipped 2026-08-19  **Plan:** [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
**Type:** feature

## What shipped

- Added a `<script type="application/json" id="proto-model">` block to `PROTOTYPE-SKELETON.html` to durably store the derived data model (entity, fields, action, successSignal) inside every generated prototype.
- Extended the `prototype` skill to pin the `{{SOURCE_PLAN}}` format as a repo-relative path and to serialize the model as compact single-line JSON into `{{PROTO_MODEL}}`; added a write-back step that records `prototype:` and `proto-model:` into the source plan's frontmatter before the HTML is written.
- Threaded `prototype:` through the renderer: `build-plan-html.mjs` reads the frontmatter key, `plan-shell.mjs` emits a `<meta name="plan-prototype">` tag and a visible "View prototype" header anchor with `aria-label`, and all three index-builder copies gain a text-bearing prototype chip on the gallery card (not a nested anchor — the card is already wrapped in `<a>`).
- Added `hooks/check-prototype-drift.py`, a `PostToolUse` hook that compares the prototype's `#proto-model` field names against the prototype's own rendered columns and form fields, and against the `proto-model:` frontmatter of the plan named in `proto-source`. Always exits 0.
- Registered the drift check in `dispatch.py`'s `is_prototype` branch after the index rebuild.
- Bumped plan-agent to 4.4.0.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/prototype/reference/PROTOTYPE-SKELETON.html` | Skeleton — `#proto-model` JSON block | Modified |
| `kit/plugins/plan-agent/skills/prototype/SKILL.md` | Skill — `proto-source` format contract, model serialization, write-back step | Modified |
| `scripts/lib/plan-shell.mjs` | Renderer shell — `plan-prototype` meta tag and header link | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundle copy — byte-identical re-copy | Modified |
| `scripts/build-plan-html.mjs` | Renderer — threads `prototype` frontmatter key | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundle copy — byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Gallery builder — prototype chip on plan cards | Modified |
| `scripts/build-plans-index.sh` | Gallery builder — byte-identical re-copy | Modified |
| `docs/plans/build-index.sh` | Gallery builder — byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/hooks/check-prototype-drift.py` | Hook — drift comparison between model and DOM/plan | Created |
| `kit/plugins/plan-agent/hooks/dispatch.py` | Hook dispatcher — fans out to drift check on prototype writes | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — new hook and frontmatter keys | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 4.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — plan-agent 4.3.1 to 4.4.0 | Modified |
| `tests/plugins/test-prototype-plan-link.mjs` | Smoke test — renderer and gallery link verification | Created |
| `tests/plugins/test-prototype-drift.sh` | Unit test — drift-hook comparison branches | Created |
| `tests/plugins/test-build-plan-html.mjs` | Unit test — back-compat case for specs with no `prototype:` key | Modified |

## How it works

The design is asymmetric by intent. Plans are markdown source plus rendered HTML; prototypes have no spec file, so the HTML is the source. Full bidirectional sync would require an HTML-to-model parser over generated files. Instead: plan-to-prototype is regeneration (re-run `/plan-agent:prototype`, which is deterministic), and prototype-to-plan is detection (compare two JSON blobs and report).

The `#proto-model` block in the prototype skeleton provides the durable home needed for comparison. When the prototype skill runs Step 5, it substitutes `{{PROTO_MODEL}}` with the Step 3 model serialized as compact single-line JSON using the same script-breakout escaping rule already documented for `{{SEED_JSON}}`. A write-back step before Step 6 resolves the plan-path input's `.html` to its sibling `.md` by extension swap and writes `prototype:` and `proto-model:` into that spec's frontmatter. If the `.md` sibling does not exist (69 of 84 non-index plans are legacy HTML with no spec), the prototype is still written and the skill prints one line explaining how to get the back-link.

The renderer threads the `prototype:` frontmatter key through `build-plan-html.mjs` into `shell.metaTags()` and `shell.header()`. The header link's `href` is computed with `path.relative()` from the rendered plan's output directory to the `prototype:` target — never a hard-coded `../prototypes/` path, because `plansDirectory` is configurable and a custom plans directory would break a hard-coded relative path.

The gallery chip uses a text-bearing `<span>` matching the existing `status-chip` / `type-chip` / `effort-chip` pattern. It cannot be an anchor because the whole card is already wrapped in `<a class="gallery-card">`, and a nested `<a>` is invalid HTML browsers silently unnest. The chip carries a `title` attribute explaining that the prototype opens from inside the plan.

`check-prototype-drift.py` reads the `PostToolUse` JSON payload and runs two comparisons: the prototype's `#proto-model` field names against the `<th>` headers and form field `name`/`id` attributes in that same file, and the `#proto-model` against the `proto-model:` frontmatter of the plan named in `proto-source`. The plan path is resolved under the plans directory only; a path escaping that directory is silently ignored. The hook reads frontmatter with a single-line regex (`^proto-model:\s*(.*)$` then `json.loads`) rather than a general YAML parser, matching the precedent in `validate-plan-filename.py`. It exits 0 on every input including missing files, malformed JSON, and out-of-tree paths — drift is advisory, never blocking.

The renderer and gallery builders exist in multiple copies that must remain byte-identical. Every change landed at the repo-root sources first, then was re-copied into the plugin bundle.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
