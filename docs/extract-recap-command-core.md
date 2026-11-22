# Extract shared recap workflow to recap-core

> Three recap commands (eng-recap, team-recap, product-doc) each duplicated the same multi-step republish logic; this extracts it to a shared reference so each command becomes a thin framing wrapper with its own artifact key.

<!-- generated:start -->

**Status:** Shipped 2026-08-01 **Plan:** [extract-recap-command-core.md](plans/extract-recap-command-core.md)
**Type:** chore

## What shipped

- Added `kit/plugins/artifact-tools/references/recap-core.md`: the canonical shared workflow for all recap commands — session-scan, content-select, HTML render, and republish steps; each command's unique artifact key (`eng-artifact-url:`, `team-artifact-url:`, `product-artifact-url:`) referenced from here.
- Reduced `eng-recap`, `team-recap`, and `product-doc` to framing wrappers: each retains only its audience framing, its unique `artifact-url:` key name, and a pointer to `recap-core.md`; the shared republish logic is removed from all three.
- Each command now under 500 words (was 700–900 words before extraction).
- `product-doc` gained page-build requirements (meta description, open-graph tags) and a 📋 favicon.
- `README.md` updated: `recap-core.md` added to the structure tree.
- Updated `tests/plugins/test-artifact-tools.sh`: checks 8, 8b, and 9 retargeted to assert the shared logic lives in `recap-core.md` rather than duplicated in each command.
- Added `tests/plugins/test-recap-command-dedupe.sh`: asserts no banned duplicate phrases appear in more than one recap command.
- Updated `tests/plugins/test-remaining-skill-splits.sh`: widened orphaned-reference check to include commands.
- Bumped artifact-tools to a minor version.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/recap-core.md` | Shared recap workflow | Created |
| `kit/plugins/artifact-tools/skills/eng-recap/SKILL.md` | Framing wrapper only | Modified |
| `kit/plugins/artifact-tools/skills/team-recap/SKILL.md` | Framing wrapper only | Modified |
| `kit/plugins/artifact-tools/skills/product-doc/SKILL.md` | Framing + favicon + page-build | Modified |
| `kit/plugins/artifact-tools/README.md` | recap-core.md in tree | Modified |
| `tests/plugins/test-artifact-tools.sh` | Checks 8, 8b, 9 retargeted | Modified |
| `tests/plugins/test-recap-command-dedupe.sh` | Duplicate-phrase check | Created |
| `tests/plugins/test-remaining-skill-splits.sh` | Orphaned-reference widened | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools minor bump | Modified |

## How it works

Before this change, each recap command contained a full copy of the republish workflow. A bug fix or improvement had to be applied three times. `recap-core.md` is a single source of truth: the shared steps live there once, and each command's SKILL.md is now only the audience framing and the artifact-url key name.

The three `artifact-url:` keys (`eng-artifact-url:`, `team-artifact-url:`, `product-artifact-url:`) are intentionally distinct so running all three in the same session produces three separate artifacts, not three overwrites of one.

## How to use it

The commands are invoked the same way as before — the extraction is transparent to the user:

```
/artifact-tools:eng-recap
/artifact-tools:team-recap
/artifact-tools:product-doc
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `024ddd0d` | 2026-08-01 | chore(artifact-tools): extract recap-core.md — reduce three commands to framing wrappers (minor bump) |

<!-- generated:end -->

## References

- Plan: [extract-recap-command-core.md](plans/extract-recap-command-core.md)
