# Make a plan and its prototype aware of each other

> A prototype already knows which plan it came from, but the plan has no idea a prototype exists, and neither file records the data model they supposedly share...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
**Type:** feature

## What shipped

- Add `<script type="application/json" id="proto-model">{{PROTO_MODEL}}</script>` to `PROTOTYPE-SKELETON.html` immediat...
- Pin the `{{SOURCE_PLAN}}` contract in `skills/prototype/SKILL.md`: on the plan path it is the repo-relative path of t...
- Extend Step 5 of `skills/prototype/SKILL.md` to substitute `{{PROTO_MODEL}}` with the Step 3 model serialized as comp...
- Add a write-back step to `skills/prototype/SKILL.md` that runs **before** the prototype HTML is written in Step 6, re...
- Thread `prototype` through the renderer in three places: read `parsed.metadata.prototype` in `build-plan-html.mjs` ne...
- Add a prototype chip to the plans gallery card alongside the existing `card-date` span, as a text-bearing span matchi...
- Write `hooks/check-prototype-drift.py`, reading the `PostToolUse` JSON payload on stdin and running two comparisons:...
- Register the drift check in `dispatch.py` by appending it to the `is_prototype` branch after the existing `build-prot...
- Write the three test files, document the new hook and the `prototype:` / `plan-prototype` keys in the plugin `README....

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/prototype/reference/PROTOTYPE-SKELETON.html` | add the `#proto-model` JSON block | Modified |
| `kit/plugins/plan-agent/skills/prototype/SKILL.md` | pin the `proto-source` format, serialize the model, write... | Modified |
| `scripts/lib/plan-shell.mjs` | optional `plan-prototype` meta tag and the header link (r... | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | byte-identical re-copy of the above | Modified |
| `scripts/build-plan-html.mjs` | thread the `prototype` frontmatter key into both `metaTag... | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | byte-identical re-copy of the above | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | prototype chip on the plans gallery card | Modified |
| `scripts/build-plans-index.sh` | byte-identical re-copy of the above | Modified |
| `docs/plans/build-index.sh` | byte-identical re-copy of the above | Modified |
| `kit/plugins/plan-agent/hooks/check-prototype-drift.py` | the drift comparison | Created |
| `kit/plugins/plan-agent/hooks/dispatch.py` | fan out to the drift check on prototype writes | Modified |
| `kit/plugins/plan-agent/README.md` | document the new hook and the `prototype:` / `plan-protot... | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 4.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | bump plan-agent 4.3.1 to 4.4.0 | Modified |
| `tests/plugins/test-prototype-plan-link.mjs` | objective test | Created |
| `tests/plugins/test-prototype-drift.sh` | drift-hook cases | Created |
| `tests/plugins/test-build-plan-html.mjs` | back-compat case for specs with no `prototype:` key | Modified |

## How it works

Give every plan a back-link to its prototype, persist the prototype's derived data model in both files, and add a `PostToolUse` hook that flags when a prototype has drifted from its own model or from its plan's copy of it.

`/plan-agent:prototype` already stamps `<meta name="proto-source">` into every prototype it generates, and `build-prototypes-index.sh` renders it on the gallery card as "from `<plan>`". The link is one-directional: open a plan and nothing tells you a prototype exists.

The implementation proceeded through these steps: Add `<script type="application/json" id="proto-model">{{PROTO_MODEL}}</script>` to `PROTOTYPE-SKELETON.html` immediat...; Pin the `{{SOURCE_PLAN}}` contract in `skills/prototype/SKILL.md`: on the plan path it is the repo-relative path of t...; Extend Step 5 of `skills/prototype/SKILL.md` to substitute `{{PROTO_MODEL}}` with the Step 3 model serialized as comp...; Add a write-back step to `skills/prototype/SKILL.md` that runs **before** the prototype HTML is written in Step 6, re...; Thread `prototype` through the renderer in three places: read `parsed.metadata.prototype` in `build-plan-html.mjs` ne....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
