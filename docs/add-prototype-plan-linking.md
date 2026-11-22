# Make a plan and its prototype aware of each other

> A prototype already knows which plan it came from, but the plan has no idea a prototype exists, and neither file records the data model they supposedly share. This puts a link on both ends and a durable model block in both files, so a hook can say "these two have drifted apart" instead of everyone finding out at implementation time.

<!-- generated:start -->

**Status:** Shipped 2026-07-26 **Plan:** [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
**Type:** feature

## What shipped

- Added `<script type="application/json" id="proto-model">` block to `PROTOTYPE-SKELETON.html` for the derived data model; pinned the `{{SOURCE_PLAN}}` format to the repo-relative path of the plan's `.md` spec.
- Extended `skills/prototype/SKILL.md` Step 5 to serialize the data model as compact single-line JSON; added write-back step (before the prototype HTML is written) that writes `prototype:` and `proto-model:` into the plan's `.md` frontmatter; skip for legacy HTML plans with no sibling spec.
- Threaded `prototype` through the renderer in `scripts/build-plan-html.mjs` and `scripts/lib/plan-shell.mjs`: `plan-prototype` meta tag; "View prototype" header anchor with `aria-label`; relative `href` computed from the output directory.
- Added prototype chip to plans gallery cards in all three byte-identical `build-index.sh` copies (not an anchor — the card is already wrapped in `<a>`).
- Added `hooks/check-prototype-drift.py` PostToolUse hook comparing (A) the prototype's `#proto-model` field names against its own `<th>` headers and form field names, and (B) the prototype's model against the plan's `proto-model:` frontmatter.
- Registered the drift hook in `hooks/dispatch.py` inside the `is_prototype` branch.
- Added `tests/plugins/test-prototype-plan-link.mjs`, `tests/plugins/test-prototype-drift.sh`, and updated `tests/plugins/test-build-plan-html.mjs`.
- Bumped plan-agent 4.3.1 → 4.4.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/prototype/reference/PROTOTYPE-SKELETON.html` | `#proto-model` JSON block | Modified |
| `kit/plugins/plan-agent/skills/prototype/SKILL.md` | Model serialization and write-back | Modified |
| `scripts/lib/plan-shell.mjs` | `plan-prototype` meta tag and header link | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical copy | Modified |
| `scripts/build-plan-html.mjs` | `prototype` frontmatter threading | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical copy | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Prototype chip on gallery card | Modified |
| `scripts/build-plans-index.sh` | Byte-identical copy | Modified |
| `docs/plans/build-index.sh` | Byte-identical copy | Modified |
| `kit/plugins/plan-agent/hooks/check-prototype-drift.py` | Drift comparison hook | Created |
| `kit/plugins/plan-agent/hooks/dispatch.py` | Fan-out to drift check | Modified |
| `kit/plugins/plan-agent/README.md` | Hook and frontmatter keys | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 4.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 4.3.1 → 4.4.0 | Modified |
| `tests/plugins/test-prototype-plan-link.mjs` | Objective test | Created |
| `tests/plugins/test-prototype-drift.sh` | Drift-hook cases | Created |
| `tests/plugins/test-build-plan-html.mjs` | Back-compat case | Modified |

## How it works

Plan to prototype is regeneration: re-run `/plan-agent:prototype`, which guarantees a deterministic result. Prototype to plan is detection: the drift hook compares two JSON blobs and reports.

When `/plan-agent:prototype` runs against a plan spec, it serializes the Step 3 data model as compact single-line JSON and writes `prototype: docs/prototypes/<slug>.html` and `proto-model: <json>` into the plan's `.md` frontmatter before writing the prototype HTML. For legacy HTML plans with no sibling `.md`, the prototype is still written and a one-line notice explains how to get the back-link.

The drift hook runs `PostToolUse` on every prototype write: (A) it compares the `#proto-model` field names against the prototype's own `<th>` headers and form `name`/`id` attributes — the only check that catches a hand-edit; (B) it compares against the plan's `proto-model:` frontmatter. It always exits 0 and stays silent on missing files, missing blocks, or parse failures.

## How to use it

```
/plan-agent:prototype docs/plans/my-plan.md
```

After generation, the plan spec gains `prototype:` and `proto-model:` frontmatter keys. The rendered plan page shows a "View prototype" link in the header and a chip on the gallery card. Drift is reported automatically whenever the prototype file is written.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-07-26 | feat(plan-agent): bidirectional plan-prototype links and drift detection (4.4.0) |

<!-- generated:end -->

## References

- Plan: [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
