# Add bidirectional plan–prototype linking

> Wires plans and their HTML prototypes together with bidirectional frontmatter links, a JSON block in the skeleton, a drift-check hook, and updated build-index copies — so navigating from a plan to its prototype (and back) works without hunting for filenames.

<!-- generated:start -->

**Status:** Shipped 2026-07-25 **Plan:** [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
**Type:** feature

## What shipped

- Added `#proto-model` JSON block to the plan skeleton for embedding the prototype model reference.
- Added `plan-prototype` meta tag in rendered plan HTML plus a header anchor for deep-linking.
- Added `check-prototype-drift.py` as a PostToolUse hook that alerts when a plan's prototype falls out of sync with its spec.
- Updated all three byte-identical copies of `build-index.sh` to handle the new linking.
- Bumped plan-agent to 4.4.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Plan skeleton | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | HTML renderer | Modified |
| `kit/plugins/plan-agent/hooks/check-prototype-drift.py` | PostToolUse hook | Created |
| `docs/plans/build-index.sh` | Index builder | Modified |
| `kit/plugins/plan-agent/scripts/build-index.sh` | Index builder (copy) | Modified |
| `kit/plugins/plan-agent/skills/plans-library/build-index.sh` | Index builder (copy) | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |

## How it works

Plans now carry a `prototype:` frontmatter key pointing at the relative path of their HTML prototype file, and prototypes carry a `plan:` key pointing back. The renderer emits a `plan-prototype` meta tag so the published artifact can resolve the relationship, and a header anchor lets deep-links land directly at the prototype reference.

The `check-prototype-drift.py` PostToolUse hook fires after any write to a plan spec or its prototype. It compares the spec's acceptance criteria checksums against the prototype's interaction model and flags when the prototype's assumptions no longer match what the plan requires. This prevents the common case where a plan gets refined but its prototype still demonstrates the original flow.

The three copies of `build-index.sh` are a repo invariant — the gallery index builder exists in `docs/plans/`, `kit/plugins/plan-agent/scripts/`, and `kit/plugins/plan-agent/skills/plans-library/` and must stay byte-identical. All three were updated together.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
